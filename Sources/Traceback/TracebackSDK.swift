//
//  Traceback.swift
//  traceback-ios
//
//  Created by Sergi Hernanz on 7/4/25.
//

import Foundation

///
/// Main SDK entry object offering methods for searching the app opening content url and debug
///
public struct TracebackSDK {
    
    static let sdkVersion = "iOS/0.5.2"
    
    /// Initialization value passed to TracebackSDK.live
    public let configuration: TracebackConfiguration
    
    /// Searches for the right content url that triggered app install
    ///
    /// @Discussion Calling this method right after app installation will search for the content url that
    /// was expected to be displayed at the very beginning of app install path. The method will return a
    /// valid url only once, later calls will no longer search for the opening url.
    public let postInstallSearchLink: () async throws -> TracebackSDK.Result?
    
    /// Searches for the right content url associated to the url that opened the app
    ///
    /// @Discussion Calling this method when the app is opened via Universal Link or scheme
    /// will search for the content url associated to the opened url.
    public let campaignSearchLink: (URL) async throws -> TracebackSDK.Result?
    
    /// Validate input URL
    ///
    /// @Discussion Validates if the domain of the given URL matches any of the
    /// associated domains in configuration
    public let isTracebackURL: (URL) -> Bool
    
    /// Diagnostics info
    ///
    /// @Discussion Call this method at app startup to diagnose your current setup
    public let performDiagnostics: () -> Void
    
    ///
    /// Match type when searching for a post-install link
    ///
    public enum MatchType: Sendable {
        case unique         /// A unique result returned, given by pasteboard
        case heuristics     /// Heuristics search success
        case ambiguous      /// Heuristics seach success but ambiguous match
        case none           /// No match found
        case intent         /// A unique result returned, given by link opened by client
        case unknown        /// Not determined match type
    }

    /// Result of traceback main methods. Contains the resulting URL and events so analytics can be saved
    public struct Result: Sendable {
        /// A valid url if the method correctly finds a post install link, or opened url contains a valid deep link
        public let url: URL?
        /// The match type when extracting the post install
        public let matchType: MatchType
        /// Analytics to be sent to your preferred analytics platform
        public let analytics: [TracebackAnalyticsEvent]
    }
}


public extension TracebackSDK {
    ///
    /// Returns a working instance of the traceback sdk.
    ///    it is returned as value-type given the provided configuration.
    ///
    /// @Discussion Calling this method repeatedly
    ///    returns different working instances that can work independently, however saving the first instance
    ///    is recommended
    ///
    static func live(config: TracebackConfiguration) -> TracebackSDK {
        let logger = Logger.live(level: config.logLevel)
        let campaignTracker = CampaignTracker()
        let implementation = TracebackSDKImpl(
            config: config,
            logger: logger,
            campaignTracker: campaignTracker
        )
        
        return TracebackSDK(
            configuration: config,
            postInstallSearchLink: {
                await implementation.detectPostInstallLink()
            },
            campaignSearchLink: { url in
                await implementation.getCampaignLink(from: url)
            },
            isTracebackURL: { url in
                implementation.isTracebackURL(url)
            },
            performDiagnostics: {
                Task { @MainActor in
                    var result: DiagnosticsResult?
                    TracebackSDKImpl.performDiagnostics(
                        config: config,
                        diagnosticsResult: &result
                    )
                }
            }
        )
    }
}

