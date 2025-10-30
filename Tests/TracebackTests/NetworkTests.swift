import Testing
import Foundation
@testable import Traceback

// MARK: - NetworkConfiguration Tests

@Test
func testNetworkConfigurationInitialization() throws {
    let hostURL = URL(string: "https://api.example.com")!
    let config = NetworkConfiguration(host: hostURL)

    #expect(config.host == hostURL)
    #expect(config.host.absoluteString == "https://api.example.com")
}

@Test
func testNetworkConfigurationWithComplexURL() throws {
    let complexURL = URL(string: "https://subdomain.example.com:8080/api/v1")!
    let config = NetworkConfiguration(host: complexURL)

    #expect(config.host == complexURL)
    #expect(config.host.scheme == "https")
    #expect(config.host.host == "subdomain.example.com")
    #expect(config.host.port == 8080)
    #expect(config.host.path == "/api/v1")
}

// MARK: - Network.fetch Generic Method Tests

@Test
func testNetworkFetchSuccess() async throws {
    // Test data that matches our Decodable type
    struct TestResponse: Decodable, Equatable {
        let id: Int
        let name: String
        let active: Bool
    }

    let expectedResponse = TestResponse(id: 123, name: "Test Item", active: true)
    let jsonString = """
    {
        "id": 123,
        "name": "Test Item",
        "active": true
    }
    """
    let jsonData = jsonString.data(using: .utf8)!

    let mockNetwork = Network { request in
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        return (jsonData, response)
    }

    let testRequest = URLRequest(url: URL(string: "https://example.com/test")!)
    let result: TestResponse = try await mockNetwork.fetch(TestResponse.self, request: testRequest)

    #expect(result == expectedResponse)
    #expect(result.id == 123)
    #expect(result.name == "Test Item")
    #expect(result.active == true)
}

@Test
func testNetworkFetchJSONDecodingError() async throws {
    // Return invalid JSON data
    let invalidJsonData = "{ invalid json }".data(using: .utf8)!

    let mockNetwork = Network { request in
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        return (invalidJsonData, response)
    }

    struct TestResponse: Decodable {
        let id: Int
        let name: String
    }

    let testRequest = URLRequest(url: URL(string: "https://example.com/test")!)

    do {
        let _ = try await mockNetwork.fetch(TestResponse.self, request: testRequest)
        #expect(Bool(false), "Expected JSON decoding error to be thrown")
    } catch {
        #expect(error is DecodingError)
    }
}

@Test
func testNetworkFetchWithComplexType() async throws {
    // Test with nested objects and arrays
    struct NestedResponse: Decodable, Equatable {
        let users: [User]
        let metadata: Metadata

        struct User: Decodable, Equatable {
            let id: Int
            let email: String
            let permissions: [String]
        }

        struct Metadata: Decodable, Equatable {
            let total: Int
            let page: Int
            let hasMore: Bool
        }
    }

    let jsonString = """
    {
        "users": [
            {
                "id": 1,
                "email": "user1@example.com",
                "permissions": ["read", "write"]
            },
            {
                "id": 2,
                "email": "user2@example.com",
                "permissions": ["read"]
            }
        ],
        "metadata": {
            "total": 25,
            "page": 1,
            "hasMore": true
        }
    }
    """

    let jsonData = jsonString.data(using: .utf8)!

    let mockNetwork = Network { request in
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        return (jsonData, response)
    }

    let testRequest = URLRequest(url: URL(string: "https://example.com/users")!)
    let result: NestedResponse = try await mockNetwork.fetch(NestedResponse.self, request: testRequest)

    #expect(result.users.count == 2)
    #expect(result.users[0].email == "user1@example.com")
    #expect(result.users[0].permissions.count == 2)
    #expect(result.users[1].permissions.count == 1)
    #expect(result.metadata.total == 25)
    #expect(result.metadata.hasMore == true)
}

@Test
func testNetworkErrorWithNonHTTPResponse() throws {
    // Test with a non-HTTP URL response (like file:// or data:// URLs)
    let fileURL = URL(string: "file:///tmp/test.json")!
    let nonHTTPResponse = URLResponse(
        url: fileURL,
        mimeType: "application/json",
        expectedContentLength: 100,
        textEncodingName: nil
    )

    let networkError = NetworkError(response: nonHTTPResponse)
    #expect(networkError == .unknown)
}

@Test
func testNetworkErrorWithEdgeCaseStatusCodes() throws {
    // Test various HTTP status codes
    let testCases: [(Int, NetworkError?)] = [
        (200, nil),           // Success
        (201, nil),           // Created
        (204, nil),           // No Content
        (300, nil),           // Multiple Choices (3xx are not errors in this implementation)
        (399, nil),           // Last 3xx code
        (400, .httpError(statusCode: 400)),  // Bad Request
        (401, .httpError(statusCode: 401)),  // Unauthorized
        (404, .httpError(statusCode: 404)),  // Not Found
        (429, .httpError(statusCode: 429)),  // Too Many Requests
        (500, .httpError(statusCode: 500)),  // Internal Server Error
        (503, .httpError(statusCode: 503)),  // Service Unavailable
        (599, .httpError(statusCode: 599))   // Custom error code
    ]

    for (statusCode, expectedError) in testCases {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!

        let networkError = NetworkError(response: response)
        #expect(networkError == expectedError, "Failed for status code \(statusCode)")
    }
}

@Test
func testNetworkErrorFromExistingNetworkError() throws {
    // Test that creating a NetworkError from an existing NetworkError returns the same error
    let originalError = NetworkError.httpError(statusCode: 404)
    let wrappedError = NetworkError(error: originalError)

    #expect(wrappedError == originalError)
}

@Test
func testNetworkErrorFromVariousURLErrorCodes() throws {
    // Test different URLError codes and their mappings
    let testCases: [(URLError.Code, NetworkError)] = [
        (.notConnectedToInternet, .noConnection),
        (.timedOut, .noConnection),
        (.cannotFindHost, .unknown),
        (.cannotConnectToHost, .unknown),
        (.networkConnectionLost, .unknown),
        (.dnsLookupFailed, .unknown),
        (.httpTooManyRedirects, .unknown),
        (.resourceUnavailable, .unknown),
        (.notConnectedToInternet, .noConnection),
        (.badURL, .unknown),
        (.cancelled, .unknown)
    ]

    for (urlErrorCode, expectedError) in testCases {
        let urlError = URLError(urlErrorCode)
        let networkError = NetworkError(error: urlError)

        #expect(networkError == expectedError, "Failed for URLError code \(urlErrorCode)")
    }
}

@Test
func testNetworkErrorFromNonURLError() throws {
    // Test with various non-URLError types
    struct CustomError: Error {}
    enum TestError: Error {
        case someError
    }

    let customError = CustomError()
    let enumError = TestError.someError
    let nsError = NSError(domain: "TestDomain", code: 123, userInfo: nil)

    #expect(NetworkError(error: customError) == .unknown)
    #expect(NetworkError(error: enumError) == .unknown)
    #expect(NetworkError(error: nsError) == .unknown)
}

// MARK: - Integration Tests for Network Components

@Test
func testNetworkConfigurationWithAPIProvider() async throws {
    let host = URL(string: "https://api.traceback.com")!
    let config = NetworkConfiguration(host: host)

    let mockNetwork = Network { request in
        // Verify the request URL uses the configured host
        #expect(request.url?.host == "api.traceback.com")
        #expect(request.url?.scheme == "https")

        let jsonString = """
        {
            "deep_link_id": "https://example.com/test",
            "match_message": "Success",
            "match_type": "unique",
            "match_campaign": "summer_sale",
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

    let apiProvider = APIProvider(config: config, network: mockNetwork)

    // This test verifies that NetworkConfiguration is properly used by APIProvider
    let testFingerprint = DeviceFingerprint(
        appInstallationTime: 1234567890,
        bundleId: "com.test.app",
        osVersion: "18.0",
        sdkVersion: "1.0.0",
        uniqueMatchLinkToCheck: nil,
        intentLink: nil,
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

    let _ = try await apiProvider.sendFingerprint(testFingerprint)
    // If we get here, the test passed - no exception was thrown
}

@Test
func testNetworkFetchWithHTTPErrorHandling() async throws {
    // Test that Network.fetch properly handles HTTP errors through the fetchData closure
    let mockNetwork = Network { request in
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )!
        return ("{\"success\": false}".data(using: .utf8)!, response)
    }

    struct TestResponse: Decodable {
        let success: Bool
    }

    let testRequest = URLRequest(url: URL(string: "https://example.com/test")!)

    // The fetch method doesn't automatically check HTTP status codes in the Network layer
    // It only handles JSON decoding and network transport errors
    // HTTP status code checking is handled at higher levels (e.g., in Network.live)
    let result = try await mockNetwork.fetch(TestResponse.self, request: testRequest)

    #expect(result.success == false)
}
