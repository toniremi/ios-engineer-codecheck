//
//  GitHubReadmeResponse.swift
//  iOSEngineerCodeCheck
//
//  Created by Antoni Remeseiro Alfonso on 2025/07/18.
//  Copyright © 2025 YUMEMI Inc. All rights reserved.
//

import Foundation

struct GitHubReadmeResponse: Codable {
    let name, path, sha: String
    let size: Int
    let url, htmlUrl: String
    let gitUrl: String
    let downloadUrl: String
    let type, content, encoding: String
    let links: Links

    enum CodingKeys: String, CodingKey {
        case name, path, sha, size, url
        case htmlUrl
        case gitUrl
        case downloadUrl
        case type, content, encoding
        case links = "_links"
    }
}

// MARK: - Links
struct Links: Codable {
    let linksSelf: String
    let git: String
    let html: String

    enum CodingKeys: String, CodingKey {
        case linksSelf = "self"
        case git, html
    }
}
