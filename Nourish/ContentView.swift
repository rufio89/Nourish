//
//  ContentView.swift
//  Nourish
//

import SwiftUI
import SwiftData

// MARK: - Root

struct ContentView: View {
    var body: some View {
        HomeView()
    }
}

// MARK: - Appearance Mode

enum AppearanceMode: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var icon: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        }
    }
}

// MARK: - Home Screen

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Friend.healthScore, order: .forward)
    private var friends: [Friend]

    @Query(sort: \Category.sortOrder)
    private var categories: [Category]

    @State private var showingAddFriend = false
    @State private var showingSettings = false
    @State private var selectedCategory: Category?

    private var ghostFriends: [Friend] {
        friends.filter { $0.isGhost }
    }

    private var filteredFriends: [Friend] {
        guard let selected = selectedCategory else { return friends }
        return friends.filter { $0.categories.contains(where: { $0.id == selected.id }) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Category filter tabs
                    if !categories.isEmpty {
                        categoryTabs
                    }

                    // Friend list or empty state
                    Group {
                        if friends.isEmpty {
                            emptyState
                        } else if filteredFriends.isEmpty {
                            emptyCategoryState
                        } else {
                            friendList
                        }
                    }
                }

                // Ghost peeking overlay
                if !ghostFriends.isEmpty {
                    GhostPeekingOverlay(ghosts: ghostFriends)
                }
            }
            .navigationTitle("Your Garden")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.body)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddFriend = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.mint)
                    }
                }
            }
            .sheet(isPresented: $showingAddFriend) {
                AddEditFriendView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    // MARK: Category Tabs

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryTab(
                    name: "All",
                    icon: "person.2.fill",
                    color: .mint,
                    isSelected: selectedCategory == nil
                ) {
                    withAnimation(.spring(duration: 0.3)) {
                        selectedCategory = nil
                    }
                }

                ForEach(categories) { category in
                    CategoryTab(
                        name: category.name,
                        icon: category.icon,
                        color: category.color,
                        isSelected: selectedCategory?.id == category.id
                    ) {
                        withAnimation(.spring(duration: 0.3)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }

    // MARK: Empty category state

    private var emptyCategoryState: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedCategory?.icon ?? "tag.fill")
                .font(.system(size: 44))
                .foregroundStyle(selectedCategory?.color ?? .gray)

            Text("No friends in \(selectedCategory?.name ?? "this category")")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.secondary)

            Button {
                selectedCategory = nil
            } label: {
                Text("Show All")
                    .font(.system(.subheadline, design: .rounded))
            }
            .buttonStyle(.bordered)
            .tint(.mint)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Friend list

    private var friendList: some View {
        List {
            ForEach(filteredFriends) { friend in
                NavigationLink(destination: FriendDetailView(friend: friend)) {
                    FriendRowView(friend: friend)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .onDelete(perform: deleteFriends)
        }
        .listStyle(.insetGrouped)
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.mint.opacity(0.3), Color.green.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                VStack(spacing: 4) {
                    Text("🌱")
                        .font(.system(size: 44))
                }
            }
            .padding(.bottom, 8)

            Text("Your garden is empty!")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)

            Text("Add friends to start nurturing\nyour relationships")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingAddFriend = true
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Plant a Friendship")
                    Image(systemName: "sparkles")
                }
                .font(.system(.headline, design: .rounded))
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.mint)
            .padding(.top, 8)
        }
    }

    private func deleteFriends(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(friends[index])
        }
    }
}

// MARK: - Friend Row

struct FriendRowView: View {
    let friend: Friend

    private var daysSince: Int {
        Calendar.current.dateComponents([.day], from: friend.lastContactDate, to: .now).day ?? 0
    }

    var body: some View {
        HStack(spacing: 14) {
            CreatureAvatarView(friend: friend, size: 56)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(friend.name)
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.semibold)
                    Spacer()
                    StatusBadge(status: friend.status)
                }

                HealthBarView(score: friend.healthScore, showHearts: true)
                    .frame(height: 14)

                Text(daysSince == 0 ? "You connected today!" : daysSince == 1 ? "1 day ago" : "\(daysSince) days ago")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: HealthStatus

    var body: some View {
        Text("\(status.emoji) \(status.rawValue)")
            .font(.system(.caption, design: .rounded))
            .fontWeight(.semibold)
            .foregroundStyle(status.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(status.color.opacity(0.15))
            )
    }
}

// MARK: - Category Tab

struct CategoryTab: View {
    let name: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(name)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color : Color(.secondarySystemFill))
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Ghost Peeking Overlay

struct GhostPeekingOverlay: View {
    let ghosts: [Friend]

    @State private var peekingGhost: Friend?
    @State private var peekPosition: PeekPosition = .right
    @State private var isVisible = false
    @State private var verticalOffset: CGFloat = 0.2

    enum PeekPosition {
        case left, right, top

        var alignment: Alignment {
            switch self {
            case .left: .leading
            case .right: .trailing
            case .top: .top
            }
        }
    }

    var body: some View {
        GeometryReader { geo in
            if let ghost = peekingGhost {
                ghostView(for: ghost, in: geo)
                    .opacity(isVisible ? 1 : 0)
                    .animation(.easeInOut(duration: 0.8), value: isVisible)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            startPeekingCycle()
        }
    }

    @ViewBuilder
    private func ghostView(for friend: Friend, in geo: GeometryProxy) -> some View {
        let size: CGFloat = 70

        ZStack {
            // Ghostly glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.6), .clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 50
                    )
                )
                .frame(width: size * 1.5, height: size * 1.5)
                .blur(radius: 10)

            VStack(spacing: 4) {
                Text("👻")
                    .font(.system(size: 32))

                Text(friend.name)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.9)
            )
        }
        .frame(width: size, height: size)
        .position(peekPositionPoint(in: geo, size: size))
    }

    private func peekPositionPoint(in geo: GeometryProxy, size: CGFloat) -> CGPoint {
        let yPos = geo.size.height * verticalOffset

        switch peekPosition {
        case .left:
            return CGPoint(x: isVisible ? size / 2 + 10 : -size, y: yPos)
        case .right:
            return CGPoint(x: isVisible ? geo.size.width - size / 2 - 10 : geo.size.width + size, y: yPos)
        case .top:
            return CGPoint(x: geo.size.width * 0.7, y: isVisible ? size / 2 + 60 : -size)
        }
    }

    private func startPeekingCycle() {
        guard !ghosts.isEmpty else { return }

        // Schedule random peeks
        schedulePeek()
    }

    private func schedulePeek() {
        // Random delay between peeks (5-15 seconds)
        let delay = Double.random(in: 5...15)

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard !ghosts.isEmpty else { return }

            // Pick a random ghost and position
            peekingGhost = ghosts.randomElement()
            peekPosition = [PeekPosition.left, .right, .top].randomElement() ?? .right
            verticalOffset = CGFloat.random(in: 0.2...0.6)

            // Show ghost
            withAnimation(.spring(duration: 0.8)) {
                isVisible = true
            }

            // Hide after a few seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 0.6)) {
                    isVisible = false
                }

                // Schedule next peek
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    schedulePeek()
                }
            }
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @State private var showingGhostCreated = false
    @State private var showingAddCategory = false
    @State private var editingCategory: Category?

    @Query(sort: \Category.sortOrder)
    private var categories: [Category]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Appearance", selection: $appearanceMode) {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            Label(mode.rawValue, systemImage: mode.icon)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.navigationLink)
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("Choose how Nourish looks on your device")
                }

                Section {
                    ForEach(categories) { category in
                        Button {
                            editingCategory = category
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: category.icon)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 28, height: 28)
                                    .background(category.color, in: Circle())

                                Text(category.name)
                                    .foregroundStyle(.primary)

                                Spacer()

                                if category.isDefault {
                                    Text("Default")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteCategories)

                    Button {
                        showingAddCategory = true
                    } label: {
                        Label("Add Category", systemImage: "plus.circle.fill")
                            .foregroundStyle(.mint)
                    }
                } header: {
                    Text("Categories")
                } footer: {
                    Text("Organize your friends into categories")
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button {
                        createTestGhost()
                    } label: {
                        Label("Create Test Ghost", systemImage: "ghost")
                    }
                } header: {
                    Text("Developer")
                } footer: {
                    Text("Creates a ghost friend to test the haunting feature")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Ghost Created! 👻", isPresented: $showingGhostCreated) {
                Button("OK") { dismiss() }
            } message: {
                Text("A test ghost has been added to your garden. Watch for them peeking around!")
            }
            .sheet(isPresented: $showingAddCategory) {
                AddEditCategoryView()
            }
            .sheet(item: $editingCategory) { category in
                AddEditCategoryView(category: category)
            }
        }
    }

    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            let category = categories[index]
            if !category.isDefault {
                modelContext.delete(category)
            }
        }
        try? modelContext.save()
    }

    private func createTestGhost() {
        let ghostDate = Calendar.current.date(byAdding: .day, value: -45, to: .now) ?? .now
        let ghost = Friend(
            name: "Ghost Riley",
            healthScore: 0,
            lastContactDate: ghostDate,
            notes: "A test ghost to see the haunting feature! 👻"
        )
        modelContext.insert(ghost)
        try? modelContext.save()
        showingGhostCreated = true
    }
}

// MARK: - Add/Edit Category View

struct AddEditCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var category: Category?

    @State private var name: String = ""
    @State private var selectedIcon: String = "tag.fill"
    @State private var selectedColorHex: String = "808080"

    private var isEditing: Bool { category != nil }
    private var isSaveDisabled: Bool { name.trimmingCharacters(in: .whitespaces).isEmpty }

    private let iconOptions = [
        "tag.fill", "heart.fill", "star.fill", "house.fill",
        "person.2.fill", "briefcase.fill", "graduationcap.fill", "gamecontroller.fill",
        "figure.run", "dumbbell.fill", "music.note", "book.fill",
        "fork.knife", "cup.and.saucer.fill", "car.fill", "airplane"
    ]

    private let colorOptions = [
        "5B9BD5",  // Blue
        "70C1B3",  // Teal
        "F4A259",  // Orange
        "E57373",  // Red
        "81C784",  // Green
        "BA68C8",  // Purple
        "FFD54F",  // Yellow
        "9B9B9B"   // Gray
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Category name", text: $name)
                }

                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.system(size: 20))
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedIcon == icon ? Color(hex: selectedColorHex).opacity(0.2) : Color(.secondarySystemFill))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedIcon == icon ? Color(hex: selectedColorHex) : .clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(selectedIcon == icon ? Color(hex: selectedColorHex) : .primary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Color") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(colorOptions, id: \.self) { colorHex in
                            Button {
                                selectedColorHex = colorHex
                            } label: {
                                Circle()
                                    .fill(Color(hex: colorHex))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(.white, lineWidth: selectedColorHex == colorHex ? 3 : 0)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color(hex: colorHex), lineWidth: selectedColorHex == colorHex ? 2 : 0)
                                            .padding(-3)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if isEditing && category?.isDefault == false {
                    Section {
                        Button(role: .destructive) {
                            deleteCategory()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Category")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Category" : "New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") { save() }
                        .disabled(isSaveDisabled)
                }
            }
            .onAppear { populateIfEditing() }
        }
    }

    private func populateIfEditing() {
        guard let category else { return }
        name = category.name
        selectedIcon = category.icon
        selectedColorHex = category.colorHex
    }

    private func save() {
        if let category {
            category.name = name.trimmingCharacters(in: .whitespaces)
            category.icon = selectedIcon
            category.colorHex = selectedColorHex
        } else {
            let newCategory = Category(
                name: name.trimmingCharacters(in: .whitespaces),
                icon: selectedIcon,
                colorHex: selectedColorHex,
                isDefault: false,
                sortOrder: 100
            )
            modelContext.insert(newCategory)
        }
        try? modelContext.save()
        dismiss()
    }

    private func deleteCategory() {
        if let category {
            modelContext.delete(category)
            try? modelContext.save()
        }
        dismiss()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Friend.self, Interaction.self], inMemory: true)
}
