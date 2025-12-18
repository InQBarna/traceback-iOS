//
//  ContentView.swift
//  TracebackAnalyticsExample
//
//  Main view demonstrating Firebase Analytics integration with Traceback SDK
//

import SwiftUI
import Traceback

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Firebase Analytics + Traceback")
                        .font(.headline)
                        .padding(.top)
                    
                    // Display debug message directly in body for visibility
                    // Text(verbatim: "Post-install link: https://traceback-samples.inqbarna.com/campaign/utm-test?utm_medium=test-medium&utm_source=test-source")
                    Text(appState.debugMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // Current route display
                    currentRouteSection
                    
                    // Analytics events
                    analyticsSection
                    
                    // Instructions
                    instructionsSection
                }
                .padding()
            }
        }
        .background(Color(UIColor.systemBackground))
        .onAppear {
            Task {
                await appState.checkPostInstallLink()
            }
        }
        .onOpenURL { url in
            Task {
                await appState.handleOpenURL(url)
            }
        }
    }

    // MARK: - View Components

    private var currentRouteSection: some View {
        VStack(spacing: 12) {
            Text("SDK Results")
                .font(.headline)

            // isTracebackURL result
            HStack {
                Text("isTracebackURL:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if let isTraceback = appState.isTracebackURL {
                    Text(isTraceback ? "✅ true" : "❌ false")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(isTraceback ? .green : .red)
                } else {
                    Text("—")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Divider()

            // Post-install link result
            HStack(alignment: .center, spacing: 4) {
                Text("postInstallSearchLink():")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if let postInstall = appState.postInstallLink {
                    Text(postInstall.absoluteString)
                        .font(.caption2)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                } else {
                    Text("nil")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }

            Divider()

            // Campaign link result
            HStack(alignment: .center, spacing: 4) {
                Text("campaignSearchLink():")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if let campaign = appState.campaignSearchLink {
                    Text(campaign.absoluteString)
                        .font(.caption2)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                } else {
                    Text("nil")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.1))
        .cornerRadius(10)
    }

    private var analyticsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Firebase Analytics Events")
                .font(.headline)

            if appState.analyticsEvents.isEmpty {
                Text("No events yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(appState.analyticsEvents.indices, id: \.self) { index in
                            Text("• \(appState.analyticsEvents[index])")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxHeight: 150)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(10)
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to Test")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                instructionRow(
                    icon: "chart.bar.fill",
                    title: "Firebase Analytics",
                    description: "UTM parameters are automatically extracted and logged"
                )

                instructionRow(
                    icon: "doc.on.clipboard",
                    title: "Post-Install",
                    description: "Copy Traceback link, delete app, reinstall"
                )

                instructionRow(
                    icon: "link",
                    title: "Campaign",
                    description: "Tap Traceback link from Messages/Email"
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }

    private func instructionRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
    }
}
