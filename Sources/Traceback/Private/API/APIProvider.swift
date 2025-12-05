//
//  TracebackAPIProvider.swift
//  traceback-ios
//
//  Created by Sergi Hernanz on 7/4/25.
//

import Foundation

struct APIProvider: Sendable {

    private let config: NetworkConfiguration
    private let network: Network

    init(config: NetworkConfiguration, network: Network) {
        self.config = config
        self.network = network
    }

    func sendFingerprint(
        _ fingerprint: DeviceFingerprint
    ) async throws -> PostInstallLinkSearchResponse {

        let url = config.host.appendingPathComponent("v1_postinstall_search_link", isDirectory: false)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(fingerprint)
            return try await network.fetch(PostInstallLinkSearchResponse.self, request: request)
        } catch {
            throw NetworkError(error: error)
        }
    }

    func getCampaignLink(from url: String, isFirstCampaignOpen: Bool) async throws -> CampaignResponse {
        var urlComponents = URLComponents(
            url: config.host.appendingPathComponent("v1_get_campaign", isDirectory: false),
            resolvingAgainstBaseURL: false
        )
        
        // Add query parameters
        urlComponents?.queryItems = [
            URLQueryItem(name: "link", value: url),
            URLQueryItem(name: "first_campaign_open", value: String(isFirstCampaignOpen))
        ]
        
        guard let url = urlComponents?.url else {
            throw NetworkError.unknown
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            return try await network.fetch(CampaignResponse.self, request: request)
        } catch {
            throw NetworkError(error: error)
        }
    }
}
