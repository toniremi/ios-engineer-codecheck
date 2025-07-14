//
//  ViewController.swift
//  iOSEngineerCodeCheck
//
//  Created by 史 翔新 on 2020/04/20.
//  Copyright © 2020 YUMEMI Inc. All rights reserved.
//

import UIKit

class ViewController: UITableViewController, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    var repo: [[String: Any]]=[]
    
    var task: URLSessionTask?
    var word: String!
    var url: String!
    var idx: Int!
    
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
        task?.cancel()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // Safely unwrap searchBar.text. If nil or empty, don't proceed with search.
        // Also, use 'isEmpty' for checking empty strings, which is more Swift-idiomatic than 'count != 0'.
        guard let word = searchBar.text, !word.isEmpty else {
            // Optionally, show an alert to the user that the search term is empty
            print("Search bar text is empty or nil. Not performing search.")
            return
        }

        // Assign 'word' to self.word (if self.word is still a stored property)
        self.word = word // This line only needed if 'self.word' is still used elsewhere as a stored property.

        // Construct the URL string.
        // No force unwrap needed for 'word' here as it's already unwrapped by the guard statement.
        let urlString = "https://api.github.com/search/repositories?q=\(word)"

        // Safely create URL object.
        guard let url = URL(string: urlString) else {
            print("Error: Invalid URL string: \(urlString)")
            return
        }

        // Cancel any ongoing task before starting a new one
        task?.cancel()

        task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            // Handle network errors first
            if let error = error {
                print("Network Error: \(error.localizedDescription)")
                // Potentially update UI on main thread to show error
                return
            }

            // Safely unwrap data
            guard let data = data else {
                print("Error: No data received from API.")
                return
            }

            // Safely parse JSON. Using 'do-catch' for more robust error handling
            do {
                if let obj = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let items = obj["items"] as? [[String: Any]] {
                        self?.repo = items
                        DispatchQueue.main.async {
                            self?.tableView.reloadData()
                        }
                    } else {
                        print("Error: 'items' key not found or not in expected format in JSON.")
                    }
                } else {
                    print("Error: JSON object is not a dictionary.")
                }
            } catch {
                print("JSON Parsing Error: \(error.localizedDescription)")
            }
        }
        task?.resume()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "Detail"{
            if let detailsViewController = segue.destination as? ViewController2 {
                detailsViewController.vc1 = self
            }
        }
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repo.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell()
        let rp = repo[indexPath.row]
        cell.textLabel?.text = rp["full_name"] as? String ?? ""
        cell.detailTextLabel?.text = rp["language"] as? String ?? ""
        cell.tag = indexPath.row
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 画面遷移時に呼ばれる
        idx = indexPath.row
        performSegue(withIdentifier: "Detail", sender: self)
        
    }
    
}
