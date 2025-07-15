//
//  GithubAPIService.swift
//  iOSEngineerCodeCheck
//
//  Created by Antoni Remeseiro Alfonso on 2025/07/15.
//  Copyright © 2025 YUMEMI Inc. All rights reserved.
//

import Foundation
import UIKit

enum APIError: Error, LocalizedError, Equatable {
    case invalidURL
    case networkError(Error) // Original network errors from URLSession
    case httpError(Int) // Generic HTTP error with status code
    case unauthorized(message: String?) // Specific for 401, with optional message from API
    case apiError(statusCode: Int, message: String) // For other non-2xx errors with an API message
    case decodingError(Error) // For JSON decoding failures
    case unknownError // For unknown errors
    case invalidResponse // For invalid response ie: data is corrupt, data is empty, etc.

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL was invalid. Please check the application's configuration."
        case .networkError(let error):
            // Provide a more user-friendly message for common network issues
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    return "No internet connection. Please check your network settings."
                case .timedOut:
                    return "The network request timed out. Please try again."
                case .cannotConnectToHost:
                    return "Could not connect to the server. The GitHub API might be temporarily unavailable."
                default:
                    return "A network error occurred: \(urlError.localizedDescription)"
                }
            }
            return "A network error occurred: \(error.localizedDescription)"
        case .httpError(let statusCode):
            return "Server responded with status code \(statusCode). Please try again later."
        case .unauthorized(let message):
            if let msg = message, !msg.isEmpty {
                return "Authentication failed: \(msg). Please check your Personal Access Token (PAT)."
            }
            return "Authentication failed (401 Unauthorized)." +
            " Please ensure your Personal Access Token (PAT) is correct and has the necessary permissions."
        case .apiError(let statusCode, let message):
            // For other API-specific errors with a message
            return "GitHub API Error (\(statusCode)): \(message). Please try again."
        case .decodingError(let error):
            // Detailed message for decoding errors (useful for development, can be more generic for user)
            return "Failed to process data from the server. \(error.localizedDescription)"
        case .unknownError:
            return "An unexpected error occurred. Please try again."
        case .invalidResponse:
            return "The server returned an unexpected response format."
        }
    }

    // Implement Equatable conformance manually
    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL):
            return true
        case (.networkError(let lhsError), .networkError(let rhsError)):
            // For network errors, compare their localized descriptions or specific error codes
            // Comparing localizedDescription is often sufficient for testing purposes
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.httpError(let lhsCode), .httpError(let rhsCode)):
            return lhsCode == rhsCode
        case (.unauthorized(let lhsMessage), .unauthorized(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.apiError(let lhsStatusCode, let lhsMessage), .apiError(let rhsStatusCode, let rhsMessage)):
            return lhsStatusCode == rhsStatusCode && lhsMessage == rhsMessage
        case (.decodingError(let lhsError), .decodingError(let rhsError)):
            // For decoding errors, also compare localized descriptions
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.unknownError, .unknownError):
            return true
        case (.invalidResponse, .invalidResponse):
            return true
        default:
            return false // If cases don't match, they are not equal
        }
    }
}

class GitHubAPIService: GitHubAPIServiceProtocol {

    // to enable debug to print the raw response
    // useful when making changes to models and facing decode errors
    var isDebugMode: Bool = false

    // Add a session property for testability
    private let session: URLSession

    // Property to hold the current search task for cancellation
    private var currentSearchTask: Task<GitHubSearchResponse, Error>?

    // Add an initializer that accepts a URLSession, defaulting to .shared
    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Generic function to make authenticated GitHub API requests
    /// It is using: [https://docs.github.com/en/rest/quickstart?apiVersion=2022-11-28]
    /// - Parameters:
    ///     - url: The github url we want to make a request for
    ///     - personalAccessToken: the personal access token that the user generated
    func performRequest<T: Decodable>(url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        //  Use self.session for the request
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            // FIX: Catch network errors here and throw APIError.networkError
            throw APIError.networkError(error)
        }

        // Add this new guard statement to check for empty data
        guard !data.isEmpty else {
            print("Error: Received empty data from the server.")
            throw APIError.invalidResponse // Or a more specific error if you have one for empty data
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(NSError(domain: "Invalid Response", code: 0, userInfo: nil))
        }

        // Handle non-success HTTP status codes (extracted to a helper function)
        try handleHTTPStatusError(statusCode: httpResponse.statusCode, data: data)

        // MARK: - Debugging: Print Raw JSON Response
        if isDebugMode {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("--- Raw JSON Response ---")
                print(jsonString)
                print("-------------------------")
            } else {
                print("--- Could not convert data to string for debugging ---")
            }
        }

        // Decode the data (extracted to a helper function)
        return try decodeResponse(data: data)
    }

    // MARK: Helper functions to make performRequest more readable
    /// This function will handle the HTTP Status error inside performRequest
    private func handleHTTPStatusError(statusCode: Int, data: Data) throws {
        // properly check status code to return a more complete error
        // the aim is to using our new ErrorView to display a more user friendly error in the UI
        guard (200...299).contains(statusCode) else {
            // Attempt to decode a GitHub API error response
            do {
                let apiErrorResponse = try JSONDecoder().decode(GitHubAPIErrorResponse.self, from: data)

                // Specific handling for 401 Unauthorized
                if statusCode == 401 {
                    throw APIError.unauthorized(message: apiErrorResponse.message)
                } else {
                    // Other non-2xx status codes that have a message
                    throw APIError.apiError(statusCode: statusCode, message: apiErrorResponse.message)
                }
            } catch let decodingError as DecodingError {
                // If we couldn't decode a GitHubAPIErrorResponse, it might be a generic HTTP error
                // or a different error format. Log the decoding error for debugging.
                print("Failed to decode GitHubAPIErrorResponse for status " +
                      "\(statusCode): \(decodingError.localizedDescription)")
                // Fallback to generic HTTP error, but give specific 401 if it's 401
                if statusCode == 401 {
                    // throw unauthorized error without specific message
                    throw APIError.unauthorized(message: "Bad credentials") // include a message instead of nil
                } else {
                    // throw generic http error using the status code
                    throw APIError.httpError(statusCode)
                }
            } catch {
                // Catch any other errors during the error decoding process
                print("An unexpected error occurred while trying to decode API error: \(error.localizedDescription)")

                if statusCode == 401 {
                    // throw unauthorized error without specific message
                    throw APIError.unauthorized(message: "Bad credentials") // include a message instead of nil
                } else {
                    // throw generic http error using the status code
                    throw APIError.httpError(statusCode)
                }
            }
        }
    }

    /// Decode our response using the injected type
    private func decodeResponse<T: Decodable>(data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            // Debugging: Print Decoding Error details
            print("--- Decoding Error Details for successful HTTP status ---")
            print("Error: \(error.localizedDescription)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .dataCorrupted(let context):
                    print("Data corrupted: \(context.debugDescription) path: \(context.codingPath)")
                case .keyNotFound(let key, let context):
                    print("Key '\(key.stringValue)' not found: \(context.debugDescription)")
                    print("Coding path: \(context.codingPath)")
                case .typeMismatch(let type, let context):
                    print("Type mismatch for \(type): \(context.debugDescription)")
                    print("Coding path: \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print("Value not found for \(type): \(context.debugDescription)")
                    print("Coding path: \(context.codingPath)")
                @unknown default:
                    print("Unknown decoding error")
                }
            }
            print("----------------------------")
            throw APIError.decodingError(error)
        }
    }

    // MARK: Service functions to access data

    /// Search Github Repositories using a query word
    /// - Parameters:
    ///     - query: the word or keyword we want to search
    func searchRepositories(query: String) async throws -> GitHubSearchResponse {
        // Cancel any previous search task before starting a new one
        currentSearchTask?.cancel()

        // Use a Task to wrap the asynchronous operation so it can be cancelled
        currentSearchTask = Task {
            // prepare our query string
            let urlString = "https://api.github.com/search/repositories?q=\(query)"

            guard let url = URL(string: urlString) else {
                throw APIError.invalidURL
            }

            return try await performRequest(url: url)
        }

        do {
            return try await currentSearchTask?.value ??
            GitHubSearchResponse(totalCount: 0, incompleteResults: false, items: [])
        } catch {
            // Re-throw if it's not a cancellation error
            if (error as? CocoaError)?.code == CocoaError.Code.userCancelled {
                // Task was cancelled, so we don't need to propagate an error for cancellation
                throw APIError.networkError(error) // Convert to APIError if desired, or handle silently
            } else if let apiError = error as? APIError {
                throw apiError // Re-throw our custom APIError
            } else {
                throw APIError.unknownError // Or a more specific error for unexpected errors
            }
        }
    }

    func fetchImage(from url: URL) async throws -> UIImage {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response): (Data, URLResponse)

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            // If response is not HTTPURLResponse, it's an unexpected network issue.
            // Using a generic error message or converting to networkError is appropriate.
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            // Handle non-2xx HTTP status codes. For images, often just throw a generic HTTP error.
            throw APIError.httpError(httpResponse.statusCode)
        }

        guard let image = UIImage(data: data) else {
            // If data was received but couldn't be converted into a UIImage
            throw APIError.decodingError(NSError(domain: "ImageDecodingError",
                                                 code: 0,
                                                 userInfo: [
                                                    NSLocalizedDescriptionKey:
                                                        "Could not create UIImage from received data."
                                                 ]))
        }

        return image
    }

    func cancelCurrentSearch() {
        currentSearchTask?.cancel()
        currentSearchTask = nil // Clear the task reference
    }
}
