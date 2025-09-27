import Testing
import Foundation
import UIKit
@testable import Traceback

// MARK: - Configuration Tests

@Test
func testTracebackConfiguration() throws {
    let mainHost = URL(string: "https://example-traceback.firebaseapp.com")!
    let additionalHosts = [URL(string: "https://custom.example.com")!]

    let config = TracebackConfiguration(
        mainAssociatedHost: mainHost,
        associatedHosts: additionalHosts,
        useClipboard: true,
        logLevel: .debug
    )

    #expect(config.mainAssociatedHost == mainHost)
    #expect(config.associatedHosts == additionalHosts)
    #expect(config.useClipboard == true)
    #expect(config.logLevel == .debug)
}

@Test
func testTracebackConfigurationDefaults() throws {
    let mainHost = URL(string: "https://example-traceback.firebaseapp.com")!

    let config = TracebackConfiguration(mainAssociatedHost: mainHost)

    #expect(config.mainAssociatedHost == mainHost)
    #expect(config.associatedHosts == nil)
    #expect(config.useClipboard == true)
    #expect(config.logLevel == .info)
}

// MARK: - URL Extraction Tests

@Test
func testExtractLinkFromURL() throws {
    let config = TracebackConfiguration(
        mainAssociatedHost: URL(string: "https://example.firebaseapp.com")!
    )
    let sdk = TracebackSDK.live(config: config)

    // Test valid URL with link parameter
    let urlWithLink = URL(string: "https://example.com?link=https%3A%2F%2Fmyapp.com%2Fproduct%2F123")!
    let result = try sdk.extractLinkFromURL(urlWithLink)

    #expect(result?.url?.absoluteString == "https://myapp.com/product/123")
    #expect(result?.match_type == TracebackSDK.MatchType.unknown)
}

@Test
func testExtractLinkFromURLWithoutLinkParameter() throws {
    let config = TracebackConfiguration(
        mainAssociatedHost: URL(string: "https://example.firebaseapp.com")!
    )
    let sdk = TracebackSDK.live(config: config)

    // Test URL without link parameter
    let urlWithoutLink = URL(string: "https://example.com?other=value")!
    let result = try sdk.extractLinkFromURL(urlWithoutLink)

    #expect(result?.url == nil)
    #expect(result?.match_type == TracebackSDK.MatchType.unknown)
}

@Test
func testExtractLinkFromURLWithMultipleQueryParams() throws {
    let config = TracebackConfiguration(
        mainAssociatedHost: URL(string: "https://example.firebaseapp.com")!
    )
    let sdk = TracebackSDK.live(config: config)

    // Test URL with multiple query parameters including link
    let complexURL = URL(string: "https://example.com?utm_source=email&link=https%3A%2F%2Fmyapp.com%2Fshare%2Fabc&utm_campaign=test")!
    let result = try sdk.extractLinkFromURL(complexURL)

    #expect(result?.url?.absoluteString == "https://myapp.com/share/abc")
    #expect(result?.match_type == TracebackSDK.MatchType.unknown)
}

// MARK: - Response Model Tests

@Test
func testPostInstallLinkSearchResponseMatchTypes() throws {
    // Test unique match type
    let uniqueResponse = PostInstallLinkSearchResponse(
        deep_link_id: URL(string: "https://example.com/product/123"),
        match_message: "Unique match found",
        match_type: "unique",
        request_ip_version: "ipv4",
        utm_medium: "social",
        utm_source: "facebook"
    )
    #expect(uniqueResponse.matchType == TracebackSDK.MatchType.unique)

    // Test none match type
    let noneResponse = PostInstallLinkSearchResponse(
        deep_link_id: nil,
        match_message: "No match found",
        match_type: "none",
        request_ip_version: "ipv4",
        utm_medium: nil,
        utm_source: nil
    )
    #expect(noneResponse.matchType == TracebackSDK.MatchType.none)

    // Test ambiguous match type
    let ambiguousResponse = PostInstallLinkSearchResponse(
        deep_link_id: URL(string: "https://example.com/default"),
        match_message: "Ambiguous match",
        match_type: "ambiguous",
        request_ip_version: "ipv4",
        utm_medium: nil,
        utm_source: nil
    )
    #expect(ambiguousResponse.matchType == TracebackSDK.MatchType.default)

    // Test unknown match type
    let unknownResponse = PostInstallLinkSearchResponse(
        deep_link_id: nil,
        match_message: "Unknown",
        match_type: "other",
        request_ip_version: "ipv4",
        utm_medium: nil,
        utm_source: nil
    )
    #expect(unknownResponse.matchType == TracebackSDK.MatchType.unknown)
}

// MARK: - Network Error Tests

@Test
func testNetworkErrorFromURLError() throws {
    // Test no connection error
    let noConnectionError = URLError(.notConnectedToInternet)
    let networkError = NetworkError(error: noConnectionError)
    #expect(networkError == .noConnection)

    // Test timeout error
    let timeoutError = URLError(.timedOut)
    let timeoutNetworkError = NetworkError(error: timeoutError)
    #expect(timeoutNetworkError == .noConnection)

    // Test other URL error
    let otherError = URLError(.badURL)
    let otherNetworkError = NetworkError(error: otherError)
    #expect(otherNetworkError == .unknown)

    // Test non-URL error
    struct CustomError: Error {}
    let customError = CustomError()
    let customNetworkError = NetworkError(error: customError)
    #expect(customNetworkError == .unknown)
}

@Test
func testNetworkErrorFromHTTPResponse() throws {
    // Test 404 error
    let badResponse = HTTPURLResponse(
        url: URL(string: "https://example.com")!,
        statusCode: 404,
        httpVersion: nil,
        headerFields: nil
    )!
    let networkError = NetworkError(response: badResponse)
    #expect(networkError == .httpError(statusCode: 404))

    // Test 500 error
    let serverError = HTTPURLResponse(
        url: URL(string: "https://example.com")!,
        statusCode: 500,
        httpVersion: nil,
        headerFields: nil
    )!
    let serverNetworkError = NetworkError(response: serverError)
    #expect(serverNetworkError == .httpError(statusCode: 500))

    // Test successful response
    let successResponse = HTTPURLResponse(
        url: URL(string: "https://example.com")!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
    )!
    let successNetworkError = NetworkError(response: successResponse)
    #expect(successNetworkError == nil)
}

// MARK: - Analytics Event Tests

@Test
func testAnalyticsEvents() throws {
    let testURL = URL(string: "https://example.com/product/123")!

    // Test post-install detected event
    let detectedEvent = TracebackAnalyticsEvent.postInstallDetected(testURL)

    switch detectedEvent {
    case .postInstallDetected(let url):
        #expect(url == testURL)
    case .postInstallError:
        #expect(Bool(false), "Expected postInstallDetected event")
    }

    // Test post-install error event
    struct TestError: Error {}
    let error = TestError()
    let errorEvent = TracebackAnalyticsEvent.postInstallError(error)

    switch errorEvent {
    case .postInstallDetected:
        #expect(Bool(false), "Expected postInstallError event")
    case .postInstallError(let receivedError):
        #expect(receivedError is TestError)
    }
}

// MARK: - Device Info Tests

@Test
func testDeviceFingerprintDeviceInfo() throws {
    let deviceInfo = DeviceFingerprint.DeviceInfo(
        deviceModelName: "iPhone15,2",
        languageCode: "en-US",
        languageCodeFromWebView: "en-US",
        languageCodeRaw: "en_US",
        appVersionFromWebView: "1.0.0",
        screenResolutionWidth: 393,
        screenResolutionHeight: 852,
        timezone: "America/New_York"
    )

    #expect(deviceInfo.deviceModelName == "iPhone15,2")
    #expect(deviceInfo.languageCode == "en-US")
    #expect(deviceInfo.languageCodeFromWebView == "en-US")
    #expect(deviceInfo.languageCodeRaw == "en_US")
    #expect(deviceInfo.appVersionFromWebView == "1.0.0")
    #expect(deviceInfo.screenResolutionWidth == 393)
    #expect(deviceInfo.screenResolutionHeight == 852)
    #expect(deviceInfo.timezone == "America/New_York")
}

@Test
func testDeviceFingerprintEquality() throws {
    let deviceInfo1 = DeviceFingerprint.DeviceInfo(
        deviceModelName: "iPhone15,2",
        languageCode: "en-US",
        languageCodeFromWebView: nil,
        languageCodeRaw: "en_US",
        appVersionFromWebView: nil,
        screenResolutionWidth: 393,
        screenResolutionHeight: 852,
        timezone: "America/New_York"
    )

    let deviceInfo2 = DeviceFingerprint.DeviceInfo(
        deviceModelName: "iPhone15,2",
        languageCode: "en-US",
        languageCodeFromWebView: nil,
        languageCodeRaw: "en_US",
        appVersionFromWebView: nil,
        screenResolutionWidth: 393,
        screenResolutionHeight: 852,
        timezone: "America/New_York"
    )

    let fingerprint1 = DeviceFingerprint(
        appInstallationTime: 1234567890,
        bundleId: "com.example.app",
        osVersion: "18.0",
        sdkVersion: "1.0.0",
        uniqueMatchLinkToCheck: nil,
        device: deviceInfo1
    )

    let fingerprint2 = DeviceFingerprint(
        appInstallationTime: 1234567890,
        bundleId: "com.example.app",
        osVersion: "18.0",
        sdkVersion: "1.0.0",
        uniqueMatchLinkToCheck: nil,
        device: deviceInfo2
    )

    #expect(fingerprint1 == fingerprint2)
}

// MARK: - Integration Tests with Mock Network

@Test
func testAPIProviderWithMockNetwork() async throws {
    let mockNetwork = Network { request in
        // Create JSON manually since PostInstallLinkSearchResponse is only Decodable
        let jsonString = """
        {
            "deep_link_id": "https://example.com/product/123",
            "match_message": "Test match",
            "match_type": "unique",
            "request_ip_version": "ipv4",
            "utm_medium": null,
            "utm_source": null
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        return (jsonData, response)
    }

    let config = NetworkConfiguration(host: URL(string: "https://test.firebaseapp.com")!)
    let apiProvider = APIProvider(config: config, network: mockNetwork)

    let testFingerprint = DeviceFingerprint(
        appInstallationTime: 1234567890,
        bundleId: "com.test.app",
        osVersion: "18.0",
        sdkVersion: "1.0.0",
        uniqueMatchLinkToCheck: URL(string: "https://test.com/link"),
        device: DeviceFingerprint.DeviceInfo(
            deviceModelName: "iPhone15,2",
            languageCode: "en-US",
            languageCodeFromWebView: nil,
            languageCodeRaw: "en_US",
            appVersionFromWebView: nil,
            screenResolutionWidth: 393,
            screenResolutionHeight: 852,
            timezone: "America/New_York"
        )
    )

    let response = try await apiProvider.sendFingerprint(testFingerprint)

    #expect(response.deep_link_id?.absoluteString == "https://example.com/product/123")
    #expect(response.match_type == "unique")
    #expect(response.matchType == TracebackSDK.MatchType.unique)
}

@Test
func testAPIProviderNetworkError() async throws {
    let mockNetwork = Network { request in
        throw URLError(.notConnectedToInternet)
    }

    let config = NetworkConfiguration(host: URL(string: "https://test.firebaseapp.com")!)
    let apiProvider = APIProvider(config: config, network: mockNetwork)

    let testFingerprint = DeviceFingerprint(
        appInstallationTime: 1234567890,
        bundleId: "com.test.app",
        osVersion: "18.0",
        sdkVersion: "1.0.0",
        uniqueMatchLinkToCheck: nil,
        device: DeviceFingerprint.DeviceInfo(
            deviceModelName: "iPhone15,2",
            languageCode: "en-US",
            languageCodeFromWebView: nil,
            languageCodeRaw: "en_US",
            appVersionFromWebView: nil,
            screenResolutionWidth: 393,
            screenResolutionHeight: 852,
            timezone: "America/New_York"
        )
    )

    do {
        let _ = try await apiProvider.sendFingerprint(testFingerprint)
        #expect(Bool(false), "Expected network error to be thrown")
    } catch {
        #expect(error is NetworkError)
        if let networkError = error as? NetworkError {
            #expect(networkError == .noConnection)
        }
    }
}

// MARK: - URL Components Edge Cases

@Test
func testExtractLinkFromURLWithMalformedEncoding() throws {
    let config = TracebackConfiguration(
        mainAssociatedHost: URL(string: "https://example.firebaseapp.com")!
    )
    let sdk = TracebackSDK.live(config: config)

    // Test URL with improperly encoded link parameter
    let malformedURL = URL(string: "https://example.com?link=https://myapp.com/product/123")! // Not URL encoded
    let result = try sdk.extractLinkFromURL(malformedURL)

    // Should still extract the link even if not properly encoded
    #expect(result?.url?.absoluteString == "https://myapp.com/product/123")
}

// MARK: - Result Object Tests

@Test
func testResultObjectCreation() throws {
    let testURL = URL(string: "https://example.com/test")!
    let testAnalytics = [TracebackAnalyticsEvent.postInstallDetected(testURL)]

    let result = TracebackSDK.Result(
        url: testURL,
        match_type: .unique,
        analytics: testAnalytics
    )

    #expect(result.url == testURL)
    #expect(result.match_type == TracebackSDK.MatchType.unique)
    #expect(result.analytics.count == 1)

    if case .postInstallDetected(let analyticsURL) = result.analytics.first {
        #expect(analyticsURL == testURL)
    } else {
        #expect(Bool(false), "Expected postInstallDetected analytics event")
    }
}

@Test
func testEmptyResult() throws {
    let emptyResult = TracebackSDK.Result.empty

    #expect(emptyResult.url == nil)
    #expect(emptyResult.match_type == TracebackSDK.MatchType.none)
    #expect(emptyResult.analytics.isEmpty)
}
