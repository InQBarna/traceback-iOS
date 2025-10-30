import Testing
import Foundation
@testable import Traceback

@Test
func testCampaignTrackerBasicFlow() throws {
    let suiteName = "test.campaignTracker.\(UUID().uuidString)"
    guard let defaults = UserDefaults(suiteName: suiteName) else {
        throw NSError(domain: "UserDefaultsInit", code: 1)
    }
    // Ensure a clean slate
    defaults.removePersistentDomain(forName: suiteName)

    let tracker = CampaignTracker(userDefaults: defaults)

    // fresh state
    #expect(tracker.hasSeenCampaign("campaign1") == false)
    #expect(tracker.isFirstTimeSeen("campaign1") == true)
    #expect(tracker.hasSeenCampaign("campaign1") == true)
    #expect(tracker.isFirstTimeSeen("campaign1") == false)

    // mark another campaign
    tracker.markCampaignAsSeen("campaign2")
    #expect(tracker.hasSeenCampaign("campaign2") == true)

    // clear
    tracker.clearSeenCampaigns()
    #expect(tracker.hasSeenCampaign("campaign1") == false)
    #expect(tracker.hasSeenCampaign("campaign2") == false)

    // cleanup
    defaults.removePersistentDomain(forName: suiteName)
}

@Test
func testPersistenceAcrossInstances() throws {
    let suiteName = "test.campaignTracker.\(UUID().uuidString)"
    guard let defaults = UserDefaults(suiteName: suiteName) else {
        throw NSError(domain: "UserDefaultsInit", code: 1)
    }
    defaults.removePersistentDomain(forName: suiteName)

    let tracker1 = CampaignTracker(userDefaults: defaults)
    #expect(tracker1.hasSeenCampaign("persist") == false)
    tracker1.markCampaignAsSeen("persist")
    #expect(tracker1.hasSeenCampaign("persist") == true)

    // Create a new tracker backed by the same suite to ensure persistence
    let tracker2 = CampaignTracker(userDefaults: defaults)
    #expect(tracker2.hasSeenCampaign("persist") == true)

    // cleanup
    defaults.removePersistentDomain(forName: suiteName)
}

@Test
func testEmptyCampaignString() throws {
    let suiteName = "test.campaignTracker.\(UUID().uuidString)"
    guard let defaults = UserDefaults(suiteName: suiteName) else {
        throw NSError(domain: "UserDefaultsInit", code: 1)
    }
    defaults.removePersistentDomain(forName: suiteName)

    let tracker = CampaignTracker(userDefaults: defaults)

    #expect(tracker.isFirstTimeSeen("") == true)
    #expect(tracker.isFirstTimeSeen("") == false)

    defaults.removePersistentDomain(forName: suiteName)
}
