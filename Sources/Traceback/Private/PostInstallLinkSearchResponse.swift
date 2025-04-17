//
//  TracebackMatchResponse.swift
//  traceback-ios
//
//  Created by Sergi Hernanz on 7/4/25.
//

import Foundation

struct PostInstallLinkSearchResponse: Decodable, Equatable, Sendable {
    let deep_link_id: URL
    let match_message: String
    let match_type: String
    let request_ip_version: String
    let utm_medium: String?
    let utm_source: String?
}
