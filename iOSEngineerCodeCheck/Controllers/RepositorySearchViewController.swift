//
//  ViewController.swift
//  iOSEngineerCodeCheck
//
//  Created by 史 翔新 on 2020/04/20.
//  Copyright © 2020 YUMEMI Inc. All rights reserved.
//

import UIKit

class RepositorySearchViewController: UITableViewController, UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!

    var repositories: [Repository] = []

    var selectedRepositoryIndex: Int?

    // Instantiate your new API service
    private let apiService: GitHubAPIServiceProtocol = GitHubAPIService()

    // MARK: - UI Elements for No Results
    private lazy var noResultsLabel: UILabel = {
        let label = UILabel()
        label.text = "検索結果が見つかりませんでした" // Japanese for "No search results found"
        label.textColor = .systemGray // A subtle gray color
        label.textAlignment = .center
        label.font = UIFont.preferredFont(forTextStyle: .headline) // A slightly larger, bolder font
        label.numberOfLines = 0 // Allow the text to wrap if it's too long
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // user proper placehodler instead of text
        searchBar.placeholder = "GitHubのリポジトリを検索できるよー"
        searchBar.delegate = self

        // register our new custom cell
        tableView.register(UINib(nibName: "RepositoryTableViewCell", bundle: nil), forCellReuseIdentifier: "Repository")

        // Configure table view for automatic cell height based on Auto Layout constraints.
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 156

        // Initial check: show no results message if the list is empty on load
        updateNoResultsMessage()
    }

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        // no need to clear text anymore since we are using placeholder
        return true
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // replace task.cancel with our apiService.cancelCurrentSearch()
        apiService.cancelCurrentSearch()

        // Optionally, clear previous results immediately as user types
        if !searchText.isEmpty {
            self.repositories = [] // Clear existing results
            self.tableView.reloadData() // This will also hide the "no results" label temporarily
            updateNoResultsMessage() // Ensure background is cleared if results are cleared
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // Safely unwrap searchBar.text. If nil or empty, don't proceed with search.
        // Also, use 'isEmpty' for checking empty strings, which is more Swift-idiomatic than 'count != 0'.
        guard let word = searchBar.text, !word.isEmpty else {
            // Optionally, show an alert to the user that the search term is empty
            print("Search bar text is empty or nil. Not performing search.")
            self.repositories = [] // Clear results to show "no results" message if search term is empty
            self.tableView.reloadData()
            updateNoResultsMessage() // Show message if search input is empty
            return
        }

        // Cancel any ongoing search before starting a new one (important for button-triggered search too)
        apiService.cancelCurrentSearch()

        // Use @MainActor to ensure UI updates are on the main thread
        Task { @MainActor in
            do {
                let searchResponse = try await apiService.searchRepositories(query: word)
                self.repositories = searchResponse.items // Assign the array of Repository objects
                self.tableView.reloadData()
                updateNoResultsMessage() // Update after data is loaded and table reloaded
            } catch let apiError as APIError {
                // Handle your custom APIError
                print("API Error: \(apiError.localizedDescription)")
                self.showAlert(title: "Search Error", message: apiError.localizedDescription)
                self.repositories = [] // Clear results on error
                self.tableView.reloadData() // Reload to reflect empty state
                updateNoResultsMessage() // Show message on error
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
                updateNoResultsMessage() // Show message on error
            }
        }
    }

    // No Results Message Logic
    private func updateNoResultsMessage() {
        if repositories.isEmpty {
            // Show the "No results" label
            tableView.backgroundView = noResultsLabel
        } else {
            // Hide the "No results" label (by setting backgroundView to nil)
            tableView.backgroundView = nil
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
        // 画面遷移時に呼ばれる
        selectedRepositoryIndex = indexPath.row
        performSegue(withIdentifier: "Detail", sender: self)

    }

}
