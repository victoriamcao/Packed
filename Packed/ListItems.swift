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
                "Passport/ID",
                "Toothbrush",
                "Toothpaste",
                "Electronic device chargers",
                "Skincare essentials",
                "Shampoo, conditioner, and body wash",
                "Deodorant",
                "Water bottle",
                "Underwear and socks",
                "Accessories",
                "Pajamas",
                "Dirty laundry bag",
                "Electronic devices"
            ])
            
            // Essentials by gender
            if gender == "Female" {
                items.append(contentsOf: [
                    "Makeup bag",
                    "Female hygiene products",
                    "Jewelry",
                    "Heat-based hair styling tools",
                    "Purse"
                ])
            } else if gender == "Male" {
                items.append(contentsOf: [
                    "Shaving kit",
                    "Hair gel",
                    "Wallet"
                ])
            } else {
                items.append(contentsOf: [
                    "Accessories",
                    "Hair products"
                ])
            }

            

            // Clothing (simplified)
            if weather == "Sunny" {
                items.append(contentsOf: ["Sunglasses", "Sunscreen", "Hat"])
            } else if weather == "Rainy" {
                items.append(contentsOf: ["Raincoat", "Umbrella", "Waterproof shoes"])
            } else if weather == "Cloudy" {
                items.append(contentsOf: ["Jacket", "Gloves", "Thermals", "Beanie"])
            }

            if type == "Business Trip" {
                items.append(contentsOf: [
                    "Business casual attire",
                    "Blazer and suit",
                    "Dress shoes / Loafers",
                    "Laptop bag",
                    "Dress shirt"
                ])
                if gender == "Female" {
                    items.append(contentsOf: [
                        "Flats / Heels",
                        "Pencil skirt"
                    ])
                }
            } else if type == "Mountain Vacation" {
                items.append(contentsOf: [
                    "Hiking boots",
                    "Fleece or thermal jacket",
                    "Windbreaker / Rain jacket",
                    "Beanie",
                    "Gloves",
                    "Backpack",
                    "Bug spray"
                ])
                if gender == "Female" {
                    items.append("Leggings")
                }
            } else if type == "Tropical Vacation" {
                items.append(contentsOf: [
                    "Swimsuits",
                    "Flip-flops / Sandals",
                    "Shorts",
                    "Tank tops"
                ])
                if gender == "Female" {
                    items.append(contentsOf: [
                        "Cover-ups",
                        "Sundresses"
                    ])
                }
            } else if type == "City Vacation" {
                items.append(contentsOf: [
                    "Jeans",
                    "Sneakers",
                    "Formal dinner attire",
                    "Scarf"
                ])
                if gender == "Female" {
                    items.append("Blouses")
                } else if gender == "Male" {
                    items.append("Polos")
                }
            } else if type == "Ski Trip" {
                items.append(contentsOf: [
                    "Ski jacket",
                    "Ski pants",
                    "Thermal base layers",
                    "Ski gloves",
                    "Neck warmer",
                    "Beanie",
                    "Ski goggles",
                    "Snow boots",
                    "Helmet",
                    "Sweaters",
                    "Jeans",
                    "Warm coat",
                    "Indoor shoes",
                    "Scarf",
                    "Hand/Foot warmers",
                ])
            }

            // Adjust for length
            let outfitCount = length < 8 ? length : 8
            items.append("\(outfitCount) casual outfits")

            return items
        }
}
