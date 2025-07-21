//
//  UILabel+Link.swift
//  iOSEngineerCodeCheck
//
//  Created by Antoni Remeseiro Alfonso on 2025/07/21.
//  Copyright © 2025 YUMEMI Inc. All rights reserved.
//

import UIKit

extension UILabel {

    /// Sets the label's text as a clickable link and attaches a tap gesture recognizer.
    ///
    /// - Parameters:
    ///   - linkText: The text to display, which will also be the link.
    ///   - urlString: The URL string to open when the label is tapped.
    ///   - color: The color of the link text. Defaults to systemBlue.
    ///   - underline: Whether the link text should be underlined. Defaults to true.
    ///   - target: The object that will receive the tap action. Typically the UIViewController.
    ///   - action: The selector for the method to call when the label is tapped.
    func setAsLink(linkText: String,
                   urlString: String,
                   color: UIColor = .systemBlue,
                   underline: Bool = true,
                   target: Any?,
                   action: Selector) {

        guard let url = URL(string: urlString) else {
            // If the URL is invalid, just set the text without link functionality
            self.text = linkText
            self.isUserInteractionEnabled = false
            return
        }

        let attributedString = NSMutableAttributedString(string: linkText)

        // Apply visual link styling (color and underline)
        attributedString.addAttribute(.foregroundColor,
                                      value: color,
                                      range: NSRange(location: 0, length: linkText.count))

        if underline {
            attributedString.addAttribute(.underlineStyle,
                                          value: NSUnderlineStyle.single.rawValue,
                                          range: NSRange(location: 0, length: linkText.count))
        }

        // Add the NSAttributedString.Key.link attribute for semantic correctness,
        // though UILabel itself won't act on it directly without a UITextView.
        attributedString.addAttribute(.link, value: url, range: NSRange(location: 0, length: linkText.count))

        self.attributedText = attributedString
        self.isUserInteractionEnabled = true // Enable user interaction for tap detection

        // Remove any existing gesture recognizers to prevent duplicates
        // This is important if this method is called multiple times on the same label
        self.gestureRecognizers?.forEach { self.removeGestureRecognizer($0) }

        // Add the tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: target, action: action)
        self.addGestureRecognizer(tapGesture)
    }

    /// Clears the link styling and removes the tap gesture.
    func clearLink() {
        self.attributedText = nil
        self.text = nil // Or set to empty string if preferred
        self.isUserInteractionEnabled = false
        self.gestureRecognizers?.forEach { self.removeGestureRecognizer($0) }
    }
}
