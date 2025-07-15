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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        searchBar.text = "GitHubのリポジトリを検索できるよー"
        searchBar.delegate = self
    }

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        // ↓こうすれば初期のテキストを消せる
        searchBar.text = ""
        return true
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // replace task.cancel with our apiService.cancelCurrentSearch()
        apiService.cancelCurrentSearch()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // Safely unwrap searchBar.text. If nil or empty, don't proceed with search.
        // Also, use 'isEmpty' for checking empty strings, which is more Swift-idiomatic than 'count != 0'.
        guard let word = searchBar.text, !word.isEmpty else {
            // Optionally, show an alert to the user that the search term is empty
            print("Search bar text is empty or nil. Not performing search.")
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
            } catch let apiError as APIError {
                // Handle your custom APIError
                print("API Error: \(apiError.localizedDescription)")
                self.showAlert(title: "Search Error", message: apiError.localizedDescription)
            } catch {
                // Handle task cancellation specifically (important for `textDidChange` cancellation)
                if let error = error as? URLError, error.code == .cancelled {
                    print("Search task was cancelled.")
                    return // Do not show an error to the user for cancellation
                }
                // Handle any other unexpected errors
                print("An unexpected error occurred: \(error.localizedDescription)")
                self.showAlert(title: "Error", message: "An unexpected error occurred: \(error.localizedDescription)")
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

        let cell = UITableViewCell()
        let repository = repositories[indexPath.row]
        cell.textLabel?.text = repository.fullName
        cell.detailTextLabel?.text = repository.language ?? ""
        cell.tag = indexPath.row
        return cell

    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 画面遷移時に呼ばれる
        selectedRepositoryIndex = indexPath.row
        performSegue(withIdentifier: "Detail", sender: self)

    }

}
