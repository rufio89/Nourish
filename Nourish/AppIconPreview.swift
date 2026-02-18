//
//  AppIconPreview.swift
//  Nourish
//
//  Run this preview, screenshot it at 1024x1024, then upload to appicon.ai
//

import SwiftUI

struct AppIconView: View {
    var body: some View {
        ZStack {
            // Warm gradient background
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.6, blue: 0.3), Color(red: 1.0, green: 0.35, blue: 0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Icon
            VStack(spacing: -10) {
                Image(systemName: "person.2.circle.fill")
                    .font(.system(size: 280, weight: .medium))
                    .foregroundStyle(.white.opacity(0.95))
            }
        }
        .ignoresSafeArea()
    }
}

#Preview("App Icon — 1024pt", traits: .fixedLayout(width: 1024, height: 1024)) {
    AppIconView()
}
