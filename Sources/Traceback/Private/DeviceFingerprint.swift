//
//  DeviceFingerprint.swift
//  traceback-ios
//
//  Created by Sergi Hernanz on 7/4/25.
//


import Foundation
import UIKit

struct DeviceFingerprint: Codable, Equatable, Sendable {
    let appInstallationTime: TimeInterval
    let bundleId: String
    let osVersion: String
    let sdkVersion: String
    let uniqueMatchLinkToCheck: URL?
    let device: DeviceInfo
    let darkLaunchDetectedLink: URL?

    struct DeviceInfo: Codable, Equatable, Sendable {
        let deviceModelName: String
        let languageCode: String         // e.g. "es-ES"
        let languageCodeFromWebView: String? // optional, from JS context
        let languageCodeRaw: String      // e.g. "es_ES"
        let screenResolutionWidth: Int
        let screenResolutionHeight: Int
        let timezone: String             // e.g. "Europe/Madrid"
    }
}

@MainActor
func createDeviceFingerprint(
    system: SystemInfo,
    linkFromClipboard: URL?,
    languageFromWebView: String?,
    darkLaunchDetectedLink: URL?
) -> DeviceFingerprint {
    
    let isCompatibilityMode =
        UIDevice.current.model == "iPad" &&
        UIDevice.current.userInterfaceIdiom == .phone
    let screenSize = UIScreen.main.bounds.size
    let screenWidth = isCompatibilityMode ? 0 : Int(screenSize.width)
    let screenHeight = isCompatibilityMode ? 0 : Int(screenSize.height)
    
    let rawLocale = system.locale.identifier
    let normalizedLocale = rawLocale
        .replacingOccurrences(of: "_", with: "-")
        .replacingOccurrences(of: "-001", with: "")

    let deviceInfo = DeviceFingerprint.DeviceInfo(
        deviceModelName: system.deviceModelName,
        languageCode: normalizedLocale,
        languageCodeFromWebView: languageFromWebView,
        languageCodeRaw: rawLocale,
        screenResolutionWidth: Int(screenWidth),
        screenResolutionHeight: Int(screenHeight),
        timezone: system.timezone.identifier
    )

    return DeviceFingerprint(
        appInstallationTime: system.installationTime,
        bundleId: system.bundleId,
        osVersion: system.osVersion,
        sdkVersion: system.sdkVersion,
        uniqueMatchLinkToCheck: linkFromClipboard,
        device: deviceInfo,
        darkLaunchDetectedLink: darkLaunchDetectedLink
    )
}
