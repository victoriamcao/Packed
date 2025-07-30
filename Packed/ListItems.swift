//
//  ListItems.swift
//  Packed
//
//  Created by Scholar on 7/30/25.
//

import Foundation

class ListItems {
    static func generatePackingList(
            type: String,
            gender: String,
            weather: String,
            length: Int
        ) -> [String] {
            var items = [String]()

            // Essentials
            items.append(contentsOf: [
                "Toothbrush",
                "Toothpaste",
                "Phone charger",
                "Socks",
                "Undergarments",
                "Passport/ID",
                "Wallet"
            ])

            // Clothing (simplified)
            if weather == "Sunny" {
                items.append(contentsOf: ["Sunglasses", "Sunscreen", "Hat"])
            } else if weather == "Rainy" {
                items.append(contentsOf: ["Raincoat", "Umbrella", "Waterproof shoes"])
            } else if weather == "Cold" || type == "Ski Trip" {
                items.append(contentsOf: ["Jacket", "Gloves", "Thermals", "Beanie"])
            }

            if type == "Business Trip" {
                items.append(contentsOf: ["Blazer", "Business Shoes", "Notebook"])
            } else if type == "Mountain Vacation" {
                items.append(contentsOf: ["Hiking boots", "Backpack", "Bug spray"])
            }

            if gender == "Female" {
                items.append("Makeup bag")
            } else if gender == "Male" {
                items.append("Shaving kit")
            }

            // Adjust for length
            let outfitCount = length < 8 ? length : 8
            items.append("\(outfitCount) casual outfits")

            return items
        }
}
