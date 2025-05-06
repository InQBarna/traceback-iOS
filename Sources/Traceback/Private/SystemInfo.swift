//
//  SystemInfo.swift
//  traceback-ios
//
//  Created by Sergi Hernanz on 7/4/25.
//

import Foundation
import UIKit

struct SystemInfo {
    let installationTime: TimeInterval
    let deviceModelName: String
    let sdkVersion: String
    let localeIdentifier: String
    let timezone: TimeZone
    let osVersion: String
    let bundleId: String
}

enum TracebackSystemImpl {
    @MainActor
    static func systemInfo() -> SystemInfo {
        SystemInfo(
            installationTime: installationTime(),
            deviceModelName: deviceModelName(),
            sdkVersion: sdkVersion(),
            localeIdentifier: Locale.preferredLanguages.first ?? Locale.current.identifier,
            timezone: TimeZone.current,
            osVersion: UIDevice.current.systemVersion,
            bundleId: Bundle.main.bundleIdentifier ?? "unknown"
        )
    }
    
    private static func installationTime() -> TimeInterval {
        // Returns app installation time as UNIX timestamp
        let documentsFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        if let attr = try? FileManager.default.attributesOfItem(atPath: documentsFolder),
           let date = attr[.creationDate] as? Date {
            return date.timeIntervalSince1970
        }
        return 0
    }

    private static func deviceModelName() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        return mirror.children.reduce("") { acc, element in
            guard let value = element.value as? Int8, value != 0 else { return acc }
            return acc + String(UnicodeScalar(UInt8(value)))
        }
    }
    
    private static func sdkVersion() -> String {
        guard let infoDictSDKVersion = Bundle(for: TracebackSDKImpl.self)
            .infoDictionary?["CFBundleShortVersionString"] as? String else {
            assertionFailure()
            return "1.0.0"
        }
        return infoDictSDKVersion
    }
}
