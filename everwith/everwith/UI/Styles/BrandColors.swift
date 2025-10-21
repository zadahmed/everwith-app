//
//  BrandColors.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI

// MARK: - EverWith Brand Color System
extension Color {
    // Primary Gradient Colors
    static let everBlush = Color(red: 1.0, green: 0.541, blue: 0.502)      // #FF8A80
    static let eternalRose = Color(red: 1.0, green: 0.4, blue: 0.702)        // #FF66B3
    static let memoryViolet = Color(red: 0.69, green: 0.416, blue: 0.941)   // #B06AF0
    static let sunsetPeach = Color(red: 1.0, green: 0.796, blue: 0.643)     // #FFCBA4
    static let softCream = Color(red: 1.0, green: 0.976, blue: 0.957)       // #FFF9F4
    
    // Neutrals
    static let pureWhite = Color(red: 1.0, green: 1.0, blue: 1.0)           // #FFFFFF
    static let softSand = Color(red: 0.973, green: 0.961, blue: 0.945)      // #F8F5F1
    static let shadowPlum = Color(red: 0.29, green: 0.247, blue: 0.369)      // #4A3F5E
    static let warmGray = Color(red: 0.612, green: 0.557, blue: 0.639)      // #9C8EA3
    
    // Note: Legacy colors (honeyGold, sky, fern, etc.) are defined in Assets.xcassets
    // We'll gradually migrate to the new EverWith color system
    
    // Brand Gradients
    static let brandGradient = LinearGradient(
        gradient: Gradient(colors: [everBlush, eternalRose, memoryViolet]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let brandRadialGradient = RadialGradient(
        gradient: Gradient(colors: [everBlush, eternalRose, memoryViolet]),
        center: .center,
        startRadius: 0,
        endRadius: 100
    )
    
    static let warmGradient = LinearGradient(
        gradient: Gradient(colors: [everBlush, sunsetPeach]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let magicalGradient = LinearGradient(
        gradient: Gradient(colors: [eternalRose, memoryViolet]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Design Tokens
struct DesignTokens {
    // Corner Radius
    static let radiusSmall: CGFloat = 16
    static let radiusMedium: CGFloat = 24
    static let radiusLarge: CGFloat = 28
    
    // Shadows
    static let shadowSoft = Color.black.opacity(0.08)
    static let shadowOffset = CGSize(width: 0, height: 8)
    static let shadowRadius: CGFloat = 24
    
    // Spacing
    static let spacingSmall: CGFloat = 8
    static let spacingMedium: CGFloat = 16
    static let spacingLarge: CGFloat = 24
    static let spacingXLarge: CGFloat = 32
    
    // Button Padding
    static let buttonPaddingVertical: CGFloat = 14
    static let buttonPaddingHorizontal: CGFloat = 20
    
    // Animation Duration
    static let animationDuration: Double = 0.25 // 250ms
    static let animationDurationSlow: Double = 0.3 // 300ms
}

// MARK: - Brand Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.pureWhite)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.buttonPaddingVertical)
            .padding(.horizontal, DesignTokens.buttonPaddingHorizontal)
            .background(Color.brandGradient)
            .cornerRadius(DesignTokens.radiusMedium)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: DesignTokens.animationDuration), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.shadowPlum)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.buttonPaddingVertical)
            .padding(.horizontal, DesignTokens.buttonPaddingHorizontal)
            .background(Color.softSand)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                    .stroke(Color.everBlush, lineWidth: 1)
            )
            .cornerRadius(DesignTokens.radiusMedium)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: DesignTokens.animationDuration), value: configuration.isPressed)
    }
}

