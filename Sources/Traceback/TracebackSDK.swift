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
    /// initialization value passed to TracebackSDK.live
    public let configuration: TracebackConfiguration
    /// Searches for the right content url that triggered app install
    ///
    /// @Discussion Calling this method right after app installation will search for the content url that
    /// was expected to be displayed at the very beginning of app install path. The method will return a
    /// valid url only once, later calls will no longer search for the opening url.
    public let postInstallSearchLink: () async throws -> Result?
    /// Parses the url that triggered app launch and extracts the real expected url to be opened
    ///
    /// @Discussion When a specific content is expected to be opened inside the application. The real url
    /// defining the content is not allways plain visible in the url which opened the app, since we need to build
    /// a url that is valid for all platforms, and for installation path. This method extracts the real url to be
    /// opened.
    public let extractLinkFromURL: (URL) throws -> Result?
    /// Diagnostics info
    ///
    /// @Discussion Call this method at app startup to diagnose your current setup
    public let performDiagnostics: () -> Void

    /// Result of traceback main methods. Contains the resulting URL and events so analytics can be saved
    public struct Result {
        /// A valid url if the method correctly finds a post install link, or opened url contains a valid deep link
        public let url: URL?
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
        let logger = Logger(level: config.logLevel)
        return TracebackSDK(
            configuration: config,
            postInstallSearchLink: {
                await TracebackSDKImpl(
                    config: config,
                    logger: logger
                )
                .detectPostInstallLink()
            },
            extractLinkFromURL: { url in
                try? TracebackSDKImpl(
                    config: config,
                    logger: logger
                )
                .extractLink(
                    from: url
                )
            },
            performDiagnostics: {
                Task {
                    await TracebackSDKImpl.performDiagnostics(config: config)
                }
            }
        )
    }
}

