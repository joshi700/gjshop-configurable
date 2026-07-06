//
//  Item.swift
//  GJShop_Configurable
//

import Foundation
import SwiftUI

class Item: ObservableObject, Identifiable {
    var id = UUID()
    var name: String
    var imageUrl: String
    var price: Double
    var description: String
    var maxQuantity: Int

    init(id: UUID = UUID(), name: String, imageUrl: String, price: Double, description: String, maxQuantity: Int = 0) {
        self.id = id
        self.name = name
        self.imageUrl = imageUrl
        self.price = price
        self.description = description
        self.maxQuantity = maxQuantity
    }
}
