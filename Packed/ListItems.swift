//
//  ListItems.swift
//  Packed
//
//  NOTE: If you see an error like "Cannot find type 'PackingItem' in scope",
//  it means the `PackingItem.swift` file is missing from your project
//  or not part of the build target. Please ensure you have that file
//  in your project.
//
//  Created by Scholar on 7/30/25.
//

import Foundation
import SwiftUI

// Struct to represent a single item in the packing list
struct PackingItem: Identifiable, Hashable, Codable {
    let id = UUID()
    var name: String
    var isPacked: Bool = false
    var category: String
}

class ListItems {
    
    // Function to generate a packing list based on user input
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
        
        func addWithQuantity(_ baseName: String, quantity: Int, category: String) {
            let name = quantity > 1 ? "\(quantity) \(baseName)" : baseName
            add(name, category: category)
        }
        
        // Calculate quantity-based items
        let underwearCount = length + 3
        let socksCount = length
        let tShirtCount = max(1, (length + 1) / 2)
        let pantsCount = max(2, length / 3)
        
        // Essentials (fixed quantities)
        ["Passport/ID", "Toothbrush", "Toothpaste", "Electronic device chargers", "Skincare essentials",
         "Shampoo, conditioner, and body wash", "Deodorant", "Water bottle", "Dirty laundry bag", "Electronic devices"].forEach {
            add($0, category: "Essentials")
        }
        
        // Quantity-based essentials
        addWithQuantity("Underwear", quantity: underwearCount, category: "Essentials")
        addWithQuantity("Pairs of socks", quantity: socksCount, category: "Essentials")
        
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
        if type == "Business Trip" {
            let businessShirtsCount = max(2, length / 2)
            let suitsCount = max(1, (length + 2) / 3)
            
            ["Business casual attire", "Dress shoes / Loafers", "Laptop bag"].forEach {
                add($0, category: "Workwear")
            }
            addWithQuantity("Blazer and suit", quantity: suitsCount, category: "Workwear")
            addWithQuantity("Dress shirt", quantity: businessShirtsCount, category: "Workwear")
            
            if gender == "Female" {
                let skirtsCount = max(1, length / 3)
                addWithQuantity("Flats / Heels", quantity: 2, category: "Workwear")
                addWithQuantity("Pencil skirt", quantity: skirtsCount, category: "Workwear")
            }
        } else if type == "Mountain Vacation" {
            let hikingOutfitsCount = max(2, (length + 1) / 2)
            
            ["Hiking boots", "Fleece or thermal jacket", "Windbreaker / Rain jacket",
             "Beanie", "Gloves", "Backpack", "Bug spray"].forEach {
                add($0, category: "Hiking Gear")
            }
            addWithQuantity("Hiking outfits", quantity: hikingOutfitsCount, category: "Hiking Gear")
            
            if gender == "Female" {
                addWithQuantity("Leggings", quantity: max(2, length / 2), category: "Hiking Gear")
            }
        } else if type == "Tropical Vacation" {
            let swimsuitsCount = max(2, (length + 1) / 2)  // About half the days
            let shortsCount = max(2, (length + 1) / 2)
            let tankTopsCount = max(3, (length * 2) / 3)
            
            ["Flip-flops / Sandals"].forEach {
                add($0, category: "Beachwear")
            }
            addWithQuantity("Swimsuits", quantity: swimsuitsCount, category: "Beachwear")
            addWithQuantity("Shorts", quantity: shortsCount, category: "Beachwear")
            addWithQuantity("Tank tops", quantity: tankTopsCount, category: "Beachwear")
            
            if gender == "Female" {
                let coverUpsCount = max(2, swimsuitsCount)
                let sundressesCount = max(2, length / 3)
                addWithQuantity("Cover-ups", quantity: coverUpsCount, category: "Beachwear")
                addWithQuantity("Sundresses", quantity: sundressesCount, category: "Beachwear")
            }
        } else if type == "City Vacation" {
            let jeansCount = max(2, length / 2)
            let formalOutfitsCount = max(1, length / 4)
            
            ["Sneakers", "Scarf"].forEach {
                add($0, category: "Citywear")
            }
            addWithQuantity("Jeans", quantity: jeansCount, category: "Citywear")
            addWithQuantity("Formal dinner attire", quantity: formalOutfitsCount, category: "Citywear")
            
            if gender == "Female" {
                addWithQuantity("Blouses", quantity: max(2, length / 2), category: "Citywear")
            } else if gender == "Male" {
                addWithQuantity("Polos", quantity: max(2, length / 2), category: "Citywear")
            }
        } else if type == "Ski Trip" {
            let thermalLayersCount = max(2, length / 2)
            let sweatersCount = max(2, (length + 1) / 2)
            let jeansCount = max(2, length / 2)
            
            ["Ski jacket", "Ski pants", "Ski gloves", "Neck warmer", "Beanie", "Ski goggles",
             "Snow boots", "Helmet", "Warm coat", "Indoor shoes", "Scarf", "Hand/Foot warmers"].forEach {
                add($0, category: "Ski Gear")
            }
            addWithQuantity("Thermal base layers", quantity: thermalLayersCount, category: "Ski Gear")
            addWithQuantity("Sweaters", quantity: sweatersCount, category: "Ski Gear")
            addWithQuantity("Jeans", quantity: jeansCount, category: "Ski Gear")
        }
        
        // General clothing based on trip length
        addWithQuantity("T-shirts", quantity: tShirtCount, category: "Clothing")
        addWithQuantity("Casual pants", quantity: pantsCount, category: "Clothing")
        
        // Pajamas quantity based on trip length
        let pajamasCount = max(2, (length + 3) / 2)  // About 1 set per 2 days
        addWithQuantity("Pajama sets", quantity: pajamasCount, category: "Clothing")
        
        return items
    }
}
