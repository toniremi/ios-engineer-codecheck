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
    @IBOutlet weak var homePageIcon: UIImageView!
    @IBOutlet weak var homePageLabel: UILabel!
    @IBOutlet weak var stargacersLabel: UILabel!
    @IBOutlet weak var watchersLabel: UILabel!
    @IBOutlet weak var forksLabel: UILabel!
    @IBOutlet weak var defaultBranchLabel: UILabel!
    @IBOutlet weak var languageColorView: UIView!
    @IBOutlet weak var languageLabel: UILabel!

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
        // make also the language view circular
        languageColorView.layer.cornerRadius = languageColorView.bounds.height / 2
        languageColorView.clipsToBounds = true

        // display repository details
        displayRepositoryDetails(repository: repository)

        // Call getImage to fetch the avatar
        getImage()

        // embed the readme view controller
        embedReadmeViewController()
    }

    func displayRepositoryDetails(repository: Repository) {
        // set the view controller title
        self.title = repository.name
        // Populate UI elements directly from the Repository model
        titleLabel.text = repository.owner?.login ?? repository.name
        descriptionLabel.text = repository.description

        if let homePageLink = repository.homepage, !homePageLink.isEmpty {
            // user our setAsLink extension
            homePageLabel.setAsLink(linkText: homePageLink,
                                                urlString: homePageLink,
                                                target: self,
                                                action: #selector(homePageLabelTapped))
            // make sure the home page link and icon are visible
            homePageIcon.isHidden = false
            homePageLabel.isHidden = false
        } else {
            homePageIcon.isHidden = true
            homePageLabel.isHidden = true
        }

        // add the rest of ui elements
        stargacersLabel.text = formatCount(repository.stargazersCount)
        watchersLabel.text = formatCount(repository.watchersCount)
        forksLabel.text = formatCount(repository.forksCount)
        defaultBranchLabel.text = repository.defaultBranch

        // language might be optional
        if let language = repository.language, !language.isEmpty {
            languageLabel.text = language
            languageColorView.backgroundColor = LanguageColorProvider.shared.color(for: language)
            languageLabel.isHidden = false
            languageColorView.isHidden = false
        } else {
            languageLabel.text = nil
            languageColorView.backgroundColor = .clear
            languageLabel.isHidden = true
            languageColorView.isHidden = true
        }
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

    // Move the tap gesture handler here
    @objc func homePageLabelTapped() {
        guard let repository = selectedRepository,
              let homePageLink = repository.homepage,
              let url = URL(string: homePageLink) else {
            print("Error: No valid homepage URL found to open.")
            return
        }

        // open the url
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            print("Error: Cannot open URL: \(url.absoluteString)")
        }
    }
}
