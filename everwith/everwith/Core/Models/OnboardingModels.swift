//
//  OnboardingModels.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import Foundation
import SwiftUI

// MARK: - Onboarding Card Model (Simplified for Single Card)
struct OnboardingCard: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let gradient: [Color]
    let illustration: String?
    
    // Single card for trust-focused onboarding
    static let singleCard = OnboardingCard(
        title: "Restore precious photos.",
        subtitle: "Keep control of what you share.",
        description: "Our AI carefully restores your precious photos, preserving every detail while bringing faded memories back to vibrant life. You control what gets processed and can delete data anytime.",
        icon: "photo.badge.plus",
        gradient: [Color.honeyGold, Color.honeyGold.opacity(0.8)],
        illustration: nil
    )
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
