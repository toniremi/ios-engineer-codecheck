//
//  ViewController2.swift
//  iOSEngineerCodeCheck
//
//  Created by 史 翔新 on 2020/04/21.
//  Copyright © 2020 YUMEMI Inc. All rights reserved.
//

import UIKit

class RepositoryDetailViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var languageLabel: UILabel!

    @IBOutlet weak var stargacersLabel: UILabel!
    @IBOutlet weak var watchersLabel: UILabel!
    @IBOutlet weak var forksLabel: UILabel!
    @IBOutlet weak var issuesLabel: UILabel!

    // instead of holding the whole vc1 reference only the data needed
    var selectedRepository: Repository? // Holds the dictionary for the selected repo

    // Make apiService a lazy var. If it's set by injection in prepare(for:),
    // that value will be used. Otherwise, a new instance is created on first access.
    lazy var apiService: GitHubAPIServiceProtocol = GitHubAPIService()

    override func viewDidLoad() {
        super.viewDidLoad()

        // use guard let to safely unwrap the selected repository data
        guard let repository = selectedRepository else {
            print("Error: selectedRepository was not set.")
            return
        }

        // Populate UI elements directly from the Repository model
        titleLabel.text = repository.fullName
        languageLabel.text = "Written in \(repository.language ?? "N/A")"
        stargacersLabel.text = "\(repository.stargazersCount) stars"
        watchersLabel.text = "\(repository.watchersCount) watchers"
        forksLabel.text = "\(repository.forksCount) forks"
        issuesLabel.text = "\(repository.openIssuesCount) open issues"

        // Call getImage to fetch the avatar
        getImage()
    }

    func getImage() {
        guard let repository = selectedRepository else { return }

        // Use the owner's avatarURL from the Repository model
        guard let ownerAvatarURLString = repository.owner?.avatarUrl,
        let ownerAvatarURL = URL(string: ownerAvatarURLString) else {
            print("Error: Could not create URL from avatar_url string")
            imageView.image = UIImage(systemName: "photo") // Set a placeholder image
            return
        }

        // Use @MainActor to ensure UI updates are on the main thread
        Task { @MainActor in
            do {
                let image = try await apiService.fetchImage(from: ownerAvatarURL)
                self.imageView.image = image
            } catch let apiError as APIError {
                print("API Error fetching image: \(apiError.localizedDescription)")
                self.imageView.image = UIImage(systemName: "exclamationmark.triangle.fill") // Error placeholder
                // Optionally, show an alert specific to image loading
            } catch {
                print("An unexpected error occurred while fetching image: \(error.localizedDescription)")
                self.imageView.image = UIImage(systemName: "exclamationmark.triangle.fill") // Error placeholder
            }
        }
    }
}
