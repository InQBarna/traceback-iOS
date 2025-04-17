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

    func sendFingerprint(_ fingerprint: DeviceFingerprint) async throws -> PostInstallLinkSearchResponse {
        guard let url = URL(string: "https://\(config.domain)/v1_postinstall_search_link") else {
            throw TracebackError.internalSDK
        }
        
        // https://europe-west1-iqbdemocms.cloudfunctions.net/ext-firebase-traceback-v1_postinstall_search_link

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
}
