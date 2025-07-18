//
//  GitHubAPIErrorResponse.swift
//  iOSEngineerCodeCheck
//
//  Created by Antoni Remeseiro Alfonso on 2025/07/15.
//  Copyright © 2025 YUMEMI Inc. All rights reserved.
//

import Foundation

// found and extrapolated from octoki/typescript types
// on this repo => https://github.com/octokit/types.ts/blob/main/src/RequestError.ts
struct GitHubAPIErrorResponse: Decodable, Equatable {
    let message: String
    let documentationUrl: String? // Optional, as it might not always be present
    let errors: [GitHubAPIErrorDetail]? // Optional array for detailed errors
    let status: String? // optional status code

    // Map snake_case from JSON to camelCase in Swift
    enum CodingKeys: String, CodingKey {
        case message
        case documentationUrl = "documentation_url"
        case errors
        case status
    }
}

// Represents a single detailed error within the 'errors' array
struct GitHubAPIErrorDetail: Decodable, Equatable {
    let resource: String?
    let field: String?
    let code: String?
    let message: String? // Sometimes a specific error message is within the detail

    enum CodingKeys: String, CodingKey {
        case resource
        case field
        case code
        case message
    }
}
