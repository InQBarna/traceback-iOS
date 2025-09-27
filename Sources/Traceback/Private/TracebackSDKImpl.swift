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
        TracebackSDK.Result(url: nil, match_type: .none, analytics: [])
    }
}

final class TracebackSDKImpl {
    private let config: TracebackConfiguration
    private let logger: Logger

    init(config: TracebackConfiguration, logger: Logger) {
        self.config = config
        self.logger = logger
    }

    func detectPostInstallLink() async -> TracebackSDK.Result {
        logger.info("Checking for previous post-install link successes")
        
        guard !UserDefaults.standard.bool(forKey: userDefaultsExistingRunKey) else {
            logger.info("Previous post-install link succes detected, " +
                        "won't continue searching for install link")
            return .empty
        }
        
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
            logger.info("Server responded with match type: \(response.match_type)")
            
            UserDefaults.standard.set(true, forKey: userDefaultsExistingRunKey)
            logger.info("Post-install success saved to user defaults \(userDefaultsExistingRunKey)" +
                        " so it is no longer checked")
            
            if let deep_link_id = response.deep_link_id {
                return TracebackSDK.Result(
                    url: response.deep_link_id,
                    match_type: response.matchType,
                    analytics: [
                        .postInstallDetected(deep_link_id)
                    ]
                )
            } else {
                return TracebackSDK.Result(
                    url: response.deep_link_id,
                    match_type: response.matchType,
                    analytics: []
                )
            }
        } catch {
            logger.error("Failed to detect post-install link: \(error.localizedDescription)")
            return TracebackSDK.Result(
                url: nil,
                match_type: .none,
                analytics: [
                    .postInstallError(error)
                ]
            )
        }
    }

    
    func extractLink(from: URL) throws -> TracebackSDK.Result {

        guard let components = URLComponents(url: from, resolvingAgainstBaseURL: false) else {
            throw TracebackError.ExtractLink.invalidURL
        }
        for queryItem in components.queryItems ?? [] {
            if queryItem.name == "link",
               let value = queryItem.value,
               let url = URL(string: value) {
                return TracebackSDK.Result(
                    url: url,
                    match_type: .unknown,
                    analytics: []
                )
            }
        }
        return TracebackSDK.Result(
            url: nil,
            match_type: .unknown,
            analytics: []
        )
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
