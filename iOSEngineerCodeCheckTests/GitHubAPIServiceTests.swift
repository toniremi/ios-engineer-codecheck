//
//  GitHubAPIServiceTests.swift
//  iOSEngineerCodeCheck
//
//  Created by Antoni Remeseiro Alfonso on 2025/07/16.
//  Copyright © 2025 YUMEMI Inc. All rights reserved.
//

import XCTest
@testable import iOSEngineerCodeCheck

class GitHubAPIServiceTests: XCTestCase {
    
    var service: GitHubAPIService! // service to test
    var mockURLSession: URLSession! // mock session
    let testLoader = TestBundleLoader() // Initialize the TestBundleLoader
    
    override func setUpWithError() throws {
        // This is called before each test method begins
        try super.setUpWithError()
        // Set up a mock URLSession for network requests
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self] // Register your mock URLProtocol
        mockURLSession = URLSession(configuration: configuration)
        service = GitHubAPIService(session: mockURLSession) // Inject the mock session
    }
    
    override func tearDownWithError() throws {
        // This is called after each test method completes
        service = nil
        mockURLSession = nil
        MockURLProtocol.stubResponse = nil // Clear any stubbed responses
        try super.tearDownWithError()
    }
    
    func testSearchRepositories_success() async throws {
        // Given
        let query = "AI"
        
        // Load the JSON data from your file using the TestBundleLoader
        let expectedData = try testLoader.loadData(fromFile: "search_response", withExtension: "json", bundleClass: type(of: self))
        
        let response = try XCTUnwrap(HTTPURLResponse(url: URL(string: "https://api.github.com/search/repositories?q=\(query)")!,
                                                     statusCode: 200,
                                                     httpVersion: nil,
                                                     headerFields: nil))
        
        MockURLProtocol.stubResponse = (expectedData, response, nil) // Use the loaded data
        
        // When
        let result = try await service.searchRepositories(query: query)
        
        // Then
        XCTAssertEqual(result.totalCount, 2281095) // Assert based on your actual JSON content
        XCTAssertFalse(result.incompleteResults)
        XCTAssertGreaterThan(result.items.count, 0)
        XCTAssertEqual(result.items.first?.name, "ai")
        XCTAssertEqual(result.items.first?.owner?.login, "vercel")
    }
    
    func testSearchRepositories_invalidURL() async {
        // Given
        // No stub needed, as the error occurs before network request
        
        // When
        do {
            _ = try await service.searchRepositories(query: " invalid url ")
            XCTFail("Expected an error but no error was thrown.")
        } catch let error as APIError {
            // Then
            // We now expect the networkError from MockURLProtocol's default behavior
            guard case .networkError(let nsError as NSError) = error else {
                XCTFail("Expected APIError.networkError but got \(error)")
                return
            }
            XCTAssertEqual(nsError.domain, "MockURLProtocolError")
            XCTAssertEqual(nsError.code, 0)
            XCTAssertEqual(nsError.localizedDescription, "No stubbed response or error found.")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testSearchRepositories_networkError() async {
        // Given
        let networkError = URLError(.notConnectedToInternet)
        MockURLProtocol.stubResponse = (nil, nil, networkError) // Stub a network error
        
        // When
        do {
            _ = try await service.searchRepositories(query: "test")
            XCTFail("Expected networkError but no error was thrown.")
        } catch let error as APIError {
            // Then
            XCTAssertEqual(error, APIError.networkError(networkError))
            XCTAssertEqual(error.localizedDescription, APIError.networkError(networkError).localizedDescription)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // Add more tests for httpError, unauthorized, decodingError, etc.
}

// MARK: - MockURLProtocol for Stubbing Network Requests

class MockURLProtocol: URLProtocol {
    static var stubResponse: (data: Data?, response: HTTPURLResponse?, error: Error?)?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true // Handle all requests for testing purposes
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        if let error = MockURLProtocol.stubResponse?.error {
            // If there's an error, send the failure and stop
            client?.urlProtocol(self, didFailWithError: error)
        } else if let response = MockURLProtocol.stubResponse?.response {
            // If there's a response, send it
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            
            // If there's data, send it
            if let data = MockURLProtocol.stubResponse?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            // After successful response and data (if any), signal completion
            client?.urlProtocolDidFinishLoading(self)
        } else {
            // Handle case where no stubbed response or error is set (e.g., an unexpected empty stub)
            // Or, you might want to assert/fail the test if this state is truly unexpected.
            // For now, let's treat it as a generic network error.
            client?.urlProtocol(self, didFailWithError: NSError(domain: "MockURLProtocolError",
                                                                code: 0,
                                                                userInfo: [NSLocalizedDescriptionKey: "No stubbed response or error found."]))
        }
    }
    
    override func stopLoading() {
        // This method is called when the client cancels the task.
        // For simple mocks like this, it often remains empty.
    }
}
