//
//  License.swift
//  iOSEngineerCodeCheck
//
//  Created by Antoni Remeseiro Alfonso on 2025/07/15.
//  Copyright © 2025 YUMEMI Inc. All rights reserved.
//

import Foundation

// Represents the license information of a GitHub repository
struct License: Codable {
    let key: String
    let name: String
    let url: String? // URL can be null
    let spdxId: String? // Can be null
    let nodeId: String? // Can be null
}
