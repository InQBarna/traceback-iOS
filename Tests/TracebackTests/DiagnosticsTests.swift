import Testing
import Foundation
import UIKit
@testable import Traceback

// MARK: - DiagnosticsResult Domain Logic Tests

@Test
func testPerformDiagnosticsDomainWithValidConfiguration() async throws {
    let validHost = URL(string: "https://example.com")!
    let config = TracebackConfiguration(
        mainAssociatedHost: validHost,
        associatedHosts: [URL(string: "https://api.example.com")!],
        useClipboard: true,
        logLevel: .info
    )

    let systemInfo = SystemInfo(
        installationTime: 1234567890,
        deviceModelName: "iPhone15,2",
        sdkVersion: "1.0.0",
        localeIdentifier: "en_US",
        timezone: TimeZone(identifier: "America/New_York")!,
        osVersion: "17.0",
        bundleId: "com.test.app"
    )

    let mockEntitlements: [String: Any] = [
        "com.apple.developer.associated-domains": [
            "applinks:example.com",
            "applinks:api.example.com"
        ]
    ]

    let mockPListInfo: [String: Any] = [
        "CFBundleURLTypes": [
            [
                "CFBundleURLSchemes": ["com.test.app"]
            ]
        ]
    ]

    class MockDelegate: NSObject, UIApplicationDelegate {
        func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
            return true
        }
    }
    let mockDelegate = await MockDelegate()

    let result = await TracebackSDKImpl.performDiagnosticsDomain(
        config: config,
        systemInfo: systemInfo,
        entitlements: mockEntitlements,
        pListInfo: mockPListInfo,
        appDelegate: mockDelegate
    )

    // Test system info
    #expect(result.systemInfo == systemInfo)

    // Test configuration validation - should all pass
    #expect(result.configuration.mainHostScheme.isValid == true)
    #expect(result.configuration.mainHostScheme.scheme == "https")
    #expect(result.configuration.mainHostname.isValid == true)
    #expect(result.configuration.mainHostname.hostname == "example.com")
    #expect(result.configuration.additionalHosts.count == 1)
    #expect(result.configuration.additionalHosts[0].isValid == true)
    #expect(result.configuration.clipboardWarning == false)

    // Test app configuration - should all pass
    #expect(result.appConfiguration.appDelegate.hasDelegate == true)
    #expect(result.appConfiguration.appDelegate.respondsToOpenURL == true)
    #expect(result.appConfiguration.urlScheme.expectedScheme == "com.test.app")
    #expect(result.appConfiguration.urlScheme.isFound == true)

    // Test associated domains - should all pass
    #expect(result.associatedDomains.hasEntitlements == true)
    #expect(result.associatedDomains.mainDomain?.isFound == true)
    #expect(result.associatedDomains.additionalDomains.count == 1)
    #expect(result.associatedDomains.additionalDomains[0].isFound == true)

    // Test summary
    #expect(result.summary.errorCount == 0)
    #expect(result.summary.warningCount == 0)
    #expect(result.summary.status == .success)
}

@Test
func testPerformDiagnosticsDomainWithErrors() async throws {
    // Configuration with HTTP instead of HTTPS
    let invalidHost = URL(string: "http://example.com")!
    let config = TracebackConfiguration(
        mainAssociatedHost: invalidHost,
        useClipboard: false, // This should be a warning
        logLevel: .info
    )

    let systemInfo = SystemInfo(
        installationTime: 1234567890,
        deviceModelName: "iPhone15,2",
        sdkVersion: "1.0.0",
        localeIdentifier: "en_US",
        timezone: TimeZone(identifier: "America/New_York")!,
        osVersion: "17.0",
        bundleId: "com.test.app"
    )

    // Empty entitlements and missing URL scheme in plist
    let emptyEntitlements: [String: Any] = [:]
    let emptyPListInfo: [String: Any] = [:]

    // No app delegate
    let result = await TracebackSDKImpl.performDiagnosticsDomain(
        config: config,
        systemInfo: systemInfo,
        entitlements: emptyEntitlements,
        pListInfo: emptyPListInfo,
        appDelegate: nil
    )

    // Test configuration validation - should have errors
    #expect(result.configuration.mainHostScheme.isValid == false)
    #expect(result.configuration.mainHostScheme.scheme == "http")
    #expect(result.configuration.mainHostname.isValid == true) // hostname is still valid
    #expect(result.configuration.clipboardWarning == true) // warning for disabled clipboard

    // Test app configuration - should have errors
    #expect(result.appConfiguration.appDelegate.hasDelegate == false)
    #expect(result.appConfiguration.appDelegate.respondsToOpenURL == false)
    #expect(result.appConfiguration.urlScheme.isFound == false)

    // Test associated domains - should have warnings
    #expect(result.associatedDomains.hasEntitlements == false)
    #expect(result.associatedDomains.mainDomain == nil)

    // Test summary - should have errors and warnings
    #expect(result.summary.errorCount > 0)
    #expect(result.summary.warningCount > 0)
    #expect(result.summary.status == .hasErrors)
}

@Test
func testPerformDiagnosticsDomainWithWarningsOnly() async throws {
    let validHost = URL(string: "https://example.com")!
    let config = TracebackConfiguration(
        mainAssociatedHost: validHost,
        useClipboard: false, // This should be a warning
        logLevel: .info
    )

    let systemInfo = SystemInfo(
        installationTime: 1234567890,
        deviceModelName: "iPhone15,2",
        sdkVersion: "1.0.0",
        localeIdentifier: "en_US",
        timezone: TimeZone(identifier: "America/New_York")!,
        osVersion: "17.0",
        bundleId: "com.test.app"
    )

    let mockEntitlements: [String: Any] = [
        "com.apple.developer.associated-domains": [
            "applinks:example.com"
        ]
    ]

    let mockPListInfo: [String: Any] = [
        "CFBundleURLTypes": [
            [
                "CFBundleURLSchemes": ["com.test.app"]
            ]
        ]
    ]

    class MockDelegate: NSObject, UIApplicationDelegate {
        func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
            return true
        }
    }
    let mockDelegate = await MockDelegate()

    let result = await TracebackSDKImpl.performDiagnosticsDomain(
        config: config,
        systemInfo: systemInfo,
        entitlements: mockEntitlements,
        pListInfo: mockPListInfo,
        appDelegate: mockDelegate
    )

    // All validations should pass except clipboard warning
    #expect(result.configuration.mainHostScheme.isValid == true)
    #expect(result.configuration.mainHostname.isValid == true)
    #expect(result.configuration.clipboardWarning == true) // warning for disabled clipboard
    #expect(result.appConfiguration.appDelegate.hasDelegate == true)
    #expect(result.appConfiguration.appDelegate.respondsToOpenURL == true)
    #expect(result.appConfiguration.urlScheme.isFound == true)
    #expect(result.associatedDomains.hasEntitlements == true)
    #expect(result.associatedDomains.mainDomain?.isFound == true)

    // Test summary - should have warnings only
    #expect(result.summary.errorCount == 0)
    #expect(result.summary.warningCount > 0)
    #expect(result.summary.status == .warningsOnly)
}

@Test
func testPerformDiagnosticsWithInoutParameter() async throws {
    let validHost = URL(string: "https://example.com")!
    let config = TracebackConfiguration(
        mainAssociatedHost: validHost,
        useClipboard: true,
        logLevel: .info
    )

    let systemInfo = SystemInfo(
        installationTime: 1234567890,
        deviceModelName: "iPhone15,2",
        sdkVersion: "1.0.0",
        localeIdentifier: "en_US",
        timezone: TimeZone(identifier: "America/New_York")!,
        osVersion: "17.0",
        bundleId: "com.test.app"
    )

    var capturedResult: DiagnosticsResult? = nil
    var loggedMessage: String? = nil

    await TracebackSDKImpl.performDiagnostics(
        config: config,
        logger: { message in
            loggedMessage = message
        },
        systemInfo: systemInfo,
        entitlements: ["com.apple.developer.associated-domains": ["applinks:example.com"]],
        pListInfo: ["CFBundleURLTypes": [["CFBundleURLSchemes": ["com.test.app"]]]],
        appDelegate: MockAppDelegate(),
        diagnosticsResult: &capturedResult
    )

    // Verify we got the structured result
    #expect(capturedResult != nil)
    #expect(capturedResult?.systemInfo == systemInfo)
    #expect(capturedResult?.configuration.mainHostScheme.isValid == true)

    // Verify we also got the formatted log message
    #expect(loggedMessage != nil)
    #expect(loggedMessage!.contains("Traceback SDK Diagnostics"))
    #expect(loggedMessage!.contains("Bundle ID: com.test.app"))
}

@Test
func testPerformDiagnosticsBackwardCompatibility() async throws {
    let validHost = URL(string: "https://example.com")!
    let config = TracebackConfiguration(
        mainAssociatedHost: validHost,
        useClipboard: true,
        logLevel: .info
    )

    var capturedResult: DiagnosticsResult? = nil
    var loggedMessage: String? = nil

    // Test the backward compatible overload (without inout parameter)
    await TracebackSDKImpl.performDiagnostics(
        config: config,
        logger: { message in
            loggedMessage = message
        },
        appDelegate: MockAppDelegate(),
        diagnosticsResult: &capturedResult
    )

    // Should still log the message
    #expect(loggedMessage != nil)
    #expect(loggedMessage?.contains("Traceback SDK Diagnostics") ?? false)
}

@Test
func testValidateConfigurationWithInvalidAdditionalHosts() async throws {
    let validHost = URL(string: "https://example.com")!
    let invalidHost = URL(string: "http://invalid.com")!
    let emptyHost = URL(string: "https://")! // Invalid hostname

    let config = TracebackConfiguration(
        mainAssociatedHost: validHost,
        associatedHosts: [invalidHost, emptyHost],
        useClipboard: true,
        logLevel: .info
    )

    let systemInfo = SystemInfo(
        installationTime: 1234567890,
        deviceModelName: "iPhone15,2",
        sdkVersion: "1.0.0",
        localeIdentifier: "en_US",
        timezone: TimeZone(identifier: "America/New_York")!,
        osVersion: "17.0",
        bundleId: "com.test.app"
    )

    let result = await TracebackSDKImpl.performDiagnosticsDomain(
        config: config,
        systemInfo: systemInfo,
        entitlements: [:],
        pListInfo: [:],
        appDelegate: nil
    )

    // Main host should be valid
    #expect(result.configuration.mainHostScheme.isValid == true)
    #expect(result.configuration.mainHostname.isValid == true)

    // Additional hosts should be invalid
    #expect(result.configuration.additionalHosts.count == 2)
    #expect(result.configuration.additionalHosts[0].isValid == false) // HTTP scheme
    #expect(result.configuration.additionalHosts[1].isValid == false) // Empty hostname

    // Should have errors due to invalid additional hosts
    #expect(result.summary.errorCount >= 2)
}

@Test
func testValidateAssociatedDomainsWithPartialMatches() async throws {
    let validHost = URL(string: "https://example.com")!
    let config = TracebackConfiguration(
        mainAssociatedHost: validHost,
        associatedHosts: [
            URL(string: "https://api.example.com")!,
            URL(string: "https://cdn.example.com")!
        ],
        useClipboard: true,
        logLevel: .info
    )

    let systemInfo = SystemInfo(
        installationTime: 1234567890,
        deviceModelName: "iPhone15,2",
        sdkVersion: "1.0.0",
        localeIdentifier: "en_US",
        timezone: TimeZone(identifier: "America/New_York")!,
        osVersion: "17.0",
        bundleId: "com.test.app"
    )

    // Only include main domain and one additional domain
    let mockEntitlements: [String: Any] = [
        "com.apple.developer.associated-domains": [
            "applinks:example.com",
            "applinks:api.example.com"
            // Missing "applinks:cdn.example.com"
        ]
    ]

    let result = await TracebackSDKImpl.performDiagnosticsDomain(
        config: config,
        systemInfo: systemInfo,
        entitlements: mockEntitlements,
        pListInfo: [:],
        appDelegate: nil
    )

    // Main domain should be found
    #expect(result.associatedDomains.hasEntitlements == true)
    #expect(result.associatedDomains.mainDomain?.isFound == true)
    #expect(result.associatedDomains.mainDomain?.domain == "applinks:example.com")

    // Should have 2 additional domains, one found and one not found
    #expect(result.associatedDomains.additionalDomains.count == 2)
    #expect(result.associatedDomains.additionalDomains[0].isFound == true)  // api.example.com
    #expect(result.associatedDomains.additionalDomains[1].isFound == false) // cdn.example.com (missing)

    // Should have warnings but no errors for missing additional domain
    #expect(result.summary.warningCount > 0)
}

// MARK: - Helper Classes

class MockAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return true
    }
}
