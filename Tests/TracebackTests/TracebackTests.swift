import Testing
import Foundation
import UIKit
@testable import Traceback

@Test
func checkCreateFingerPrint() async throws {
    
    let link = URL(string: "https://example.com/test-link")!
    let localeFromWebView = "es-ES"
    let appVersionFromWebView = "es-ES"
    let system = SystemInfo(
        installationTime: TimeInterval(0),
        deviceModelName: "myIphone",
        sdkVersion: "1.0.0",
        localeIdentifier: "es_ES",
        timezone: TimeZone(identifier: "Europe/Madrid")!,
        osVersion: "18.0.0",
        bundleId: "com.inqbarna.familymealplanner"
    )
    let createdFingerPrint = await createDeviceFingerprint(
        system: system,
        linkFromClipboard: link,
        webviewInfo: WebViewNavigatorReader.Navigator(
            language: localeFromWebView,
            appVersion: appVersionFromWebView
        ),
        darkLaunchDetectedLink: nil
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
            appVersionFromWebView: "es-ES",
            screenResolutionWidth: Int(UIScreen.main.bounds.width),
            screenResolutionHeight: Int(UIScreen.main.bounds.height),
            timezone: "Europe/Madrid"
        ),
        darkLaunchDetectedLink: nil
    )
    #expect(
        createdFingerPrint == expectedFingerprint
    )
}

@Test
func checkLocaleFromWebview() async throws {
    let reader = await WebViewNavigatorReader()
    let localeFromWebView = await reader.getWebViewInfo()
    #expect(localeFromWebView?.language == Locale.current.identifier)
}
