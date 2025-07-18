//
//  ModelTests.swift
//  iOSEngineerCodeCheck
//
//  Created by Antoni Remeseiro Alfonso on 2025/07/16.
//  Copyright © 2025 YUMEMI Inc. All rights reserved.
//

import XCTest
@testable import iOSEngineerCodeCheck // Ensure this is present

final class ModelTests: XCTestCase {
    let loader = TestBundleLoader() // Use the updated loader
    
    func testDecodingGitHubSearchResponse() throws {
        // Given
        // Use the name of your JSON file without extension
        let searchResponse = try loader.loadJSON(type: GitHubSearchResponse.self,
                                                 fromFile: "search_response",
                                                 bundleClass: type(of: self))
        
        // Then
        XCTAssertNotNil(searchResponse)
        XCTAssertEqual(searchResponse.totalCount, 2281095) // Assert based on your actual JSON content
        XCTAssertFalse(searchResponse.incompleteResults)
        XCTAssertGreaterThan(searchResponse.items.count, 0) // Ensure items array is not empty
        XCTAssertEqual(searchResponse.items.first?.name, "ai") // Assert a specific item property
        XCTAssertEqual(searchResponse.items.first?.owner?.login, "vercel") // Check nested properties
        XCTAssertEqual(searchResponse.items.first?.stargazersCount, 15732) // Check another property like stargazers count
    }
    
    // Add more tests for individual models if they can be decoded separately
    
    // Test Decoding Repository
    func testDecodingRepository() throws {
        // Use the name of your JSON file without extension
        let repositoryResponse = try loader.loadJSON(type: Repository.self,
                                                     fromFile: "repository",
                                                     bundleClass: type(of: self))
        
        // Create an ISO8601DateFormatter directly for test assertions to test dates
        let dateFormatter = ISO8601DateFormatter()
        
        // Then
        XCTAssertNotNil(repositoryResponse)
        XCTAssertNotNil(repositoryResponse.license) // Ensure license is also there
        XCTAssertEqual(repositoryResponse.fullName, "microsoft/AI") // Assert a specific item property
        XCTAssertEqual(repositoryResponse.owner?.avatarUrl, "https://avatars.githubusercontent.com/u/6154722?v=4") // Check nested properties
        XCTAssertEqual(repositoryResponse.watchersCount, 1924) // Check another property like stargazers count
        
        // Use the dateFormatter to parse the expected date strings
        XCTAssertEqual(repositoryResponse.createdAt, dateFormatter.date(from: "2019-09-04T22:59:06Z"))
        XCTAssertEqual(repositoryResponse.updatedAt, dateFormatter.date(from: "2025-07-14T08:21:48Z"))
        XCTAssertEqual(repositoryResponse.pushedAt, dateFormatter.date(from: "2025-05-10T20:24:19Z"))
    }
    
    // Test decoding Github API Error JSON response
    func testDecodingGithubAPIError() throws {
        // Use the name of your JSON file without extension
        let errorResponse = try loader.loadJSON(type: GitHubAPIErrorResponse.self,
                                                     fromFile: "github_error",
                                                     bundleClass: type(of: self))
        
        // Then
        XCTAssertNotNil(errorResponse)
        XCTAssertNotNil(errorResponse.errors) // Ensure license is also there
        XCTAssertEqual(errorResponse.message, "Validation Failed") // Assert a specific item property
        XCTAssertEqual(errorResponse.errors?.first?.code, "missing") // Check nested properties
        XCTAssertEqual(errorResponse.status, "422") // Check another property like stargazers count
    }
}
