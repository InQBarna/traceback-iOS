//
//  APIClient.swift
//  traceback-ios
//
//  Created by Sergi Hernanz on 7/4/25.
//

import Foundation

struct NetworkConfiguration: Sendable {
    let host: URL
    init(host: URL) {
        self.host = host
    }
}

struct Network: Sendable {
    let fetchData: @Sendable (URLRequest) async throws -> (Data, URLResponse)
}

extension Network {
    func fetch<T: Decodable>(_ type: T.Type, request: URLRequest) async throws -> T {
        let (jsonData, _) = try await fetchData(request)
        return try JSONDecoder().decode(type, from: jsonData)
    }
}

