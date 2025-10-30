//
//  CampaignTracker.swift
//  Traceback
//
//  Created by Nacho Sanchez on 24/10/25.
//

import Foundation

class CampaignTracker {
    private let userDefaults: UserDefaults
    private let seenCampaignsKey = "_traceback_seen_campaigns"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // Get all seen campaigns
    private func getSeenCampaigns() -> Set<String> {
        if let campaigns = userDefaults.array(forKey: seenCampaignsKey) as? [String] {
            return Set(campaigns)
        }
        return Set()
    }
    
    // Save seen campaigns
    private func saveSeenCampaigns(_ campaigns: Set<String>) {
        userDefaults.set(Array(campaigns), forKey: seenCampaignsKey)
    }
    
    // Check if campaign has been seen before
    func hasSeenCampaign(_ campaign: String) -> Bool {
        return getSeenCampaigns().contains(campaign)
    }
    
    // Mark campaign as seen
    func markCampaignAsSeen(_ campaign: String) {
        var campaigns = getSeenCampaigns()
        campaigns.insert(campaign)
        saveSeenCampaigns(campaigns)
    }
    
    // Check and mark in one operation (returns true if first time)
    func isFirstTimeSeen(_ campaign: String) -> Bool {
        let isFirstTime = !hasSeenCampaign(campaign)
        if isFirstTime {
            markCampaignAsSeen(campaign)
        }
        return isFirstTime
    }
    
    // Clear all seen campaigns (useful for testing)
    func clearSeenCampaigns() {
        userDefaults.removeObject(forKey: seenCampaignsKey)
    }
}
