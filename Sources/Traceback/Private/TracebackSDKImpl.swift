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
        TracebackSDK.Result(url: nil, analytics: [])
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
            let languageFromWebView = await WebViewLanguageReader().getWebViewLocaleIdentifier()
            logger.debug("WebView language: \(languageFromWebView ?? "nil")")

            // 2. Try to read a link from clipboard
            let linkFromClipboard = config.useClipboard ? UIPasteboard.general.url : nil
            logger.debug("Link from clipboard: \(linkFromClipboard?.absoluteString ?? "none")")

            // 3. Generate fingerprint
            let system = await TracebackSystemImpl.systemInfo()
            let fingerprint = await createDeviceFingerprint(
                system: system,
                linkFromClipboard: linkFromClipboard,
                languageFromWebView: languageFromWebView
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

            return TracebackSDK.Result(
                url: response.deep_link_id,
                analytics: [
                    .postInstallDetected(response.deep_link_id)
                ]
            )
        } catch {
            logger.error("Failed to detect post-install link: \(error.localizedDescription)")
            return TracebackSDK.Result(
                url: nil,
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
                    analytics: []
                )
            }
        }
        return TracebackSDK.Result(
            url: nil,
            analytics: []
        )
    }
    
    @MainActor
    public static func performDiagnostics(
        config: TracebackConfiguration
    ) {
        var output = ""
        var errorCount = 0
        
        output += "\n--- Traceback Diagnostics ---\n"
        
        // 1. Generic Info
        output += "Traceback SDK Version: \(TracebackSystemImpl.systemInfo().sdkVersion)\n"
        output += "Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")\n"
        
        // 2. Simulator warning
#if targetEnvironment(simulator)
        output += """
            WARNING: iOS Simulator does not support Universal Links. \
            Traceback post-install detection will not fully function.\n
            """
#endif
        
        // 3. AppDelegate `application(_:open:options:)` check
        if let delegate = UIApplication.shared.delegate {
            let selector = #selector(UIApplicationDelegate.application(_:open:options:))
            if !(delegate.responds(to: selector)) {
                errorCount += 1
                output += """
                    ERROR: UIApplication delegate \(delegate) does NOT implement \
                    application(_:open:options:), required for handling incoming links.\n
                    """
            } else {
                output += "✅ UIApplication delegate responds to application(_:open:options:)\n"
            }
        }
        
        // 4. Check URL scheme in Info.plist
        let expectedScheme = Bundle.main.bundleIdentifier ?? ""
        let info = Bundle.main.infoDictionary
        let urlTypes = info?["CFBundleURLTypes"] as? [[String: Any]] ?? []
        let schemeFound = urlTypes.contains {
            guard let schemes = $0["CFBundleURLSchemes"] as? [String] else { return false }
            return schemes.contains(expectedScheme)
        }
        
        if schemeFound {
            output += "✅ Found URL scheme '\(expectedScheme)' in CFBundleURLTypes\n"
        } else {
            errorCount += 1
            output += """
                ERROR: Expected URL scheme '\(expectedScheme)' not found in Info.plist \
                (CFBundleURLTypes).\n
                """
        }
        
        // 5. (Optional) Entitlements analysis placeholder
#if !targetEnvironment(simulator)
        // Optionally analyze entitlements if needed
#endif
        
        if errorCount == 0 {
            output += "\n✅ Diagnostics completed successfully. No issues found.\n"
        } else {
            output += "\n❌ Diagnostics found \(errorCount) error(s).\n"
        }
        output += "-----------------------------\n"
        
        print("\(output)")
    }

}
