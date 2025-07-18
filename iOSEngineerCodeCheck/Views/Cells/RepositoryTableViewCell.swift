//
//  RepositoryTableViewCell.swift
//  iOSEngineerCodeCheck
//
//  Created by Antoni Remeseiro Alfonso on 2025/07/18.
//  Copyright © 2025 YUMEMI Inc. All rights reserved.
//

import UIKit
import Foundation // For URL and other Foundation types

class RepositoryTableViewCell: UITableViewCell {

    // MARK: - IBOutlets
    // Connect these outlets by dragging from the corresponding UI element in your .xib
    // to this file in Xcode's "Connections Inspector".
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var ownerLabel: UILabel!
    @IBOutlet weak var repositoryTitleLabel: UILabel!
    @IBOutlet weak var repositoryDescriptionLabel: UILabel!
    @IBOutlet weak var stargazersCountLabel: UILabel!
    @IBOutlet weak var languageColorView: UIView! // The colored dot for the language
    @IBOutlet weak var languageLabel: UILabel!

    // A task reference to cancel ongoing image loading if the cell is reused
    private var imageLoadingTask: Task<Void, Never>?

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code that runs once when the cell is loaded from the XIB

        // Make the avatar image view circular
        avatarImageView.layer.cornerRadius = avatarImageView.bounds.height / 2
        avatarImageView.clipsToBounds = true // Ensure content is clipped to the rounded corners

        // Make the language color view circular
        languageColorView.layer.cornerRadius = languageColorView.bounds.height / 2
        languageColorView.clipsToBounds = true // Ensure content is clipped
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // This method is called just before the cell is reused.
        // It's crucial for clearing previous content and cancelling any ongoing tasks
        // to prevent displaying incorrect data or visual glitches.

        // Cancel any active image loading task to prevent setting the wrong image later
        imageLoadingTask?.cancel()
        imageLoadingTask = nil

        // Clear all labels and image view to avoid displaying old data
        avatarImageView.image = nil // Set a nil or placeholder image
        ownerLabel.text = nil
        repositoryTitleLabel.text = nil
        repositoryDescriptionLabel.text = nil
        stargazersCountLabel.text = nil
        languageLabel.text = nil
        languageColorView.backgroundColor = .clear // Reset background color
        languageLabel.isHidden = false // Reset visibility state
        languageColorView.isHidden = false // Reset visibility state
        repositoryDescriptionLabel.isHidden = false // Reset visibility state
    }

    // MARK: - Configuration

    /// Configures the cell with repository data.
    /// - Parameters:
    ///   - repository: The `Repository` object to display.
    ///   - imageService: An optional service conforming to `GitHubAPIServiceProtocol` for fetching images.
    func configure(with repository: Repository, imageService: GitHubAPIServiceProtocol?) {
        // Set owner login (or a default if nil)
        ownerLabel.text = repository.owner?.login ?? "Unknown Owner"

        // Set repository full name
        repositoryTitleLabel.text = repository.name

        // Set repository description, handle optionality and hide label if empty
        if let description = repository.description, !description.isEmpty {
            repositoryDescriptionLabel.text = description
            repositoryDescriptionLabel.isHidden = false
        } else {
            repositoryDescriptionLabel.text = "No description provided." // Or keep it nil
            repositoryDescriptionLabel.isHidden = true // Hide if no description
        }

        // Format and set stargazers count
        stargazersCountLabel.text = formatStargazersCount(repository.stargazersCount)

        // Set language and its corresponding color, or hide if no language
        if let language = repository.language, !language.isEmpty {
            languageLabel.text = language
            languageColorView.backgroundColor = colorForLanguage(language)
            languageLabel.isHidden = false
            languageColorView.isHidden = false
        } else {
            languageLabel.text = nil
            languageColorView.backgroundColor = .clear
            languageLabel.isHidden = true
            languageColorView.isHidden = true
        }

        // Load avatar image asynchronously
        avatarImageView.image = UIImage(systemName: "person.circle.fill") // Set a placeholder immediately

        if let ownerAvatarURLString = repository.owner?.avatarUrl,
            let service = imageService,
            let ownerAvatarURL = URL(string: ownerAvatarURLString) {
            imageLoadingTask = Task { @MainActor in // Use @MainActor for UI updates
                do {
                    let image = try await service.fetchImage(from: ownerAvatarURL)
                    // Check if the task hasn't been cancelled (e.g., cell was reused)
                    if !Task.isCancelled {
                        self.avatarImageView.image = image
                    }
                } catch {
                    print("Failed to load avatar image for \(repository.fullName): \(error.localizedDescription)")
                    // Set an error placeholder image if fetching fails
                    if !Task.isCancelled {
                        self.avatarImageView.image = UIImage(systemName: "exclamationmark.triangle.fill")
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    /// Formats a large number of stargazers into a more readable string (e.g., 123k, 1.2M).
    private func formatStargazersCount(_ count: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal // Use decimal style for thousands separators
        formatter.maximumFractionDigits = 1 // Allow one decimal place for 'k' or 'M'

        if count >= 1_000_000 {
            let millions = Double(count) / 1_000_000
            return (formatter.string(from: NSNumber(value: millions)) ?? "") + "M"
        } else if count >= 1_000 {
            let thousands = Double(count) / 1_000
            return (formatter.string(from: NSNumber(value: thousands)) ?? "") + "k"
        } else {
            return formatter.string(from: NSNumber(value: count)) ?? "\(count)"
        }
    }

    /// Provides a color for a given programming language.
    /// This is a simple example; for a comprehensive solution, consider a dedicated language color manager.
    private func colorForLanguage(_ language: String) -> UIColor {
        // return the color for the language or gray if cannot find it
       return LanguageColorProvider.shared.color(for: language)
    }
}
