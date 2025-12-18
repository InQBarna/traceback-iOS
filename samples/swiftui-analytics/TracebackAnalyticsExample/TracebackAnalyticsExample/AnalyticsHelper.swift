//
//  AnalyticsHelper.swift
//  TracebackAnalyticsExample
//
//  Helper class to extract UTM parameters from Traceback URLs
//  and send them to Firebase Analytics
//

import Foundation
import FirebaseAnalytics

struct AnalyticsHelper {

    /// Logs a campaign event to Firebase Analytics with UTM parameters extracted from the URL
    /// - Parameters:
    ///   - url: The Traceback result URL containing UTM parameters
    ///   - source: The source of the campaign (e.g., "post_install", "campaign_link")
    static func logCampaignFromURL(_ url: URL, source: String) {
        // Extract UTM parameters from URL
        let utmParams = extractUTMParameters(from: url)

        // Log to Firebase Analytics using AnalyticsEventCampaignDetails
        // Reference: https://firebase.google.com/docs/reference/swift/firebaseanalytics/api/reference/Constants#analyticseventcampaigndetails
        var params: [String: Any] = [:]

        // Add UTM parameters as event parameters
        if let campaign = utmParams["utm_campaign"] {
            params[AnalyticsParameterCampaign] = campaign
        }
        if let utmSource = utmParams["utm_source"] {
            params[AnalyticsParameterSource] = utmSource
        }
        if let medium = utmParams["utm_medium"] {
            params[AnalyticsParameterMedium] = medium
        }
        if let term = utmParams["utm_term"] {
            params[AnalyticsParameterTerm] = term
        }
        if let content = utmParams["utm_content"] {
            params[AnalyticsParameterContent] = content
        }
        
        // ChatGTP claims this may be necessary ??? didn't apply it
        // Analytics.setDefaultEventParameters(params)

        // Add traceback source to distinguish post-install vs campaign link
        params["traceback_source"] = source
        
        Analytics.setAnalyticsCollectionEnabled(true)
        
        /*
          We may need this
         https://emndeniz.medium.com/push-utm-tracking-on-ios-a227e57e69d7
        Task {
            
            for _ in 0...5 {
                if let sessionId =  try? await Analytics.sessionID()  {
                    params["session_id"] = String(sessionId)
                    break
                } else {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }
            }
         
            ...
        */
            
        // Add the full URL for reference
        // params["page_location"] = url.absoluteString
        
        print("[Firebase Analytics] Campaign attribution set:")
        print("  User Properties: \(utmParams)")
        print("  Event Parameters: \(params)")
        
        // Log both the standard campaign_details event and a custom event
        Analytics.logEvent(AnalyticsEventCampaignDetails, parameters: params)
        Analytics.logEvent("campaign_details_custom", parameters: params)
        
        
        Analytics.logEvent(
            AnalyticsEventScreenView,
            parameters: [
                AnalyticsParameterScreenName: url.pathComponents.joined(separator: "/"),
                AnalyticsParameterScreenClass: url.pathComponents.joined(separator: "/")
            ]
        )
    }

    /// Extracts UTM parameters from a URL
    /// - Parameter url: The URL to extract parameters from
    /// - Returns: Dictionary of UTM parameter names to values
    private static func extractUTMParameters(from url: URL) -> [String: String] {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return [:]
        }

        var utmParams: [String: String] = [:]

        // Extract all UTM parameters
        let utmKeys = ["utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content"]

        for item in queryItems {
            if utmKeys.contains(item.name), let value = item.value {
                utmParams[item.name] = value
            }
        }

        return utmParams
    }
}
