//
//  LanguageColorProvider.swift
//  iOSEngineerCodeCheck
//
//  Created by Antoni Remeseiro Alfonso on 2025/07/18.
//  Copyright © 2025 YUMEMI Inc. All rights reserved.
//

import Foundation
import UIKit // Changed from SwiftUI to UIKit

// Alias for the dictionary type representing language colors
typealias LanguageColorsData = [String: String]

class LanguageColorProvider {
    // We'll use a singleton pattern so it's initialized only once
    static let shared = LanguageColorProvider()

    private var languageColors: LanguageColorsData?

    // Private initializer to enforce singleton pattern
    private init() {
        loadColors()
    }

    // Loads the githublangs.json file from the app bundle
    private func loadColors() {
        // Find the URL for githublangs.json in the main bundle
        guard let url = Bundle.main.url(forResource: "githublangs", withExtension: "json") else {
            print("Error: githublangs.json not found in app bundle.")
            return
        }

        do {
            let data = try Data(contentsOf: url) // Load data from the URL
            let decoder = JSONDecoder()
            // Decode the JSON data into our LanguageColorsData [String: String]
            languageColors = try decoder.decode(LanguageColorsData.self, from: data)
            print("Successfully loaded language colors from githublangs.json.")
        } catch {
            print("Error decoding language colors JSON: \(error.localizedDescription)")
            languageColors = nil
        }
    }

    // Public method to get a UIKit.UIColor for a given programming language name
    func color(for language: String?) -> UIColor { // Changed return type to UIColor
        guard let language = language else {
            // Return a default color (e.g., gray) if the language is nil
            return .gray
        }

        // Try to find the language directly in the loaded data
        if let hex = languageColors?[language] {
            return UIColor.fromHex(hex) // Use UIColor's fromHex extension
        }

        // Fallback: If direct match fails, try a case-insensitive match.
        // Some languages might have slight casing differences.
        for (key, hex) in languageColors ?? [:] where key.lowercased() == language.lowercased() {
            return UIColor.fromHex(hex) // Use UIColor's fromHex extension
        }

        // Return a default color if the language is not found in the palette
        print("Warning: Color not found for language: \(language). Using default gray.")
        return .gray
    }
}
