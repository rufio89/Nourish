//
//  FriendDetailView.swift
//  Nourish
//

import SwiftUI
import SwiftData
import MessageUI

struct FriendDetailView: View {
    @Bindable var friend: Friend
    @Environment(\.modelContext) private var modelContext

    @State private var showingLogInteraction = false
    @State private var showingEditFriend = false
    @State private var showingMessageComposer = false
    @State private var canSendText = MFMessageComposeViewController.canSendText()
    @State private var showingResurrection = false
    @State private var wasGhost = false

    private var sortedInteractions: [Interaction] {
        friend.interactions.sorted { $0.date > $1.date }
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    healthCard
                    if friend.isGhost {
                        resurrectSection
                    }
                    if !friend.phoneNumber.isEmpty {
                        reachOutSection
                    }
                    quickLogSection
                    if !sortedInteractions.isEmpty {
                        interactionHistory
                    }
                    if !friend.notes.isEmpty {
                        notesCard
                    }
                }
                .padding()
            }

            // Resurrection overlay
            if showingResurrection {
                ResurrectionOverlay(friendName: friend.name) {
                    showingResurrection = false
                }
            }
        }
        .navigationTitle(friend.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEditFriend = true }
            }
        }
        .sheet(isPresented: $showingLogInteraction) {
            LogInteractionView(friend: friend)
        }
        .sheet(isPresented: $showingEditFriend) {
            AddEditFriendView(friend: friend)
        }
        .sheet(isPresented: $showingMessageComposer) {
            MessageComposerView(recipient: friend.phoneNumber) {
                logInteractionWithResurrection(type: .text, note: "Sent a text")
            }
        }
        .onAppear {
            wasGhost = friend.isGhost
        }
    }

    private func logInteractionWithResurrection(type: InteractionType, note: String = "") {
        let wasGhostBefore = friend.isGhost
        friend.logInteraction(type: type, note: note)
        try? modelContext.save()

        // Show resurrection animation if they were a ghost
        if wasGhostBefore && !friend.isGhost {
            withAnimation {
                showingResurrection = true
            }
        }
    }

    // MARK: - Resurrect Section (for ghosts)

    private var resurrectSection: some View {
        VStack(spacing: 12) {
            Text("👻 This friendship has become a ghost!")
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.medium)

            Text("Reach out to bring them back to life")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(HealthStatus.ghost.color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(HealthStatus.ghost.color.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Health Card

    private var healthCard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                CreatureAvatarView(friend: friend, size: 80)

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    StatusBadge(status: friend.status)

                    Text("\(Int(friend.healthScore)) HP")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(friend.status.color)
                }
            }

            HealthBarView(score: friend.healthScore, height: 16, showHearts: true)

            HStack {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.secondary)
                Text("Last seen")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(friend.lastContactDate.formatted(.relative(presentation: .named)))
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: friend.status.bgGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: friend.status.color.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }

    // MARK: - Reach Out

    private var reachOutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "hand.wave.fill")
                    .foregroundStyle(.blue)
                Text("Reach Out")
                    .font(.system(.headline, design: .rounded))
            }

            HStack(spacing: 12) {
                Button {
                    if canSendText {
                        showingMessageComposer = true
                    } else {
                        openURL("sms:\(friend.phoneNumber)")
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "bubble.left.fill")
                            .font(.title2)
                        Text("Text")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue.opacity(0.1))
                    )
                    .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)

                Button {
                    openURL("tel:\(friend.phoneNumber)")
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                            .font(.title2)
                        Text("Call")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.green.opacity(0.1))
                    )
                    .foregroundStyle(.green)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }

    // MARK: - Quick Log

    private var quickLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.mint)
                Text("Feed Your Friendship")
                    .font(.system(.headline, design: .rounded))
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(InteractionType.allCases) { type in
                    QuickLogButton(type: type) {
                        withAnimation(.spring(duration: 0.5)) {
                            logInteractionWithResurrection(type: type)
                        }
                    }
                }
            }
            Button {
                showingLogInteraction = true
            } label: {
                Label("Log with note & date…", systemImage: "square.and.pencil")
                    .font(.system(.subheadline, design: .rounded))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.mint)
            .controlSize(.small)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }

    // MARK: - Interaction History

    private var interactionHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(.purple)
                Text("History")
                    .font(.system(.headline, design: .rounded))
            }

            ForEach(sortedInteractions) { interaction in
                InteractionRowView(interaction: interaction)
                if interaction.id != sortedInteractions.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }

    // MARK: - Notes

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundStyle(.orange)
                Text("Notes")
                    .font(.system(.headline, design: .rounded))
            }
            Text(friend.notes)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Message Composer

struct MessageComposerView: UIViewControllerRepresentable {
    let recipient: String
    var onSent: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onSent: onSent) }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.recipients = [recipient]
        vc.messageComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let onSent: () -> Void
        init(onSent: @escaping () -> Void) { self.onSent = onSent }

        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            controller.dismiss(animated: true)
            if result == .sent { onSent() }
        }
    }
}

// MARK: - Quick Log Button

struct QuickLogButton: View {
    let type: InteractionType
    let action: () -> Void
    @State private var tapped = false
    @State private var showPlusOne = false

    var body: some View {
        Button {
            tapped = true
            showPlusOne = true
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { tapped = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { showPlusOne = false }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Image(systemName: type.icon)
                        .font(.title2)
                        .symbolEffect(.bounce, value: tapped)

                    if showPlusOne {
                        Text("+\(Int(type.points))")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.mint))
                            .offset(y: -25)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .offset(y: 10)),
                                removal: .opacity.combined(with: .offset(y: -10))
                            ))
                    }
                }

                Text(type.rawValue)
                    .font(.system(.caption2, design: .rounded))
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(tapped ? Color.mint.opacity(0.2) : Color(.secondarySystemFill))
            )
            .foregroundStyle(tapped ? .mint : .primary)
            .scaleEffect(tapped ? 0.95 : 1.0)
            .animation(.spring(duration: 0.3), value: tapped)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Interaction Row

struct InteractionRowView: View {
    let interaction: Interaction

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.mint.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: interaction.type.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(.mint)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(interaction.type.rawValue)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.medium)
                if !interaction.note.isEmpty {
                    Text(interaction.note)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(interaction.date.formatted(date: .abbreviated, time: .omitted))
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Resurrection Overlay

struct ResurrectionOverlay: View {
    let friendName: String
    let onDismiss: () -> Void

    @State private var phase = 0
    @State private var sparkles: [SparkleParticle] = []

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(phase >= 1 ? 0.7 : 0)
                .ignoresSafeArea()

            // Sparkle particles
            ForEach(sparkles) { sparkle in
                Image(systemName: "sparkle")
                    .font(.system(size: sparkle.size))
                    .foregroundStyle(sparkle.color)
                    .position(sparkle.position)
                    .opacity(sparkle.opacity)
            }

            // Main content
            VStack(spacing: 24) {
                // Ghost transforming to alive
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white.opacity(0.8), .mint.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: phase >= 2 ? 150 : 50
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 20)

                    // Face transition
                    Text(phase >= 2 ? "😊" : "👻")
                        .font(.system(size: 60))
                        .scaleEffect(phase >= 2 ? 1.2 : 1.0)
                }

                if phase >= 2 {
                    VStack(spacing: 8) {
                        Text("Resurrection!")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("\(friendName) has returned!")
                            .font(.system(.title3, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                if phase >= 3 {
                    Button {
                        onDismiss()
                    } label: {
                        Text("Welcome Back!")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(.mint)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(.white, in: Capsule())
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            runAnimation()
        }
    }

    private func runAnimation() {
        // Phase 1: Darken background
        withAnimation(.easeIn(duration: 0.3)) {
            phase = 1
        }

        // Add sparkles
        for i in 0..<20 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                addSparkle()
            }
        }

        // Phase 2: Transform ghost
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(duration: 0.6)) {
                phase = 2
            }
        }

        // Phase 3: Show button
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(duration: 0.4)) {
                phase = 3
            }
        }
    }

    private func addSparkle() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        let sparkle = SparkleParticle(
            position: CGPoint(
                x: CGFloat.random(in: 50...(screenWidth - 50)),
                y: CGFloat.random(in: 200...(screenHeight - 200))
            ),
            size: CGFloat.random(in: 8...20),
            color: [Color.white, .mint, .yellow, .cyan].randomElement()!,
            opacity: Double.random(in: 0.6...1.0)
        )
        sparkles.append(sparkle)

        // Fade out sparkle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let index = sparkles.firstIndex(where: { $0.id == sparkle.id }) {
                withAnimation(.easeOut(duration: 0.5)) {
                    sparkles[index].opacity = 0
                }
            }
        }
    }
}

struct SparkleParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var color: Color
    var opacity: Double
}
