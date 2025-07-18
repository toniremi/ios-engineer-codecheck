//
//  ReadmeViewController.swift
//  iOSEngineerCodeCheck
//
//  Created by Antoni Remeseiro Alfonso on 2025/07/18.
//  Copyright © 2025 YUMEMI Inc. All rights reserved.
//

import UIKit
import WebKit
import Down

class ReadmeViewController: UIViewController {

    var repositoryOwner: String?
    var repositoryName: String?
    var repositoryUrlString: String?

    internal let webView = WKWebView() // Make internal for testing or specific access if needed
    private let apiService: GitHubAPIServiceProtocol = GitHubAPIService()

    private var webViewHeightConstraint: NSLayoutConstraint! // Add a property for the height constraint

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // No title needed here as it's embedded

        setupWebView()
        setupActivityIndicator()
        loadReadmeContent()
    }

    private func setupWebView() {
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView) // Add webView to ReadmeVC's root view

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Initialize the height constraint for the webView, which will be updated later
        // Use a low priority or a minimum height to start, and activate/deactivate as needed
        webViewHeightConstraint = webView.heightAnchor.constraint(equalToConstant: 1.0)
        webViewHeightConstraint.priority = .defaultLow // Set a lower priority if it conflicts with parent layout
        webViewHeightConstraint.isActive = true
    }

    private func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func loadReadmeContent() {
        guard let owner = repositoryOwner, let name = repositoryName else {
            print("Error: Repository owner or name not set for ReadmeVC.")
            return
        }

        activityIndicator.startAnimating()

        Task { @MainActor in
            do {
                apiService.setDebugMode(enabled: true)

                let readmeContent = try await apiService.fetchReadme(owner: owner, repoName: name)

                let down = Down(markdownString: readmeContent)
                let htmlString = try down.toHTML()

                // Load the generated HTML into the WKWebView
                // Use the repository's HTML URL as baseURL for relative paths (e.g., images)
                if let repoHtmlUrlString = repositoryUrlString, let baseURL = URL(string: repoHtmlUrlString) {
                     webView.loadHTMLString(htmlString, baseURL: baseURL)
                } else {
                     webView.loadHTMLString(htmlString, baseURL: nil)
                }

            } catch {
                print("Error loading or rendering README: \(error.localizedDescription)")
                // Optionally show an alert or error state within the ReadmeVC itself
            }
            // activityIndicator.stopAnimating() // Will stop in didFinishNavigation
        }
    }
}

// MARK: - WKNavigationDelegate
extension ReadmeViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()

        // After the page finishes loading, execute JavaScript to get the content height
        webView.evaluateJavaScript("document.body.scrollHeight") { [weak self] (result, error) in
            guard let self = self else { return }
            if let height = result as? CGFloat {
                // Update the webView's height constraint.
                // This will cause the ReadmeViewController's view to resize,
                // which the parent's UIScrollView/UIStackView will then layout.
                self.webViewHeightConstraint.constant = height
                self.view.layoutIfNeeded() // Request layout update for the child view

                // If the parent UIScrollView's contentSize isn't automatically adjusting,
                // you might need to notify the parent to update its layout or contentSize.
                // This often happens automatically if you're using UIStackView and
                // the child view's frame/intrinsicContentSize changes.
                print("WebView content height: \(height)")
            } else if let error = error {
                print("Error getting WKWebView content height: \(error.localizedDescription)")
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        print("WKWebView navigation failed: \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        print("WKWebView provisional navigation failed: \(error.localizedDescription)")
    }

    // Handle external links: Open them in Safari instead of within the embedded WKWebView
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                decisionHandler(.cancel) // Cancel navigation in current webView
                return
            }
        }
        decisionHandler(.allow) // Allow other navigation
    }
}
