//
//  NourishApp.swift
//  Nourish
//

import SwiftUI
import SwiftData

@main
struct NourishApp: App {

    let container: ModelContainer

    init() {
        let schema = Schema([Friend.self, Interaction.self, Category.self])
        // Try to open the existing store first
        if let c = try? ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema)) {
            container = c
        } else {
            // Schema changed (e.g. new fields added) — wipe and recreate
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: storeURL)
            do {
                container = try ModelContainer(for: schema, configurations: config)
            } catch {
                fatalError("Failed to create ModelContainer even after reset: \(error)")
            }
        }
    }

    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .task { await applyDecayAndSeedIfNeeded() }
                .preferredColorScheme(appearanceMode.colorScheme)
        }
    }

    // MARK: - Decay + Seed

    @MainActor
    private func applyDecayAndSeedIfNeeded() async {
        let context = container.mainContext
        let friends = (try? context.fetch(FetchDescriptor<Friend>())) ?? []
        let categories = (try? context.fetch(FetchDescriptor<Category>())) ?? []

        for friend in friends {
            friend.applyDecay()
        }

        // Seed default categories if none exist
        if categories.isEmpty {
            seedDefaultCategories(context: context)
        }

        if friends.isEmpty {
            seedSampleData(context: context)
        }

        try? context.save()
    }

    @MainActor
    private func seedDefaultCategories(context: ModelContext) {
        for (index, cat) in Category.defaultCategories.enumerated() {
            let category = Category(
                name: cat.name,
                icon: cat.icon,
                colorHex: cat.colorHex,
                isDefault: true,
                sortOrder: cat.sortOrder
            )
            context.insert(category)
        }
    }

    @MainActor
    private func seedSampleData(context: ModelContext) {
        let calendar = Calendar.current
        let now = Date.now

        let samples: [(name: String, score: Double, daysAgo: Int, note: String)] = [
            ("Alex",   92,  1, "Grabbed coffee, great chat about the hiking trip."),
            ("Jordan", 62,  5, "Quick text exchange last week."),
            ("Sam",    35, 12, "Haven't seen them since the holidays."),
            ("Morgan",  8, 28, "Need to reach out — it's been way too long."),
            ("Ghost Riley", 0, 45, "Lost touch completely... they've become a ghost! 👻")
        ]

        for sample in samples {
            let lastContact = calendar.date(byAdding: .day, value: -sample.daysAgo, to: now) ?? now
            let friend = Friend(
                name: sample.name,
                healthScore: sample.score,
                lastContactDate: lastContact,
                notes: sample.note
            )
            context.insert(friend)
        }
    }
}
