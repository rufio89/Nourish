//
//  LogInteractionView.swift
//  Nourish
//

import SwiftUI
import SwiftData

struct LogInteractionView: View {
    @Bindable var friend: Friend
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: InteractionType = .hangout
    @State private var note: String = ""
    @State private var date: Date = .now

    var body: some View {
        NavigationStack {
            Form {
                Section("What did you do?") {
                    ForEach(InteractionType.allCases) { type in
                        HStack {
                            Image(systemName: type.icon)
                                .foregroundStyle(.tint)
                                .frame(width: 24)

                            Text(type.rawValue)

                            Spacer()

                            Text("+\(Int(type.points)) pts")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if selectedType == type {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { selectedType = type }
                    }
                }

                Section("When?") {
                    DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)
                }

                Section("Note (optional)") {
                    TextField("How did it go?", text: $note, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section {
                    healthPreview
                }
            }
            .navigationTitle("Log Interaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") { logInteraction() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Health Preview

    private var previewScore: Double {
        min(100, friend.healthScore + selectedType.points)
    }

    private var healthPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Health Preview")
                .font(.subheadline.bold())

            HStack {
                Text("\(Int(friend.healthScore))")
                    .foregroundStyle(.secondary)
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                Text("\(Int(previewScore))")
                    .foregroundStyle(HealthStatus.status(for: previewScore).color)
                    .fontWeight(.semibold)
                Text("(+\(Int(selectedType.points)))")
                    .foregroundStyle(.green)
            }
            .font(.subheadline)

            HealthBarView(score: previewScore, height: 10)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Health preview: \(Int(friend.healthScore)) to \(Int(previewScore)), plus \(Int(selectedType.points)) points")
    }

    // MARK: - Log

    private func logInteraction() {
        withAnimation {
            friend.logInteraction(type: selectedType, note: note, date: date)
            try? modelContext.save()
        }
        dismiss()
    }
}

#Preview {
    let friend = Friend(name: "Alex", healthScore: 45)
    return LogInteractionView(friend: friend)
        .modelContainer(for: [Friend.self, Interaction.self], inMemory: true)
}
