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
    /// Indicates the url that triggered app opening is an invalid URL
    enum ExtractLink: Error {
        case invalidURL
    }
    /// Indicates an error from the URL that triggered app opening
    case extractLink(ExtractLink)
    /// Indicates a network error
    case network(NetworkError)
    /// Indicates an internal error, please refer to github issues
    case internalSDK
}
