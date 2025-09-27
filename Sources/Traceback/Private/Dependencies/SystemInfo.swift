//
//  SystemInfo.swift
//  Traceback
//
//  Created by Sergi Hernanz on 27/9/25.
//

import Foundation

struct SystemInfo: Equatable {
    let installationTime: TimeInterval
    let deviceModelName: String
    let sdkVersion: String
    let localeIdentifier: String
    let timezone: TimeZone
    let osVersion: String
    let bundleId: String
}
