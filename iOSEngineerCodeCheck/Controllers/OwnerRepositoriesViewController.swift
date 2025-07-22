//
//  OwnerRepositoriesViewController.swift
//  iOSEngineerCodeCheck
//
//  Created by Antoni Remeseiro Alfonso on 2025/07/22.
//  Copyright © 2025 YUMEMI Inc. All rights reserved.
//

import UIKit

class OwnerRepositoriesViewController: UITableViewController {

    // the owner selected to list all of its repositories
    var owner: String?

    // our list of repositories
    var repositories: [Repository] = []

    // selected repository so we can load details
    var selectedRepositoryIndex: Int?

    // Make apiService a lazy var. If it's set by injection in prepare(for:),
    // that value will be used. Otherwise, a new instance is created on first access.
    lazy var apiService: GitHubAPIServiceProtocol = GitHubAPIService()

    // activity indicator
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large) // Use .medium or .large
        indicator.hidesWhenStopped = true // Automatically hides when stopAnimating() is called
        indicator.color = .systemGray // Set a color that contrasts with your background
        return indicator
    }()

    // UI Elements for No Results
    private lazy var noResultsLabel: UILabel = {
        let label = UILabel()
        label.text = "検索結果が見つかりませんでした" // Japanese for "No search results found"
        label.textColor = .systemGray // A subtle gray color
        label.textAlignment = .center
        label.font = UIFont.preferredFont(forTextStyle: .headline) // A slightly larger, bolder font
        label.numberOfLines = 0 // Allow the text to wrap if it's too long
        return label
    }()

    // State variable to track loading
    private var isLoading: Bool = false {
        didSet {
            // Automatically update the table view's background whenever isLoading changes
            updateTableViewBackgroundView()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        // use guard let to safely unwrap the selected repository data
        guard let ownerLogin = owner else {
            print("Error: owner was not set.")
            return
        }

        // set the title to be the ownerLogin
        self.title = ownerLogin

        // register our new custom cell
        tableView.register(UINib(nibName: "RepositoryTableViewCell", bundle: nil), forCellReuseIdentifier: "Repository")

        // Configure table view for automatic cell height based on Auto Layout constraints.
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 156

        // dismiss keboard
        tableView.keyboardDismissMode = .onDrag

        // Initial state setup: Ensure background is set correctly
        updateTableViewBackgroundView()

        // fetch the repositories for this owner
        fetchOwnerRepositories(owner: ownerLogin)
    }

    private func updateTableViewBackgroundView() {
        if isLoading {
            // If loading, show the activity indicator
            tableView.backgroundView = activityIndicator
            activityIndicator.startAnimating()
            noResultsLabel.isHidden = true // Ensure label is hidden if it was visible
        } else if repositories.isEmpty {
            // If not loading and no repositories, show the "no results" label
            tableView.backgroundView = noResultsLabel
            activityIndicator.stopAnimating()
            noResultsLabel.isHidden = false // Ensure label is visible
        } else {
            // If there are repositories, hide both (default table view content shows)
            tableView.backgroundView = nil
            activityIndicator.stopAnimating()
            noResultsLabel.isHidden = true // Ensure label is hidden
        }
    }

    func fetchOwnerRepositories(owner: String) {
        // Clear existing results immediately before starting a new fetch
        self.repositories = []
        self.tableView.reloadData() // Refresh table to show cleared state / spinner
        self.isLoading = true // Start loading state, which will show the activity indicator

        // Use @MainActor to ensure UI updates are on the main thread
        Task { @MainActor in
            // Ensure isLoading is set to false when the Task finishes (whether successful or not)
            defer { self.isLoading = false }

            do {
                self.repositories = try await apiService.fetchRepositories(forOwner: owner)
                self.tableView.reloadData()
            } catch let apiError as APIError {
                // Handle your custom APIError
                print("API Error: \(apiError.localizedDescription)")
                self.showAlert(title: "Search Error", message: apiError.localizedDescription)
                self.repositories = [] // Clear results on error
                self.tableView.reloadData() // Reload to reflect empty state
            } catch {
                // Handle task cancellation specifically (important for `textDidChange` cancellation)
                if let error = error as? URLError, error.code == .cancelled {
                    print("Search task was cancelled.")
                    return // Do not show an error to the user for cancellation
                }
                // Handle any other unexpected errors
                print("An unexpected error occurred: \(error.localizedDescription)")
                self.showAlert(title: "Error", message: "An unexpected error occurred: \(error.localizedDescription)")
                self.repositories = [] // Clear results on unexpected error
                self.tableView.reloadData() // Reload to reflect empty state
            }
        }
    }

    // Helper to show alerts
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Detail" {
            if let detailsViewController = segue.destination as? RepositoryDetailViewController {
                // pass the selected repository
                if let selectedIndex = selectedRepositoryIndex, repositories.indices.contains(selectedIndex) {
                    detailsViewController.selectedRepository = repositories[selectedIndex]
                } else {
                    print("Error: Invalid index or repository data not available for segue.")
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repositories.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // make sure we fetch the RepositoryTableViewCell view cell
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Repository", for: indexPath)
                as? RepositoryTableViewCell else {
            // If the cell cannot be dequeued as RepositoryTableViewCell, something is wrong.
            fatalError("The dequeued cell is not an instance of RepositoryTableViewCell.")
        }

        // Get the corresponding repository object for the current row
        let repository = repositories[indexPath.row]

        // Configure the cell with the repository data and the API service (for image loading).
        cell.configure(with: repository, imageService: apiService)

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedRepositoryIndex = indexPath.row
        performSegue(withIdentifier: "Detail", sender: self)
    }
}
