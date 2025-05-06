//
//  TracebackConfiguration.swift
//  traceback-ios
//
//  Created by Sergi Hernanz on 7/4/25.
//

import Foundation

/// Events returned by the sdk methods so they can be reported to your preferred analytics platform
public enum TracebackAnalyticsEvent {
    /// A post-installation content url has been detected
    case postInstallDetected(URL)
    /// A post-installation content url failure
    case postInstallError(Error)
}

/// Main configuration for the traceback sdk.
///  Needed to connect traceback sdk to the correct firebase project
public struct TracebackConfiguration: Sendable {
    
    /// Select the desired log level. Treaceback logs to os_system mac os when debugging.
    public enum LogLevel: Int, Sendable {
        /// Logs only errors
        case error
        /// Logs important debug information, warnings and errors.
        case debug
        /// Verbowe logging, info, debug and error logs are included
        case info
    }
    
    /// The main associated domain created by traceback firebase extension
    public let mainAssociatedHost: URL
    /// List of other domains associated to this app that are configured using Traceback.
    /// Usually the host created by the firebase traceback extension
    public let associatedHosts: [URL]?
    /// Configure the sdk to use the clipboard. This is the recommended setup, it's the only configuration
    /// that allows unique installation/link matches
    public let useClipboard: Bool
    /// Configure the sdk's logLevel
    /// @See TracebackConfiguration.LogLevel
    public let logLevel: LogLevel
    let network: NetworkConfiguration
    
    public init(
        mainAssociatedHost: URL,
        associatedHosts: [URL]? = nil,
        useClipboard: Bool = true,
        logLevel: LogLevel = .info
    ) {
        self.mainAssociatedHost = mainAssociatedHost
        self.associatedHosts = associatedHosts
        self.useClipboard = useClipboard
        self.logLevel = logLevel
        self.network = NetworkConfiguration(host: mainAssociatedHost)
    }
}
