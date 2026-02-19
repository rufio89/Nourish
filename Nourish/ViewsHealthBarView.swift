//
//  HealthBarView.swift
//  Nourish
//

import SwiftUI

struct HealthBarView: View {
    let score: Double   // 0–100
    var height: CGFloat = 8
    var showHearts: Bool = false

    private var status: HealthStatus { HealthStatus.status(for: score) }

    var body: some View {
        Group {
            if showHearts {
                heartsView
            } else {
                barView
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Health score \(Int(score)) out of 100, \(status.rawValue)")
    }

    private var barView: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemFill))

                Capsule()
                    .fill(barGradient)
                    .frame(width: geo.size.width * (score / 100))
                    .animation(.spring(duration: 0.4), value: score)
            }
        }
        .frame(height: height)
    }

    private var heartsView: some View {
        HStack(spacing: 4) {
            ForEach(0..<5) { index in
                let fillAmount = min(1.0, max(0, (score - Double(index) * 20) / 20))

                Image(systemName: status == .ghost ? "heart.slash" :
                        fillAmount >= 1.0 ? "heart.fill" :
                        fillAmount > 0 ? "heart.lefthalf.fill" : "heart")
                    .font(.system(size: height * 1.5))
                    .foregroundStyle(status == .ghost ? status.color.opacity(0.5) :
                        fillAmount > 0 ? status.color : Color(.systemFill))
                    .symbolEffect(.pulse, options: .repeating, value: status == .critical && index == 0)
            }
        }
        .animation(.spring(duration: 0.4), value: score)
    }

    private var barGradient: LinearGradient {
        LinearGradient(
            colors: [status.color.opacity(0.8), status.color],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Creature Avatar View

struct CreatureAvatarView: View {
    let friend: Friend
    var size: CGFloat = 60

    @Environment(\.colorScheme) private var colorScheme
    @State private var bounce = false
    @State private var wiggle = false
    @State private var ghostFloat = false
    @State private var ghostShimmer = false

    private var isGhost: Bool { friend.isGhost }

    var body: some View {
        ZStack {
            // Ghost aura (only for ghosts)
            if isGhost {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [HealthStatus.ghost.color.opacity(0.4), Color.clear],
                            center: .center,
                            startRadius: size * 0.3,
                            endRadius: size * 0.6
                        )
                    )
                    .frame(width: size * 1.3, height: size * 1.3)
                    .blur(radius: 8)
                    .opacity(ghostShimmer ? 0.8 : 0.4)
            }

            // Background bubble
            Circle()
                .fill(
                    LinearGradient(
                        colors: friend.status.bgGradient(for: colorScheme),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: friend.status.color.opacity(isGhost ? 0.5 : 0.3), radius: isGhost ? 12 : 8, x: 0, y: 4)
                .opacity(isGhost ? 0.7 : 1.0)

            // Profile image or creature
            if let image = friend.profileImage {
                image
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
                    .padding(4)
                    .opacity(isGhost ? 0.6 : 1.0)
                    .saturation(isGhost ? 0.3 : 1.0)
            } else {
                VStack(spacing: 2) {
                    Text(friend.status.creatureFace)
                        .font(.system(size: size * 0.35))
                    Text(friend.name.prefix(1).uppercased())
                        .font(.system(size: size * 0.2, weight: .bold, design: .rounded))
                        .foregroundStyle(friend.status.color)
                }
                .opacity(isGhost ? 0.8 : 1.0)
            }

            // Status indicator
            Circle()
                .fill(friend.status.color)
                .frame(width: size * 0.22, height: size * 0.22)
                .overlay(
                    Text(friend.status.emoji)
                        .font(.system(size: size * 0.12))
                )
                .offset(x: size * 0.35, y: -size * 0.35)
                .shadow(color: isGhost ? HealthStatus.ghost.color.opacity(0.5) : .primary.opacity(0.1), radius: isGhost ? 4 : 2, x: 0, y: 1)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(friend.name), status: \(friend.status.rawValue)")
        .scaleEffect(bounce ? 1.05 : 1.0)
        .rotationEffect(.degrees(wiggle ? 2 : -2))
        .offset(y: ghostFloat ? -4 : 4)
        .onAppear {
            if friend.status == .thriving {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    bounce = true
                }
            }
            if friend.status == .critical {
                withAnimation(.easeInOut(duration: 0.15).repeatForever(autoreverses: true)) {
                    wiggle = true
                }
            }
            if isGhost {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    ghostFloat = true
                }
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    ghostShimmer = true
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HealthBarView(score: 90)
        HealthBarView(score: 90, showHearts: true)
        HealthBarView(score: 60, showHearts: true)
        HealthBarView(score: 35, showHearts: true)
        HealthBarView(score: 8, showHearts: true)
    }
    .padding()
}
