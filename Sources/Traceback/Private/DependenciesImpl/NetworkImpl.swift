//
//  NetworkImpl.swift
//  Traceback
//
//  Created by Sergi Hernanz on 27/9/25.
//

import Foundation

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
