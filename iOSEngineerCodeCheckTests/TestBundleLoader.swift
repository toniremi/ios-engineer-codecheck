//
//  TestBundleLoader.swift
//  iOSEngineerCodeCheck
//
//  Created by Antoni Remeseiro Alfonso on 2025/07/16.
//  Copyright © 2025 YUMEMI Inc. All rights reserved.
//

import Foundation

enum TestLoaderError: Error, LocalizedError {
    case fileNotFound(String)
    case invalidData(String) // For decoding failures
    case bundleAccessError(String) // For issues getting the bundle or URL

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "Could not find file '\(filename)' in the test bundle."
        case .invalidData(let filename):
            return "Invalid data in file '\(filename)' for decoding."
        case .bundleAccessError(let message):
            return "Bundle access error: \(message)"
        }
    }
}

// Renamed and adjusted for loading from the test bundle
class TestBundleLoader {

    /// Loads raw Data from a file within the test bundle.
    /// - Parameters:
    ///   - name: The name of the file (e.g., "search_response").
    ///   - fileExtension: The file extension (e.g., "json").
    ///   - bundleClass: A class within the test bundle (e.g., your XCTestCase class) to correctly identify the bundle.
    func loadData(fromFile name: String, withExtension fileExtension: String, bundleClass: AnyClass) throws -> Data {
        guard let url = Bundle(for: bundleClass).url(forResource: name, withExtension: fileExtension) else {
            throw TestLoaderError.fileNotFound("\(name).\(fileExtension)")
        }
        do {
            return try Data(contentsOf: url)
        } catch {
            throw TestLoaderError.bundleAccessError("Failed to load data from URL \(url): \(error.localizedDescription)")
        }
    }

    /// Loads and decodes JSON from a file within the test bundle into a Decodable type.
    /// - Parameters:
    ///   - type: The Decodable type to decode into (e.g., GitHubSearchResponse.self).
    ///   - name: The name of the JSON file (e.g., "search_response").
    ///   - bundleClass: A class within the test bundle (e.g., your XCTestCase class) to correctly identify the bundle.
    func loadJSON<T: Decodable>(type: T.Type, fromFile name: String, bundleClass: AnyClass) throws -> T {
        let data = try loadData(fromFile: name, withExtension: "json", bundleClass: bundleClass)
        let decoder = JSONDecoder()

        // Configure decoding strategy for GitHub Responses
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(type, from: data)
        } catch {
            print("Decoding error for \(name).json: \(error.localizedDescription)")
            throw TestLoaderError.invalidData("\(name).json")
        }
    }
}
