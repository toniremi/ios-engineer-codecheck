//
//  GitHubAPIErrorResponse.swift
//  iOSEngineerCodeCheck
//
//  Created by Antoni Remeseiro Alfonso on 2025/07/15.
//  Copyright © 2025 YUMEMI Inc. All rights reserved.
//

import Foundation

struct GitHubAPIErrorResponse: Decodable {
    let message: String
    let documentationUrl: String? // Optional, as it might not always be present

    // Map snake_case from JSON to camelCase in Swift
    enum CodingKeys: String, CodingKey {
        case message
        case documentationUrl = "documentation_url"
    }
}
