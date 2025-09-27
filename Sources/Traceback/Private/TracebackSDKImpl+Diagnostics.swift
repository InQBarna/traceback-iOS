//
//  TracebackSDKImpl+Diagnostics.swift
//  traceback-ios
//
//  Created by Sergi Hernanz on 7/4/25.
//

import Foundation
import UIKit

// MARK: - TracebackSDKImpl Diagnostics Extension

extension TracebackSDKImpl {

    @MainActor
    static func performDiagnosticsDomain(
        config: TracebackConfiguration,
        systemInfo: SystemInfo? = nil,
        entitlements: [String: Any]? = nil,
        pListInfo: [String: Any]? = Bundle.main.infoDictionary,
        appDelegate: UIApplicationDelegate? = UIApplication.shared.delegate
    ) -> DiagnosticsResult {
        let actualSystemInfo = systemInfo ?? TracebackSystemImpl.systemInfo()

        // Load entitlements if not provided
        let appEntitlements: [String: Any] = {
            if let entitlements {
                return entitlements
            }
            let entitlementsPath = Bundle.main.path(forResource: "Entitlements", ofType: "plist") ??
                                   Bundle.main.path(forResource: actualSystemInfo.bundleId, ofType: "entitlements")

            if let entitlementsPath = entitlementsPath,
               let entitlementsDict = NSDictionary(contentsOfFile: entitlementsPath) {
                return entitlementsDict as? [String: Any] ?? [:]
            }
            return [:]
        }()

        // 1. Configuration validation
        let configValidation = validateConfiguration(config: config)

        // 2. App configuration validation
        let appConfigValidation = validateAppConfiguration(
            systemInfo: actualSystemInfo,
            pListInfo: pListInfo,
            appDelegate: appDelegate
        )

        // 3. Associated domains validation
        let domainsValidation = validateAssociatedDomains(
            config: config,
            entitlements: appEntitlements
        )

        // 4. Calculate summary
        let summary = calculateSummary(
            configValidation: configValidation,
            appConfigValidation: appConfigValidation,
            domainsValidation: domainsValidation
        )

        return DiagnosticsResult(
            systemInfo: actualSystemInfo,
            configuration: configValidation,
            appConfiguration: appConfigValidation,
            associatedDomains: domainsValidation,
            summary: summary
        )
    }

    @MainActor
    static func performDiagnosticsPresentation(
        config: TracebackConfiguration,
        diagnosticsResult: DiagnosticsResult
    ) -> String {
        var output = ""

        // 1. Header
        output += "\n========== Traceback SDK Diagnostics ==========\n"
        output += "Traceback SDK Version: \(diagnosticsResult.systemInfo.sdkVersion)\n"
        output += "Bundle ID: \(diagnosticsResult.systemInfo.bundleId)\n"
        output += "Configuration Host: \(config.mainAssociatedHost.absoluteString)\n"
        output += "Clipboard Enabled: \(config.useClipboard ? "✅ Yes" : "❌ No")\n"
        if diagnosticsResult.configuration.clipboardWarning {
            output += "  ⚠️  WARNING: Clipboard disabled. This limits post-install detection accuracy.\n"
        }
        output += "Log Level: \(config.logLevel)\n"

        if let additionalHosts = config.associatedHosts, !additionalHosts.isEmpty {
            output += "Additional Associated Hosts: \(additionalHosts.map { $0.absoluteString }.joined(separator: ", "))\n"
        }
        output += "\n"

        // 2. Simulator warning
        if diagnosticsResult.summary.isSimulator {
            output += """
                ⚠️  WARNING: iOS Simulator does not support Universal Links. \
                Traceback post-install detection will not fully function.\n
                """
        }

        // 3. Configuration validation
        output += "--- Configuration Validation ---\n"

        // 3a. Host URL validation
        if diagnosticsResult.configuration.mainHostScheme.isValid {
            output += "✅ Main associated host uses HTTPS\n"
        } else {
            output += "❌ ERROR: Main associated host must use HTTPS scheme. Found: \(diagnosticsResult.configuration.mainHostScheme.scheme ?? "nil")\n"
        }

        if diagnosticsResult.configuration.mainHostname.isValid {
            output += "✅ Main associated host has valid hostname: \(diagnosticsResult.configuration.mainHostname.hostname!)\n"
        } else {
            output += "❌ ERROR: Main associated host has invalid hostname\n"
        }

        // 3b. Additional hosts validation
        if !diagnosticsResult.configuration.additionalHosts.isEmpty {
            let validHosts = diagnosticsResult.configuration.additionalHosts.filter { $0.isValid }.count
            let totalHosts = diagnosticsResult.configuration.additionalHosts.count

            if validHosts == totalHosts {
                output += "✅ All \(validHosts) additional associated hosts are valid\n"
            }

            for host in diagnosticsResult.configuration.additionalHosts {
                if !host.isValid {
                    output += "❌ ERROR: Additional host invalid: \(host.url)\n"
                }
            }
        }

        // 4. App Configuration
        output += "\n--- App Configuration ---\n"

        // 4a. AppDelegate check
        if diagnosticsResult.appConfiguration.appDelegate.hasDelegate {
            if diagnosticsResult.appConfiguration.appDelegate.respondsToOpenURL {
                output += "✅ UIApplication delegate responds to application(_:open:options:)\n"
            } else {
                output += """
                    ❌ ERROR: UIApplication delegate does NOT implement \
                    application(_:open:options:), required for handling incoming links.\n
                    """
            }
        } else {
            output += "❌ ERROR: No UIApplication delegate found\n"
        }

        // 4b. URL scheme validation
        if diagnosticsResult.appConfiguration.urlScheme.isFound {
            output += "✅ Found URL scheme '\(diagnosticsResult.appConfiguration.urlScheme.expectedScheme)' in CFBundleURLTypes\n"
        } else {
            output += """
                ❌ ERROR: Expected URL scheme '\(diagnosticsResult.appConfiguration.urlScheme.expectedScheme)' not found in Info.plist \
                (CFBundleURLTypes).\n
                """
        }

        // 4c. Associated Domains validation
        if diagnosticsResult.associatedDomains.hasEntitlements {
            if let mainDomain = diagnosticsResult.associatedDomains.mainDomain {
                if mainDomain.isFound {
                    output += "✅ Found main associated domain in entitlements: \(mainDomain.domain)\n"
                } else {
                    output += "❌ ERROR: Main associated domain '\(mainDomain.domain)' not found in entitlements\n"
                }
            }

            let foundAdditionalDomains = diagnosticsResult.associatedDomains.additionalDomains.filter { $0.isFound }.count

            for domain in diagnosticsResult.associatedDomains.additionalDomains {
                if !domain.isFound {
                    output += "⚠️  WARNING: Additional domain '\(domain.domain)' not found in entitlements\n"
                }
            }

            if foundAdditionalDomains > 0 {
                output += "✅ Found \(foundAdditionalDomains) additional associated domains in entitlements\n"
            }
        } else {
            output += "⚠️  WARNING: Could not read app entitlements for associated domains validation\n"
            output += "   Make sure 'com.apple.developer.associated-domains' includes 'applinks:\(config.mainAssociatedHost.host ?? "your-domain")'\n"
        }

        // 5. Network connectivity test (optional)
        output += "\n--- Network Connectivity ---\n"
        output += "ℹ️  To test network connectivity, try calling postInstallSearchLink() manually\n"
        output += "   Expected endpoint: \(config.mainAssociatedHost.absoluteString)/v1_postinstall_search_link\n"

        // 6. Recommendations
        output += "\n--- Recommendations ---\n"
        if diagnosticsResult.configuration.clipboardWarning {
            output += "• Enable clipboard usage for better post-install link detection\n"
        }

        if diagnosticsResult.summary.isSimulator {
            output += "• Test on a physical device to verify Universal Links functionality\n"
        }

        output += "• Call performDiagnostics() only during development, not in production\n"
        output += "• Use the analytics events from postInstallSearchLink() results for tracking\n"

        // 7. Summary
        output += "\n--- Summary ---\n"
        switch diagnosticsResult.summary.status {
        case .success:
            output += "✅ Diagnostics completed successfully. No issues found.\n"
        case .warningsOnly:
            output += "✅ Configuration is valid with \(diagnosticsResult.summary.warningCount) warning(s).\n"
        case .hasErrors:
            output += "❌ Diagnostics found \(diagnosticsResult.summary.errorCount) error(s) and \(diagnosticsResult.summary.warningCount) warning(s).\n"
            output += "   Fix errors before using Traceback in production.\n"
        }
        output += "-----------------------------\n"

        return output
    }
}

// MARK: - Private Diagnostic Helper Methods

private extension TracebackSDKImpl {

    static func validateConfiguration(config: TracebackConfiguration) -> DiagnosticsResult.ConfigurationValidation {
        let mainHost = config.mainAssociatedHost

        // Validate main host scheme
        let schemeValidation = DiagnosticsResult.ConfigurationValidation.HostSchemeValidation(
            isValid: mainHost.scheme == "https",
            scheme: mainHost.scheme
        )

        // Validate main hostname
        let hostnameValidation = DiagnosticsResult.ConfigurationValidation.HostnameValidation(
            isValid: mainHost.host != nil && !mainHost.host!.isEmpty,
            hostname: mainHost.host
        )

        // Validate additional hosts
        let additionalHostsValidation = config.associatedHosts?.map { host in
            DiagnosticsResult.ConfigurationValidation.AdditionalHostValidation(
                url: host.absoluteString,
                isValid: host.scheme == "https" && host.host != nil && !host.host!.isEmpty
            )
        } ?? []

        // Check clipboard warning
        let clipboardWarning = !config.useClipboard

        return DiagnosticsResult.ConfigurationValidation(
            mainHostScheme: schemeValidation,
            mainHostname: hostnameValidation,
            additionalHosts: additionalHostsValidation,
            clipboardWarning: clipboardWarning
        )
    }

    static func validateAppConfiguration(
        systemInfo: SystemInfo,
        pListInfo: [String: Any]?,
        appDelegate: UIApplicationDelegate?
    ) -> DiagnosticsResult.AppConfigurationValidation {
        // Validate app delegate
        let delegateValidation: DiagnosticsResult.AppConfigurationValidation.AppDelegateValidation
        if let delegate = appDelegate {
            let selector = #selector(UIApplicationDelegate.application(_:open:options:))
            let respondsToOpenURL = delegate.responds(to: selector)
            delegateValidation = DiagnosticsResult.AppConfigurationValidation.AppDelegateValidation(
                hasDelegate: true,
                respondsToOpenURL: respondsToOpenURL
            )
        } else {
            delegateValidation = DiagnosticsResult.AppConfigurationValidation.AppDelegateValidation(
                hasDelegate: false,
                respondsToOpenURL: false
            )
        }

        // Validate URL scheme
        let expectedScheme = systemInfo.bundleId
        let urlTypes = pListInfo?["CFBundleURLTypes"] as? [[String: Any]] ?? []
        let schemeFound = urlTypes.contains {
            guard let schemes = $0["CFBundleURLSchemes"] as? [String] else { return false }
            return schemes.contains(expectedScheme)
        }

        let urlSchemeValidation = DiagnosticsResult.AppConfigurationValidation.URLSchemeValidation(
            expectedScheme: expectedScheme,
            isFound: schemeFound
        )

        return DiagnosticsResult.AppConfigurationValidation(
            appDelegate: delegateValidation,
            urlScheme: urlSchemeValidation
        )
    }

    static func validateAssociatedDomains(
        config: TracebackConfiguration,
        entitlements: [String: Any]
    ) -> DiagnosticsResult.AssociatedDomainsValidation {
        guard !entitlements.isEmpty,
              let domains = entitlements["com.apple.developer.associated-domains"] as? [String] else {
            return DiagnosticsResult.AssociatedDomainsValidation(
                hasEntitlements: false,
                mainDomain: nil,
                additionalDomains: []
            )
        }

        // Validate main domain
        let mainDomain = config.mainAssociatedHost.host!
        let mainDomainEntry = "applinks:\(mainDomain)"
        let mainDomainValidation = DiagnosticsResult.AssociatedDomainsValidation.DomainValidation(
            domain: mainDomainEntry,
            isFound: domains.contains(mainDomainEntry)
        )

        // Validate additional domains
        let additionalDomainValidations = config.associatedHosts?.compactMap { host -> DiagnosticsResult.AssociatedDomainsValidation.DomainValidation? in
            guard let hostname = host.host else { return nil }
            let domainEntry = "applinks:\(hostname)"
            return DiagnosticsResult.AssociatedDomainsValidation.DomainValidation(
                domain: domainEntry,
                isFound: domains.contains(domainEntry)
            )
        } ?? []

        return DiagnosticsResult.AssociatedDomainsValidation(
            hasEntitlements: true,
            mainDomain: mainDomainValidation,
            additionalDomains: additionalDomainValidations
        )
    }

    static func calculateSummary(
        configValidation: DiagnosticsResult.ConfigurationValidation,
        appConfigValidation: DiagnosticsResult.AppConfigurationValidation,
        domainsValidation: DiagnosticsResult.AssociatedDomainsValidation
    ) -> DiagnosticsResult.Summary {
        var errorCount = 0
        var warningCount = 0

        // Count configuration errors
        if !configValidation.mainHostScheme.isValid {
            errorCount += 1
        }
        if !configValidation.mainHostname.isValid {
            errorCount += 1
        }
        for additionalHost in configValidation.additionalHosts {
            if !additionalHost.isValid {
                errorCount += 1
            }
        }
        if configValidation.clipboardWarning {
            warningCount += 1
        }

        // Count app configuration errors
        if !appConfigValidation.appDelegate.hasDelegate {
            errorCount += 1
        } else if !appConfigValidation.appDelegate.respondsToOpenURL {
            errorCount += 1
        }
        if !appConfigValidation.urlScheme.isFound {
            errorCount += 1
        }

        // Count domain errors
        if domainsValidation.hasEntitlements {
            if let mainDomain = domainsValidation.mainDomain, !mainDomain.isFound {
                errorCount += 1
            }
            for additionalDomain in domainsValidation.additionalDomains {
                if !additionalDomain.isFound {
                    warningCount += 1  // Additional domains are warnings, not errors
                }
            }
        } else {
            warningCount += 1  // No entitlements is a warning
        }

        #if targetEnvironment(simulator)
        let isSimulator = true
        #else
        let isSimulator = false
        #endif

        return DiagnosticsResult.Summary(
            errorCount: errorCount,
            warningCount: warningCount,
            isSimulator: isSimulator
        )
    }
}
