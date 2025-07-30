//
//  SavedLists.swift
//  Packed
//
//  Created by Scholar on 7/30/25.
//

import Foundation

struct PackingList: Identifiable, Codable, Equatable {
    var id = UUID()
    var vacationName: String
    var items: [String]
}
