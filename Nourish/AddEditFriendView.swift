//
//  AddEditFriendView.swift
//  Nourish
//

import SwiftUI
import SwiftData
import PhotosUI

struct AddEditFriendView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var friend: Friend?

    @Query(sort: \Category.sortOrder)
    private var categories: [Category]

    @State private var name: String = ""
    @State private var phoneNumber: String = ""
    @State private var notes: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var lastContactDate: Date = Calendar.current.date(byAdding: .day, value: -14, to: .now) ?? .now
    @State private var rememberLastContact: Bool = false
    @State private var selectedCategories: Set<PersistentIdentifier> = []

    private var isEditing: Bool { friend != nil }
    private var isSaveDisabled: Bool { name.trimmingCharacters(in: .whitespaces).isEmpty }

    private var estimatedStatus: HealthStatus {
        let score = calculateHealthScore(from: lastContactDate)
        return HealthStatus.status(for: score)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            avatarView
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)

                    ContactPickerButton(onPick: { picked in
                        name = picked.name
                        phoneNumber = picked.phoneNumber
                        photoData = picked.photoData
                    }) {
                        Label("Import from Contacts", systemImage: "person.crop.circle.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .listRowBackground(Color.clear)
                }

                Section("Name") {
                    TextField("Friend's name", text: $name)
                }

                Section("Phone Number") {
                    TextField("e.g. +1 555 123 4567", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }

                Section("Notes") {
                    TextField("Anything worth remembering…", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if !categories.isEmpty {
                    Section("Categories") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                            ForEach(categories) { category in
                                CategoryChip(
                                    category: category,
                                    isSelected: selectedCategories.contains(category.id)
                                ) {
                                    toggleCategory(category)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                if !isEditing {
                    Section {
                        Toggle(isOn: $rememberLastContact.animation()) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("I remember when we last connected")
                                    .font(.system(.subheadline, design: .rounded))
                                if !rememberLastContact {
                                    Text("They'll start needing attention")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .tint(.mint)

                        if rememberLastContact {
                            DatePicker(
                                "Last connected",
                                selection: $lastContactDate,
                                in: ...Date.now,
                                displayedComponents: .date
                            )
                            .font(.system(.subheadline, design: .rounded))

                            HStack {
                                Text("Starting status:")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(estimatedStatus.emoji) \(estimatedStatus.rawValue)")
                                    .font(.system(.caption, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(estimatedStatus.color)
                            }
                        }
                    } header: {
                        Text("When did you last connect?")
                    } footer: {
                        if rememberLastContact {
                            Text("Health decays \(Image(systemName: "heart")) 5 points per day since last contact")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Friend" : "Plant Friend")
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
            .task(id: selectedPhoto) {
                if let selectedPhoto {
                    photoData = try? await selectedPhoto.loadTransferable(type: Data.self)
                }
            }
            .onAppear { populateIfEditing() }
        }
    }

    // MARK: - Avatar

    @ViewBuilder
    private var avatarView: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let photoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.tint)
                        }
                }
            }
            .frame(width: 90, height: 90)
            .clipShape(Circle())

            Image(systemName: "camera.circle.fill")
                .font(.title2)
                .foregroundStyle(.tint)
                .background(Color(.systemBackground), in: Circle())
        }
    }

    // MARK: - Helpers

    private func populateIfEditing() {
        guard let friend else { return }
        name            = friend.name
        phoneNumber     = friend.phoneNumber
        notes           = friend.notes
        photoData       = friend.photoData
        lastContactDate = friend.lastContactDate
        rememberLastContact = true
        selectedCategories = Set(friend.categories.map { $0.id })
    }

    private func toggleCategory(_ category: Category) {
        if selectedCategories.contains(category.id) {
            selectedCategories.remove(category.id)
        } else {
            selectedCategories.insert(category.id)
        }
    }

    private func save() {
        let selectedCats = categories.filter { selectedCategories.contains($0.id) }

        if let friend {
            friend.name        = name.trimmingCharacters(in: .whitespaces)
            friend.phoneNumber = phoneNumber.trimmingCharacters(in: .whitespaces)
            friend.notes       = notes
            friend.photoData   = photoData
            friend.categories  = selectedCats
        } else {
            // Calculate starting health based on last contact
            let contactDate = rememberLastContact ? lastContactDate : Calendar.current.date(byAdding: .day, value: -14, to: .now) ?? .now
            let startingHealth = calculateHealthScore(from: contactDate)

            let newFriend = Friend(
                name: name.trimmingCharacters(in: .whitespaces),
                photoData: photoData,
                healthScore: startingHealth,
                lastContactDate: contactDate,
                notes: notes,
                phoneNumber: phoneNumber.trimmingCharacters(in: .whitespaces)
            )
            newFriend.categories = selectedCats
            modelContext.insert(newFriend)
        }
        try? modelContext.save()
        dismiss()
    }

    private func calculateHealthScore(from lastContact: Date) -> Double {
        let daysSince = Calendar.current.dateComponents([.day], from: lastContact, to: .now).day ?? 0
        // Start at 100, decay 5 points per day
        return max(0, min(100, 100 - Double(daysSince) * 5))
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(category.name)
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? category.color : Color(.secondarySystemFill))
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}
