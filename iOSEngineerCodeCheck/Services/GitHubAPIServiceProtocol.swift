//
//  GitHubAPIServiceProtocol.swift
//  iOSEngineerCodeCheck
//
//  Created by Antoni Remeseiro Alfonso on 2025/07/15.
//  Copyright © 2025 YUMEMI Inc. All rights reserved.
//

import Foundation
import UIKit

protocol GitHubAPIServiceProtocol {
    func searchRepositories(query: String) async throws -> GitHubSearchResponse
    func fetchImage(from url: URL) async throws -> UIImage
    func cancelCurrentSearch()
}
