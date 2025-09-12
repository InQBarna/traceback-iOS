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
            let webviewInfo = await WebViewNavigatorReader().getWebViewInfo()
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
    public static func performDiagnostics(
        config: TracebackConfiguration
    ) {
        let logger = Logger(level: .info)
        var output = ""
        var errorCount = 0
        var warningCount = 0
        
        output += "\n--- Traceback Diagnostics ---\n"
        
        // 1. Generic Info
        output += "Traceback SDK Version: \(TracebackSystemImpl.systemInfo().sdkVersion)\n"
        output += "Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")\n"
        output += "Configuration Host: \(config.mainAssociatedHost.absoluteString)\n"
        output += "Clipboard Enabled: \(config.useClipboard ? "✅ Yes" : "❌ No")\n"
        if !config.useClipboard {
            warningCount += 1
            output += "  ⚠️  WARNING: Clipboard disabled. This limits post-install detection accuracy.\n"
        }
        output += "Log Level: \(config.logLevel)\n"
        
        if let additionalHosts = config.associatedHosts, !additionalHosts.isEmpty {
            output += "Additional Associated Hosts: \(additionalHosts.map { $0.absoluteString }.joined(separator: ", "))\n"
        }
        output += "\n"
        
        // 2. Simulator warning
#if targetEnvironment(simulator)
        warningCount += 1
        output += """
            ⚠️  WARNING: iOS Simulator does not support Universal Links. \
            Traceback post-install detection will not fully function.\n
            """
#endif
        
        // 3. Configuration validation
        output += "--- Configuration Validation ---\n"
        
        // 3a. Host URL validation
        let mainHost = config.mainAssociatedHost
        if mainHost.scheme != "https" {
            errorCount += 1
            output += "❌ ERROR: Main associated host must use HTTPS scheme. Found: \(mainHost.scheme ?? "nil")\n"
        } else {
            output += "✅ Main associated host uses HTTPS\n"
        }
        
        if mainHost.host == nil || mainHost.host!.isEmpty {
            errorCount += 1
            output += "❌ ERROR: Main associated host has invalid hostname\n"
        } else {
            output += "✅ Main associated host has valid hostname: \(mainHost.host!)\n"
        }
        
        // 3b. Additional hosts validation
        if let additionalHosts = config.associatedHosts {
            var validHosts = 0
            for host in additionalHosts {
                if host.scheme == "https" && host.host != nil && !host.host!.isEmpty {
                    validHosts += 1
                } else {
                    errorCount += 1
                    output += "❌ ERROR: Additional host invalid: \(host.absoluteString)\n"
                }
            }
            if validHosts == additionalHosts.count && validHosts > 0 {
                output += "✅ All \(validHosts) additional associated hosts are valid\n"
            }
        }
        
        // 4. App Configuration
        output += "\n--- App Configuration ---\n"
        
        // 4a. AppDelegate `application(_:open:options:)` check
        if let delegate = UIApplication.shared.delegate {
            let selector = #selector(UIApplicationDelegate.application(_:open:options:))
            if !(delegate.responds(to: selector)) {
                errorCount += 1
                output += """
                    ❌ ERROR: UIApplication delegate \(delegate) does NOT implement \
                    application(_:open:options:), required for handling incoming links.\n
                    """
            } else {
                output += "✅ UIApplication delegate responds to application(_:open:options:)\n"
            }
        } else {
            errorCount += 1
            output += "❌ ERROR: No UIApplication delegate found\n"
        }
        
        // 4b. Check URL scheme in Info.plist
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
                ❌ ERROR: Expected URL scheme '\(expectedScheme)' not found in Info.plist \
                (CFBundleURLTypes).\n
                """
        }
        
        // 4c. Associated Domains validation
        let entitlementsPath = Bundle.main.path(forResource: "Entitlements", ofType: "plist") ??
                              Bundle.main.path(forResource: Bundle.main.bundleIdentifier, ofType: "entitlements")
        
        if let entitlementsPath = entitlementsPath,
           let entitlements = NSDictionary(contentsOfFile: entitlementsPath),
           let domains = entitlements["com.apple.developer.associated-domains"] as? [String] {
            
            let mainDomain = config.mainAssociatedHost.host!
            let mainDomainEntry = "applinks:\(mainDomain)"
            
            if domains.contains(mainDomainEntry) {
                output += "✅ Found main associated domain in entitlements: \(mainDomainEntry)\n"
            } else {
                errorCount += 1
                output += "❌ ERROR: Main associated domain '\(mainDomainEntry)' not found in entitlements\n"
                output += "   Available domains: \(domains.joined(separator: ", "))\n"
            }
            
            // Check additional hosts
            if let additionalHosts = config.associatedHosts {
                var foundAdditionalDomains = 0
                for host in additionalHosts {
                    if let hostname = host.host {
                        let domainEntry = "applinks:\(hostname)"
                        if domains.contains(domainEntry) {
                            foundAdditionalDomains += 1
                        } else {
                            warningCount += 1
                            output += "⚠️  WARNING: Additional domain '\(domainEntry)' not found in entitlements\n"
                        }
                    }
                }
                if foundAdditionalDomains > 0 {
                    output += "✅ Found \(foundAdditionalDomains) additional associated domains in entitlements\n"
                }
            }
        } else {
            warningCount += 1
            output += "⚠️  WARNING: Could not read app entitlements for associated domains validation\n"
            output += "   Make sure 'com.apple.developer.associated-domains' includes 'applinks:\(config.mainAssociatedHost.host ?? "your-domain")'\n"
        }
        
        // 5. Network connectivity test (optional)
        output += "\n--- Network Connectivity ---\n"
        output += "ℹ️  To test network connectivity, try calling postInstallSearchLink() manually\n"
        output += "   Expected endpoint: \(config.mainAssociatedHost.absoluteString)/v1_postinstall_search_link\n"
        
        // 6. Recommendations
        output += "\n--- Recommendations ---\n"
        if !config.useClipboard {
            output += "• Enable clipboard usage for better post-install link detection\n"
        }
        
#if targetEnvironment(simulator)
        output += "• Test on a physical device to verify Universal Links functionality\n"
#endif
        
        output += "• Call performDiagnostics() only during development, not in production\n"
        output += "• Use the analytics events from postInstallSearchLink() results for tracking\n"
        
        // 7. Summary
        output += "\n--- Summary ---\n"
        if errorCount == 0 && warningCount == 0 {
            output += "✅ Diagnostics completed successfully. No issues found.\n"
        } else if errorCount == 0 {
            output += "✅ Configuration is valid with \(warningCount) warning(s).\n"
        } else {
            output += "❌ Diagnostics found \(errorCount) error(s) and \(warningCount) warning(s).\n"
            output += "   Fix errors before using Traceback in production.\n"
        }
        output += "-----------------------------\n"
        
        logger.info(output)
    }

}
