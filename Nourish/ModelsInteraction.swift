//
//  Interaction.swift
//  Nourish
//

import SwiftData
import Foundation

@Model
final class Interaction {
    var type: InteractionType
    var note: String
    var date: Date

    @Relationship
    var friend: Friend?

    init(type: InteractionType, note: String = "", date: Date = .now, friend: Friend? = nil) {
        self.type = type
        self.note = note
        self.date = date
        self.friend = friend
    }
}
