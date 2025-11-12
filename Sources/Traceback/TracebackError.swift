//
//  TracebackError.swift
//  traceback-ios
//
//  Created by Sergi Hernanz on 7/4/25.
//

import Foundation

/// Used to diagnose different types of network errors
public enum NetworkError: Swift.Error, Equatable, Sendable {
    case noConnection
    case httpError(statusCode: Int)
    case unknown
}

/// Used to diagnose traceback's sdk errors
enum TracebackError: Error {
    /// Indicates a network error
    case network(NetworkError)
    /// Indicates an internal error, please refer to github issues
    case internalSDK
}
