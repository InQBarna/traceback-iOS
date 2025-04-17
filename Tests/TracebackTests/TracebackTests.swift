import Testing
import Foundation
import UIKit
@testable import Traceback

@Test
func checkCreateFingerPrint() async throws {
    
    let link = URL(string: "https://example.com/test-link")!
    let localeFromWebView = "es-ES"
    let system = SystemInfo(
        installationTime: TimeInterval(0),
        deviceModelName: "myIphone",
        sdkVersion: "1.0.0",
        locale: Locale(identifier: "es_ES"),
        timezone: TimeZone(identifier: "Europe/Madrid")!,
        osVersion: "18.0.0",
        bundleId: "com.inqbarna.familymealplanner"
    )
    let createdFingerPrint = await createDeviceFingerprint(
        system: system,
        linkFromClipboard: link,
        languageFromWebView: localeFromWebView
    )
    let expectedFingerprint = await DeviceFingerprint(
        appInstallationTime: system.installationTime,
        bundleId: system.bundleId,
        osVersion: system.osVersion,
        sdkVersion: system.sdkVersion,
        uniqueMatchLinkToCheck: link,
        device: .init(
            deviceModelName: system.deviceModelName,
            languageCode: "es-ES",
            languageCodeFromWebView: localeFromWebView,
            languageCodeRaw: "es_ES",
            screenResolutionWidth: Int(UIScreen.main.bounds.width),
            screenResolutionHeight: Int(UIScreen.main.bounds.height),
            timezone: "Europe/Madrid"
        )
    )
    #expect(
        createdFingerPrint == expectedFingerprint
    )
}

@Test
func checkLocaleFromWebview() async throws {
    let reader = await WebViewLanguageReader()
    let localeFromWebView = await reader.getWebViewLocaleIdentifier()
    #expect(localeFromWebView == "en-GB")
}
