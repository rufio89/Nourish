//
//  ModelsCategory.swift
//  Nourish
//

import SwiftData
import SwiftUI

@Model
final class Category {
    var name: String
    var icon: String              // SF Symbol name
    var colorHex: String          // Stored as hex for persistence
    var isDefault: Bool           // Predefined vs custom
    var sortOrder: Int            // For tab ordering

    @Relationship(inverse: \Friend.categories)
    var friends: [Friend] = []

    init(
        name: String,
        icon: String = "tag.fill",
        colorHex: String = "808080",
        isDefault: Bool = false,
        sortOrder: Int = 0
    ) {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.isDefault = isDefault
        self.sortOrder = sortOrder
    }

    // MARK: - Computed Properties

    var color: Color {
        Color(hex: colorHex)
    }

    // MARK: - Default Categories

    static let defaultCategories: [(name: String, icon: String, colorHex: String, sortOrder: Int)] = [
        ("Family", "house.fill", "5B9BD5", 0),       // Blue
        ("Friends", "person.2.fill", "70C1B3", 1),   // Teal/Green
        ("Work", "briefcase.fill", "F4A259", 2),     // Orange
        ("Other", "tag.fill", "9B9B9B", 3)           // Gray
    ]
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (128, 128, 128)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
