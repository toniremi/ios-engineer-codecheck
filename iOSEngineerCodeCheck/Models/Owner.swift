//
//  Owner.swift
//  iOSEngineerCodeCheck
//
//  Created by Antoni Remeseiro Alfonso on 2025/07/15.
//  Copyright © 2025 YUMEMI Inc. All rights reserved.
//

import Foundation

// Represents the owner (a simple user) of a GitHub repository
struct Owner: Codable {
    let login: String
    let id: Int
    let nodeId: String
    let avatarUrl: String
    let htmlUrl: String
    let type: String
}
