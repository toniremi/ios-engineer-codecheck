//
//  ViewController2.swift
//  iOSEngineerCodeCheck
//
//  Created by 史 翔新 on 2020/04/21.
//  Copyright © 2020 YUMEMI Inc. All rights reserved.
//

import UIKit

class ViewController2: UIViewController {

    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var languageLabel: UILabel!

    @IBOutlet weak var stargacersLabel: UILabel!
    @IBOutlet weak var watchersLabel: UILabel!
    @IBOutlet weak var forksLabel: UILabel!
    @IBOutlet weak var issuesLabel: UILabel!

    // instead of holding the whole vc1 reference only the data needed
    var selectedRepository: [String: Any]? // Holds the dictionary for the selected repo

    override func viewDidLoad() {
        super.viewDidLoad()

        // use guard let to safely unwrap the selected repository data
        guard let repository = selectedRepository else {
            print("Error: selectedRepository was not set.")
            return
        }

        languageLabel.text = "Written in \(repository["language"] as? String ?? "")"
        stargacersLabel.text = "\(repository["stargazers_count"] as? Int ?? 0) stars"
        watchersLabel.text = "\(repository["watchers_count"] as? Int ?? 0) watchers"
        forksLabel.text = "\(repository["forks_count"] as? Int ?? 0) forks"
        issuesLabel.text = "\(repository["open_issues_count"] as? Int ?? 0) open issues"
        getImage()

    }

    func getImage() {

        // use guard let to safely unwrap the selected repository and the data fields needed
        guard let repository = selectedRepository,
              let owner = repository["owner"] as? [String: Any],
              let imgURLString = owner["avatar_url"] as? String,
              let imageURL = URL(string: imgURLString) else {
            print("Error: Could not retrieve image URL from repository data in getImage().")
            return
        }

        // set the repository title
        titleLabel.text = repository["full_name"] as? String ?? ""

        // user URLSession to fetch avatar
        URLSession.shared.dataTask(with: imageURL) { [weak self] (data, _, error) in
            if let error = error {
                print("Network Error fetching image: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("Error: No image data received.")
                return
            }

            guard let img = UIImage(data: data) else {
                print("Error: Could not create UIImage from data.")
                return
            }

            DispatchQueue.main.async {
                self?.imageView.image = img
            }
        }.resume()

    }

}
