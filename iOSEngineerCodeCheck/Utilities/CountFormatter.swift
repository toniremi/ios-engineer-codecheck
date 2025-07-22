//
//  CountFormatter.swift
//  iOSEngineerCodeCheck
//
//  Created by Antoni Remeseiro Alfonso on 2025/07/18.
//  Copyright © 2025 YUMEMI Inc. All rights reserved.
//
import UIKit

func formatCount(_ count: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal // Use decimal style for thousands separators
    formatter.maximumFractionDigits = 1 // Allow one decimal place for 'k' or 'M'

    if count >= 1_000_000 {
        let millions = Double(count) / 1_000_000
        return (formatter.string(from: NSNumber(value: millions)) ?? "") + "M"
    } else if count >= 1_000 {
        let thousands = Double(count) / 1_000
        return (formatter.string(from: NSNumber(value: thousands)) ?? "") + "k"
    } else {
        return formatter.string(from: NSNumber(value: count)) ?? "\(count)"
    }
}
