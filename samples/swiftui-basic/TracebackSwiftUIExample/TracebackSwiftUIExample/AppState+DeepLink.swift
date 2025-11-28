//
//  AppState+DeepLink.swift
//  TracebackSwiftUIExample
//
//  Deep link handling methods for AppState
//

import Foundation

extension AppState {

    /// Checks for post-install link on app launch
    /// Should be called only once when the app first appears
    func checkPostInstallLink() async {
        debugMessage = "Checking for post-install link..."

        do {
            let result = try await traceback.postInstallSearchLink()

            if let result, let url = result.url {
                debugMessage = "✅ Post-install link detected!"
                handlePostInstallLink(url)
                sendAnalytics(result.analytics)
            } else {
                debugMessage = "ℹ️ No post-install link found"
            }
        } catch {
            debugMessage = "❌ Post-install check failed: \(error.localizedDescription)"
            print("[Error] Post-install search failed: \(error)")
        }
    }

    /// Handles a URL opened via Universal Link or custom scheme
    /// Resolves campaign links via the Traceback SDK
    func handleOpenURL(_ url: URL) async {
        print("[URL Received] \(url.absoluteString)")

        // Check if this is a Traceback URL and update the debug flag
        let isTraceback = traceback.isTracebackURL(url)
        isTracebackURL = isTraceback

        guard isTraceback else {
            print("[isTracebackURL] false - ignoring")
            debugMessage = "❌ Not a Traceback URL: \(url.host ?? "unknown")"
            return
        }

        print("[isTracebackURL] true - resolving campaign")
        debugMessage = "⏳ Resolving campaign link..."

        do {
            let result = try await traceback.campaignSearchLink(url)

            if let result, let deepLink = result.url {
                debugMessage = "✅ Campaign link resolved!"
                handleCampaignLink(deepLink)
                sendAnalytics(result.analytics)
            } else {
                debugMessage = "ℹ️ No deep link in campaign URL"
            }
        } catch {
            debugMessage = "❌ Campaign resolution failed: \(error.localizedDescription)"
            print("[Error] Campaign link resolution failed: \(error)")
        }
    }
}
