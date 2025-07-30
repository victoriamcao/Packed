//
//  ListItems.swift
//  Packed
//
//  Created by Scholar on 7/30/25.
//

import Foundation

struct PackingItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var isPacked: Bool = false
    var category: String
}

class ListItems {
    static func generatePackingList(
        type: String,
        gender: String,
        weather: String,
        length: Int
    ) -> [PackingItem] {
        var items: [PackingItem] = []

        func add(_ name: String, category: String) {
            items.append(PackingItem(name: name, category: category))
        }

        // Essentials
        ["Passport/ID", "Toothbrush", "Toothpaste", "Electronic device chargers", "Skincare essentials",
         "Shampoo, conditioner, and body wash", "Deodorant", "Water bottle", "Underwear and socks",
         "Accessories", "Pajamas", "Dirty laundry bag", "Electronic devices"].forEach {
            add($0, category: "Essentials")
        }

        // Gender-based Essentials
        if gender == "Female" {
            ["Makeup bag", "Female hygiene products", "Jewelry", "Heat-based hair styling tools", "Purse"].forEach {
                add($0, category: "Toiletries & Personal Items")
            }
        } else if gender == "Male" {
            ["Shaving kit", "Hair gel", "Wallet"].forEach {
                add($0, category: "Toiletries & Personal Items")
            }
        }

        // Weather-based Clothing
        if weather == "Sunny" {
            ["Sunglasses", "Sunscreen", "Hat"].forEach {
                add($0, category: "Clothing")
            }
        } else if weather == "Rainy" {
            ["Raincoat", "Umbrella", "Waterproof shoes"].forEach {
                add($0, category: "Clothing")
            }
        } else if weather == "Cloudy" || weather == "Cold" {
            ["Jacket", "Gloves", "Thermals", "Beanie"].forEach {
                add($0, category: "Clothing")
            }
        }

        // Trip-specific Gear
        switch type {
        case "Business Trip":
            ["Business casual attire", "Blazer and suit", "Dress shoes / Loafers", "Laptop bag", "Dress shirt"].forEach {
                add($0, category: "Workwear")
            }
            if gender == "Female" {
                ["Flats / Heels", "Pencil skirt"].forEach { add($0, category: "Workwear") }
            }
        case "Mountain Vacation":
            ["Hiking boots", "Fleece or thermal jacket", "Windbreaker / Rain jacket", "Beanie", "Gloves", "Backpack", "Bug spray"].forEach {
                add($0, category: "Hiking Gear")
            }
            if gender == "Female" { add("Leggings", category: "Hiking Gear") }
        case "Tropical Vacation":
            ["Swimsuits", "Flip-flops / Sandals", "Shorts", "Tank tops"].forEach {
                add($0, category: "Beachwear")
            }
            if gender == "Female" {
                ["Cover-ups", "Sundresses"].forEach { add($0, category: "Beachwear") }
            }
        case "City Vacation":
            ["Jeans", "Sneakers", "Formal dinner attire", "Scarf"].forEach {
                add($0, category: "Citywear")
            }
            if gender == "Female" {
                add("Blouses", category: "Citywear")
            } else if gender == "Male" {
                add("Polos", category: "Citywear")
            }
        case "Ski Trip":
            ["Ski jacket", "Ski pants", "Thermal base layers", "Ski gloves", "Neck warmer", "Beanie", "Ski goggles",
             "Snow boots", "Helmet", "Sweaters", "Jeans", "Warm coat", "Indoor shoes", "Scarf", "Hand/Foot warmers"].forEach {
                add($0, category: "Ski Gear")
            }
        default: break
        }

        // Outfit count
        let outfitCount = min(length, 8)
        add("\(outfitCount) casual outfits", category: "Clothing")

        return items
    }
}
