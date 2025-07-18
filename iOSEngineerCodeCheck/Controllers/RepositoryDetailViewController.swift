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
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var homePageLabel: UILabel!
    @IBOutlet weak var stargacersLabel: UILabel!
    @IBOutlet weak var watchersLabel: UILabel!
    @IBOutlet weak var forksLabel: UILabel!

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var readmeContainerView: UIView!

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

        // Make the avatar image view circular
        imageView.layer.cornerRadius = imageView.bounds.height / 2
        imageView.clipsToBounds = true // Ensure content is clipped to the rounded corners

        // display repository details
        displayRepositoryDetails(repository: repository)

        // Call getImage to fetch the avatar
        getImage()

        // embed the readme view controller
        embedReadmeViewController()
    }

    func displayRepositoryDetails(repository: Repository) {
        // Populate UI elements directly from the Repository model
        titleLabel.text = repository.name
        descriptionLabel.text = repository.description
        homePageLabel.text = repository.homepage
        stargacersLabel.text = formatCount(repository.stargazersCount)
        watchersLabel.text = formatCount(repository.watchersCount)
        forksLabel.text = formatCount(repository.forksCount)
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

    private func embedReadmeViewController() {
        guard let ownerLogin = selectedRepository?.owner?.login,
              let repoName = selectedRepository?.name,
              let repoHtmlUrl = selectedRepository?.htmlUrl else { // Get the htmlUrl
            print("Cannot embed README: owner, repo name, or HTML URL missing.")
            return
        }

        let readmeVC = ReadmeViewController()
        readmeVC.repositoryOwner = ownerLogin
        readmeVC.repositoryName = repoName
        readmeVC.repositoryUrlString = repoHtmlUrl

        addChild(readmeVC)
        readmeContainerView.addSubview(readmeVC.view)

        readmeVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            readmeVC.view.topAnchor.constraint(equalTo: readmeContainerView.topAnchor),
            readmeVC.view.leadingAnchor.constraint(equalTo: readmeContainerView.leadingAnchor),
            readmeVC.view.trailingAnchor.constraint(equalTo: readmeContainerView.trailingAnchor),
            readmeVC.view.bottomAnchor.constraint(equalTo: readmeContainerView.bottomAnchor)
        ])

        readmeVC.didMove(toParent: self)
    }
}
