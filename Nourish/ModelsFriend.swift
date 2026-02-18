//
//  Friend.swift
//  Nourish
//

import SwiftData
import SwiftUI

// MARK: - Health Status

enum HealthStatus: String, Codable {
    case thriving = "Happy!"
    case okay     = "Content"
    case fading   = "Lonely"
    case critical = "Help!"
    case ghost    = "Ghost"

    var emoji: String {
        switch self {
        case .thriving: "💚"
        case .okay:     "💛"
        case .fading:   "🧡"
        case .critical: "💔"
        case .ghost:    "👻"
        }
    }

    var creatureFace: String {
        switch self {
        case .thriving: "😊"
        case .okay:     "🙂"
        case .fading:   "😕"
        case .critical: "😢"
        case .ghost:    "👻"
        }
    }

    var color: Color {
        switch self {
        case .thriving: Color(red: 0.4, green: 0.85, blue: 0.6)   // Mint green
        case .okay:     Color(red: 1.0, green: 0.85, blue: 0.4)   // Warm yellow
        case .fading:   Color(red: 1.0, green: 0.6, blue: 0.4)    // Peachy orange
        case .critical: Color(red: 1.0, green: 0.45, blue: 0.55)  // Soft red/pink
        case .ghost:    Color(red: 0.7, green: 0.75, blue: 0.85)  // Ghostly blue-gray
        }
    }

    var bgGradient: [Color] {
        switch self {
        case .thriving: [Color(red: 0.85, green: 1.0, blue: 0.9), Color(red: 0.7, green: 0.95, blue: 0.85)]
        case .okay:     [Color(red: 1.0, green: 0.98, blue: 0.85), Color(red: 1.0, green: 0.95, blue: 0.75)]
        case .fading:   [Color(red: 1.0, green: 0.92, blue: 0.88), Color(red: 1.0, green: 0.85, blue: 0.8)]
        case .critical: [Color(red: 1.0, green: 0.9, blue: 0.92), Color(red: 1.0, green: 0.82, blue: 0.85)]
        case .ghost:    [Color(red: 0.9, green: 0.92, blue: 0.95), Color(red: 0.82, green: 0.85, blue: 0.9)]
        }
    }

    var isGhost: Bool { self == .ghost }

    // Sort order: Ghost first, then Critical
    var sortOrder: Int {
        switch self {
        case .ghost:    -1
        case .critical: 0
        case .fading:   1
        case .okay:     2
        case .thriving: 3
        }
    }

    static func status(for score: Double, daysSinceContact: Int = 0) -> HealthStatus {
        // Become a ghost if health is 0 AND no contact for 30+ days
        if score <= 0 && daysSinceContact >= 30 {
            return .ghost
        }
        switch score {
        case 75...100: return .thriving
        case 50..<75:  return .okay
        case 25..<50:  return .fading
        default:       return .critical
        }
    }
}

// MARK: - Interaction Type

enum InteractionType: String, Codable, CaseIterable, Identifiable {
    case hangout      = "Hangout in person"
    case call         = "Phone/video call"
    case text         = "Text conversation"
    case socialMedia  = "Social media like/comment"

    var id: String { rawValue }

    var points: Double {
        switch self {
        case .hangout:     40
        case .call:        30
        case .text:        15
        case .socialMedia:  5
        }
    }

    var icon: String {
        switch self {
        case .hangout:     "person.2.fill"
        case .call:        "phone.fill"
        case .text:        "bubble.left.fill"
        case .socialMedia: "heart.fill"
        }
    }
}

// MARK: - Friend Model

@Model
final class Friend {
    var name: String
    var photoData: Data?
    var healthScore: Double       // 0–100
    var lastContactDate: Date
    var notes: String
    var phoneNumber: String       // e.g. "+15551234567"

    @Relationship(deleteRule: .cascade)
    var interactions: [Interaction] = []

    @Relationship
    var categories: [Category] = []

    init(
        name: String,
        photoData: Data? = nil,
        healthScore: Double = 80,
        lastContactDate: Date = .now,
        notes: String = "",
        phoneNumber: String = ""
    ) {
        self.name = name
        self.photoData = photoData
        self.phoneNumber = phoneNumber
        self.healthScore = healthScore
        self.lastContactDate = lastContactDate
        self.notes = notes
    }

    // MARK: Computed helpers

    var daysSinceContact: Int {
        Calendar.current.dateComponents([.day], from: lastContactDate, to: .now).day ?? 0
    }

    var status: HealthStatus {
        HealthStatus.status(for: healthScore, daysSinceContact: daysSinceContact)
    }

    var isGhost: Bool { status.isGhost }

    var profileImage: Image? {
        guard let data = photoData, let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
    }

    // MARK: Business logic

    /// Call on app launch to decay health based on days since last contact.
    func applyDecay() {
        let daysSinceContact = Calendar.current.numberOfDaysBetween(lastContactDate, and: .now)
        guard daysSinceContact > 0 else { return }
        let decay = Double(daysSinceContact) * 5.0
        healthScore = max(0, healthScore - decay)
    }

    /// Log a new interaction and boost health score.
    func logInteraction(type: InteractionType, note: String = "", date: Date = .now) {
        let interaction = Interaction(type: type, note: note, date: date, friend: self)
        interactions.append(interaction)
        healthScore = min(100, healthScore + type.points)
        lastContactDate = date
    }
}

// MARK: - Calendar helper

private extension Calendar {
    func numberOfDaysBetween(_ from: Date, and to: Date) -> Int {
        let fromDay = startOfDay(for: from)
        let toDay   = startOfDay(for: to)
        return dateComponents([.day], from: fromDay, to: toDay).day ?? 0
    }
}
