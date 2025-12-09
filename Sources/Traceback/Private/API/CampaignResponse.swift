//
//  CampaignResponse.swift
//  traceback-ios
//
//  Created by Nacho Sánchez on 10/24/25.
//

import Foundation

struct CampaignResponse: Decodable, Equatable, Sendable {
    let result: URL?
    let error: String?
}
