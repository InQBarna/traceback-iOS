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

extension NetworkError {
    init(error: Swift.Error) {
        if let alreadyNetworkError = error as? Self {
            self = alreadyNetworkError
            return
        }
        guard let urlError = error as? URLError else {
            self = .unknown
            return
        }
        switch urlError.code {
        case .notConnectedToInternet, .timedOut:
            self = .noConnection
        default:
            self = .unknown
        }
    }
    
    init?(response: URLResponse) {
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode >= 400 {
                self = .httpError(statusCode: httpResponse.statusCode)
            } else {
                return nil
            }
        } else {
            self = .unknown
        }
    }
}

extension Network {
    func fetch<T: Decodable>(_ type: T.Type, request: URLRequest) async throws -> T {
        let (jsonData, _) = try await fetchData(request)
        return try JSONDecoder().decode(type, from: jsonData)
    }
}

extension Network {
    public static let live = Network { request in
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            return (data, response)
        } catch {
            throw NetworkError(error: error)
        }
    }
}
