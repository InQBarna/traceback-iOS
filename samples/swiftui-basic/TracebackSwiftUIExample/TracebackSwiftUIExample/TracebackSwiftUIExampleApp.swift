//
//  TracebackSwiftUIExampleApp.swift
//  TracebackSwiftUIExample
//
//  A basic SwiftUI app demonstrating Traceback SDK integration
//

import SwiftUI
import Traceback

@main
struct TracebackSwiftUIExampleApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

// MARK: - App State

@MainActor
class AppState: ObservableObject {
    // SDK Debug Information
    @Published var postInstallLink: URL?
    @Published var campaignSearchLink: URL?
    @Published var isTracebackURL: Bool?
    @Published var debugMessage: String = "Waiting for links..."
    @Published var analyticsEvents: [String] = []

    lazy var traceback: TracebackSDK = {
        let config = TracebackConfiguration(
            mainAssociatedHost: URL(string: "https://traceback-extension-samples-traceback.web.app")!,
            useClipboard: true,
            logLevel: .debug
        )
        return TracebackSDK.live(config: config)
    }()

    init() {
        // Run diagnostics on init (only in debug builds)
        #if DEBUG
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.traceback.performDiagnostics()
        }
        #endif
    }

    func handlePostInstallLink(_ url: URL) {
        postInstallLink = url
        debugMessage = "Post-install link: \(url.absoluteString)"
        print("[Post-Install] \(url.absoluteString)")
    }

    func handleCampaignLink(_ url: URL) {
        campaignSearchLink = url
        debugMessage = "Campaign link: \(url.absoluteString)"
        print("[Campaign] \(url.absoluteString)")
    }

    func sendAnalytics(_ events: [TracebackAnalyticsEvent]) {
        for event in events {
            let eventDescription = formatAnalyticsEvent(event)
            analyticsEvents.append(eventDescription)
            print("[Analytics] \(eventDescription)")
        }
    }

    private func formatAnalyticsEvent(_ event: TracebackAnalyticsEvent) -> String {
        switch event {
        case .postInstallDetected(let url):
            return "Post-install detected: \(url.absoluteString)"
        case .postInstallError(let error):
            return "Post-install error: \(error.localizedDescription)"
        case .campaignResolved(let url):
            return "Campaign resolved: \(url.absoluteString)"
        case .campaignResolvedLocally(let url):
            return "Campaign resolved locally: \(url.absoluteString)"
        case .campaignError(let error):
            return "Campaign error: \(error.localizedDescription)"
        }
    }
}
