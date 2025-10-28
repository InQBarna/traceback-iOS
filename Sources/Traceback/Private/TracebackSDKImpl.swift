//
//  TracebackImpl.swift
//  traceback-ios
//
//  Created by Sergi Hernanz on 7/4/25.
//

import Foundation
import UIKit

private let userDefaultsExistingRunKey = "traceback_existingRun"

extension TracebackSDK.Result {
    static var empty: Self {
        TracebackSDK.Result(url: nil, campaign: nil, matchType: .none, analytics: [])
    }
}

final class TracebackSDKImpl {
    private let config: TracebackConfiguration
    private let logger: Logger
    private let campaignTracker: CampaignTracker
    private let linkDetectionActor = ValueWaiter<URL>()

    init(config: TracebackConfiguration, logger: Logger, campaignTracker: CampaignTracker) {
        self.config = config
        self.logger = logger
        self.campaignTracker = campaignTracker
    }

    func detectPostInstallLink() async -> TracebackSDK.Result {
        logger.info("Checking for previous post-install link successes")
        
        guard !UserDefaults.standard.bool(forKey: userDefaultsExistingRunKey) else {
            logger.info("Previous post-install link succes detected, " +
                        "won't continue searching for install link")
            return .empty
        }
        
        logger.debug("Waiting for universal link")
        let linkFromIntent = await linkDetectionActor.waitForValue(timeout: 0.5)
        logger.debug("Got universal link: \(linkFromIntent?.absoluteString ?? "none")")
        
        logger.info("Checking for post-install link")

        do {
            // 1. Try to get a languageCode from WebView
            let webviewInfo = await WebViewInfoReader.live().getInfo()
            logger.debug("WebView language: \(webviewInfo?.language ?? "nil")")
            logger.debug("WebView appVersion: \(webviewInfo?.appVersion ?? "nil")")

            // 2. Try to read a link from clipboard
            let linkFromClipboard: URL?
            if config.useClipboard {
                linkFromClipboard = UIPasteboard.general.url
                UIPasteboard.general.string = ""
            } else {
                linkFromClipboard = nil
            }
            logger.debug("Link from clipboard: \(linkFromClipboard?.absoluteString ?? "none")")

            // 3. Generate fingerprint
            let system = await TracebackSystemImpl.systemInfo()
            let fingerprint = await createDeviceFingerprint(
                system: system,
                linkFromClipboard: linkFromClipboard,
                linkFromIntent: linkFromIntent,
                webviewInfo: webviewInfo
            )

            logger.debug("Generated fingerprint: \(fingerprint)")

            // 4. Send fingerprint to backend
            let api = APIProvider(
                config: NetworkConfiguration(
                    host: config.mainAssociatedHost
                ),
                network: Network.live
            )

            let response = try await api.sendFingerprint(fingerprint)
            logger.info("Server responded with match type: \(response.matchType)")
            
            // 5. Save checks locally
            UserDefaults.standard.set(true, forKey: userDefaultsExistingRunKey)
            logger.info("Post-install success saved to user defaults \(userDefaultsExistingRunKey)" +
                        " so it is no longer checked")
            
            if let campaign = response.match_campaign {
                campaignTracker.markCampaignAsSeen(campaign)
                logger.info("Campaign \(campaign) seen for first time")
            }
            
            // TODO: remove this if backend sends final deeplink
            if
                let longLink = response.deep_link_id,
                let deeplink = try? extractLink(from: longLink)
            {
                return TracebackSDK.Result(
                    url: deeplink,
                    campaign: response.match_campaign,
                    matchType: response.matchType,
                    analytics: response.deep_link_id.map { [.postInstallDetected($0)] } ?? []
                )
            }
            
            // 6. Return what we have found
            return TracebackSDK.Result(
                url: response.deep_link_id,
                campaign: response.match_campaign,
                matchType: response.matchType,
                analytics: response.deep_link_id.map { [.postInstallDetected($0)] } ?? []
            )
        } catch {
            logger.error("Failed to detect post-install link: \(error.localizedDescription)")
            return TracebackSDK.Result(
                url: nil,
                campaign: nil,
                matchType: .none,
                analytics: [
                    .postInstallError(error)
                ]
            )
        }
    }
    
    func getCampaignLink(from url: URL) async -> TracebackSDK.Result {
        do {
            // 1. Check if first run, if not save link and continue
            guard UserDefaults.standard.bool(forKey: userDefaultsExistingRunKey) else {
                logger.info("Do not get campaign links on first run, do it via postInstallSearch")
                await linkDetectionActor.provideValue(url)
                return .empty
            }
            
            // 2. Extract campaign from url
            let campaign = extractCampaign(from: url)
            
            // 3. If no campaign, process locally
            guard let campaign else {
                let deeplink = try? extractLink(from: url)
                
                return TracebackSDK.Result(
                    url: deeplink,
                    campaign: campaign,
                    matchType: .unique,
                    analytics: []
                )
            }
            
            let isFirstCampaignOpen = campaignTracker.isFirstTimeSeen(campaign)
            logger.info("Campaign \(campaign) first open \(isFirstCampaignOpen)")
            
            // 3. Get campaign resolution from backend
            let api = APIProvider(
                config: NetworkConfiguration(
                    host: config.mainAssociatedHost
                ),
                network: Network.live
            )
            
            let response = try await api.getCampaignLink(from: url.absoluteString, isFirstCampaignOpen: isFirstCampaignOpen)
            logger.info("Server responded with link: \(String(describing: response.result))")
            
            guard
                let deeplink = response.result
            else {
                return .empty
            }
            
            return TracebackSDK.Result(
                url: deeplink,
                campaign: campaign,
                matchType: .unique,
                analytics: [
                    .campaignResolved(deeplink)
                ]
            )
        } catch {
            return TracebackSDK.Result(
                url: nil,
                campaign: nil,
                matchType: .none,
                analytics: [
                    .campaignError(error)
                ]
            )
        }
    }

    /// Parses the url that triggered app launch and extracts the real expected url to be opened
    ///
    /// @Discussion When a specific content is expected to be opened inside the application. The real url
    /// defining the content is not allways plain visible in the url which opened the app, since we need to build
    /// a url that is valid for all platforms, and for installation path. This method extracts the real url to be
    /// opened.
    private func extractLink(from url: URL) throws -> URL? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw TracebackError.ExtractLink.invalidURL
        }
        
        for queryItem in components.queryItems ?? [] {
            if queryItem.name == "link",
               let value = queryItem.value,
               let url = URL(string: value) {
                return url
            }
        }
        
        return nil
    }
    
    private func extractCampaign(from url: URL) -> String? {
        let path = url.path
        if path.count > 1 {
            return String(path.dropFirst())
        }
        return nil
    }
    
    @MainActor
    static func performDiagnostics(
        config: TracebackConfiguration,
        logger: @escaping (String) -> Void = { message in
            Logger.live().info(message)
        },
        systemInfo: SystemInfo? = nil,
        entitlements: [String: Any]? = nil,
        pListInfo: [String: Any]? = Bundle.main.infoDictionary,
        appDelegate: UIApplicationDelegate? = UIApplication.shared.delegate,
        diagnosticsResult: inout DiagnosticsResult?
    ) {
        let appEntitlements: [String: Any]
        if let providedEntitlements = entitlements {
            appEntitlements = providedEntitlements
        } else {
            let actualSystemInfo = systemInfo ?? TracebackSystemImpl.systemInfo()
            // Default entitlements loading logic
            let entitlementsFileName = "\(actualSystemInfo.bundleId).entitlements"
            if let entitlementsPath = Bundle.main.path(forResource: "Entitlements", ofType: "plist") {
                appEntitlements = NSDictionary(contentsOfFile: entitlementsPath) as? [String: Any] ?? [:]
            } else if let entitlementsPath = Bundle.main.path(forResource: entitlementsFileName, ofType: "plist") {
                appEntitlements = NSDictionary(contentsOfFile: entitlementsPath) as? [String: Any] ?? [:]
            } else {
                appEntitlements = [:]
            }
        }

        let result = performDiagnosticsDomain(
            config: config,
            systemInfo: systemInfo,
            entitlements: appEntitlements,
            pListInfo: pListInfo,
            appDelegate: appDelegate
        )

        // Set the inout parameter
        diagnosticsResult = result

        let formattedOutput = performDiagnosticsPresentation(
            config: config,
            diagnosticsResult: result
        )

        logger(formattedOutput)
    }
}
