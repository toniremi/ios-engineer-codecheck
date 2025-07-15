//
//  Repository.swift
//  iOSEngineerCodeCheck
//
//  Created by Antoni Remeseiro Alfonso on 2025/07/15.
//  Copyright © 2025 YUMEMI Inc. All rights reserved.
//

import Foundation

// Represents a single GitHub repository item
struct Repository: Codable {
    let id: Int
    let nodeId: String
    let name: String
    let fullName: String
    let isPrivate: Bool // 'private' is a Swift keyword, so we change it to isPrivate
    let owner: Owner? // Owner can be null
    let htmlUrl: String
    let description: String? // Description can be null
    let fork: Bool
    let url: String
    let createdAt: Date // Requires JSONDecoder dateDecodingStrategy
    let updatedAt: Date // Requires JSONDecoder dateDecodingStrategy
    let pushedAt: Date  // Requires JSONDecoder dateDecodingStrategy
    let homepage: String? // Homepage can be null
    let size: Int
    let stargazersCount: Int
    let watchersCount: Int
    let language: String? // Language can be null
    let forksCount: Int
    let openIssuesCount: Int
    let defaultBranch: String
    let score: Double
    let license: License? // License can be null

    enum CodingKeys: String, CodingKey {
        case id
        case nodeId
        case name
        case fullName
        case isPrivate = "private"
        case owner
        case htmlUrl
        case description
        case fork
        case url
        case createdAt
        case updatedAt
        case pushedAt
        case homepage
        case size
        case stargazersCount
        case watchersCount
        case language
        case forksCount
        case openIssuesCount
        case defaultBranch
        case score
        case license
    }
}
