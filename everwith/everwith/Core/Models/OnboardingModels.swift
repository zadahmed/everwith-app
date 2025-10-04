//
//  OnboardingModels.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import Foundation
import SwiftUI

// MARK: - Onboarding Card Model
struct OnboardingCard: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let gradient: [Color]
    let illustration: String?
    
    static let cards: [OnboardingCard] = [
        OnboardingCard(
            title: "Restore with care",
            subtitle: "Bring memories back to life",
            description: "Our AI carefully restores your precious photos, preserving every detail while bringing faded memories back to vibrant life.",
            icon: "photo.badge.plus",
            gradient: [Color.honeyGold.opacity(0.8), Color.warmLinen.opacity(0.6)],
            illustration: nil
        ),
        OnboardingCard(
            title: "Together Scene",
            subtitle: "Share the journey",
            description: "Create beautiful tributes and share restored memories with loved ones. Every photo tells a story worth preserving.",
            icon: "heart.circle",
            gradient: [Color.sky.opacity(0.8), Color.fern.opacity(0.6)],
            illustration: nil
        ),
        OnboardingCard(
            title: "Privacy first",
            subtitle: "Your memories, your control",
            description: "We process photos securely on our servers with enterprise-grade encryption. You control what gets processed and can delete data anytime.",
            icon: "lock.shield",
            gradient: [Color.charcoal.opacity(0.8), Color.softBlush.opacity(0.6)],
            illustration: nil
        )
    ]
}

// MARK: - Permission State
enum PermissionState {
    case notRequested
    case granted
    case denied
    case restricted
}

// MARK: - Onboarding State
enum OnboardingState {
    case cards
    case requestingPermission
    case permissionGranted
    case permissionDenied
    case completed
}
