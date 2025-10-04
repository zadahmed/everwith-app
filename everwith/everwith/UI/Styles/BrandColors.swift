//
//  BrandColors.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI

// MARK: - Brand Colors Extension
extension Color {
    // Brand Gradients (using auto-generated color symbols)
    static let brandGradient = LinearGradient(
        gradient: Gradient(colors: [Color.honeyGold, Color.sky]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let brandRadialGradient = RadialGradient(
        gradient: Gradient(colors: [Color.honeyGold, Color.sky]),
        center: .center,
        startRadius: 0,
        endRadius: 100
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
            .foregroundColor(.charcoal)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.buttonPaddingVertical)
            .padding(.horizontal, DesignTokens.buttonPaddingHorizontal)
            .background(Color.honeyGold)
            .cornerRadius(DesignTokens.radiusMedium)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: DesignTokens.animationDuration), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.charcoal)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.buttonPaddingVertical)
            .padding(.horizontal, DesignTokens.buttonPaddingHorizontal)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                    .stroke(Color.charcoal, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: DesignTokens.animationDuration), value: configuration.isPressed)
    }
}

