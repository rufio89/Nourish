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
            if let c = try? ModelContainer(for: schema, configurations: config) {
                container = c
            } else {
                // Last resort: use in-memory store so the app doesn't crash
                let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                container = try! ModelContainer(for: schema, configurations: memoryConfig)
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

        #if DEBUG
        if friends.isEmpty {
            // Re-fetch categories in case we just seeded them
            let allCategories = (try? context.fetch(FetchDescriptor<Category>())) ?? []
            seedDevData(context: context, categories: allCategories)
        }
        #endif

        try? context.save()
    }

    #if DEBUG
    @MainActor
    private func seedDevData(context: ModelContext, categories: [Category]) {
        Self.insertDevData(context: context, categories: categories)
    }

    @MainActor
    static func insertDevData(context: ModelContext, categories: [Category]) {
        func daysAgo(_ days: Int) -> Date {
            Date.now.addingTimeInterval(-86400 * Double(days))
        }

        let family = categories.first { $0.name == "Family" }
        let friends = categories.first { $0.name == "Friends" }
        let work = categories.first { $0.name == "Work" }
        let other = categories.first { $0.name == "Other" }

        // 1. Sarah — Thriving, score ~92, contacted today, Family
        let sarah = Friend(name: "Sarah", healthScore: 92, lastContactDate: .now, notes: "Sister — lives nearby")
        sarah.lastDecayDate = .now
        if let bd = Calendar.current.date(from: DateComponents(year: 1995, month: 3, day: 12)) {
            sarah.birthday = bd
        }
        if let family { sarah.categories.append(family) }
        context.insert(sarah)

        let sarahInt1 = Interaction(type: .hangout, note: "Brunch at the new cafe", date: .now, friend: sarah)
        context.insert(sarahInt1)

        // 2. Jake — Thriving, score ~80, contacted 2 days ago, Friends
        let jake = Friend(name: "Jake", healthScore: 80, lastContactDate: daysAgo(2))
        jake.lastDecayDate = .now
        if let friends { jake.categories.append(friends) }
        context.insert(jake)

        let jakeInt1 = Interaction(type: .call, note: "Caught up about weekend plans", date: daysAgo(2), friend: jake)
        context.insert(jakeInt1)

        // 3. Mom — Okay, score ~60, contacted 8 days ago, Family, with upcoming birthday
        let mom = Friend(name: "Mom", healthScore: 60, lastContactDate: daysAgo(8), notes: "Don't forget to call more often")
        mom.lastDecayDate = .now
        // Birthday ~10 days from now
        let upcomingBirthday = Calendar.current.date(byAdding: .day, value: 10, to: .now)
        if let upcoming = upcomingBirthday {
            // Set birth year in the past but month/day upcoming
            var comps = Calendar.current.dateComponents([.month, .day], from: upcoming)
            comps.year = 1965
            mom.birthday = Calendar.current.date(from: comps)
        }
        if let family { mom.categories.append(family) }
        context.insert(mom)

        let momInt1 = Interaction(type: .call, note: "Weekly check-in", date: daysAgo(8), friend: mom)
        let momInt2 = Interaction(type: .text, note: "Sent photos from the trip", date: daysAgo(12), friend: mom)
        context.insert(momInt1)
        context.insert(momInt2)

        // 4. Alex — Fading, score ~35, contacted 20 days ago, Work
        let alex = Friend(name: "Alex", healthScore: 35, lastContactDate: daysAgo(20))
        alex.lastDecayDate = .now
        if let work { alex.categories.append(work) }
        context.insert(alex)

        let alexInt1 = Interaction(type: .text, note: "Talked about the project deadline", date: daysAgo(20), friend: alex)
        context.insert(alexInt1)

        // 5. Priya — Critical, score ~15, contacted 35 days ago, Friends
        let priya = Friend(name: "Priya", healthScore: 15, lastContactDate: daysAgo(35), notes: "Met at the conference last year")
        priya.lastDecayDate = .now
        if let bd = Calendar.current.date(from: DateComponents(year: 1993, month: 8, day: 22)) {
            priya.birthday = bd
        }
        if let friends { priya.categories.append(friends) }
        context.insert(priya)

        let priyaInt1 = Interaction(type: .socialMedia, note: "Liked her vacation photos", date: daysAgo(35), friend: priya)
        context.insert(priyaInt1)

        // 6. Tom — Ghost, score 0, contacted 45 days ago, Other
        let tom = Friend(name: "Tom", healthScore: 0, lastContactDate: daysAgo(45))
        tom.lastDecayDate = .now
        if let other { tom.categories.append(other) }
        context.insert(tom)

        let tomInt1 = Interaction(type: .text, note: "Happy birthday text", date: daysAgo(45), friend: tom)
        context.insert(tomInt1)
    }
    #endif

    @MainActor
    private func seedDefaultCategories(context: ModelContext) {
        for (_, cat) in Category.defaultCategories.enumerated() {
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

}
