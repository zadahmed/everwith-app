//
//  BrandColors.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI

// MARK: - EverWith White-Base Brand Colors
extension Color {
    // MARK: - Core White-Base Colors
    static let pureWhite = Color(red: 1.0, green: 1.0, blue: 1.0) // #FFFFFF
    static let softCream = Color(red: 1.0, green: 0.98, blue: 0.96) // #FFF9F4
    
    // MARK: - Primary Gradient Colors (Used Sparingly)
    static let blushPink = Color(red: 1.0, green: 0.54, blue: 0.5) // #FF8A80
    static let roseMagenta = Color(red: 1.0, green: 0.4, blue: 0.7) // #FF66B3
    static let memoryViolet = Color(red: 0.69, green: 0.42, blue: 0.94) // #B06AF0
    
    // MARK: - Secondary Highlight Colors
    static let lightBlush = Color(red: 1.0, green: 0.85, blue: 0.88) // #FFD9E1
    static let softLavender = Color(red: 0.95, green: 0.9, blue: 0.98) // #F2E6FA
    
    // MARK: - Text Colors
    static let deepPlum = Color(red: 0.24, green: 0.16, blue: 0.3) // #3C2A4D
    static let softPlum = Color(red: 0.54, green: 0.48, blue: 0.59) // #8A7A96
    static let lightGray = Color(red: 0.6, green: 0.6, blue: 0.65) // #9999A5
    
    // MARK: - Subtle Borders & Dividers
    static let subtleBorder = Color(red: 0.0, green: 0.0, blue: 0.0).opacity(0.06)
    static let cardShadow = Color(red: 0.0, green: 0.0, blue: 0.0).opacity(0.05)
    static let gentleShadow = Color(red: 0.0, green: 0.0, blue: 0.0).opacity(0.08)
    
    // MARK: - Legacy Colors (for compatibility)
    // These are defined in Assets.xcassets to avoid redeclaration errors
    // everBlush, eternalRose, sunsetPeach, softSand, shadowPlum, warmGray
}

// MARK: - Brand Gradients
extension LinearGradient {
    static let primaryBrand = LinearGradient(
        gradient: Gradient(colors: [
            Color.blushPink,
            Color.roseMagenta,
            Color.memoryViolet
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let subtleHighlight = LinearGradient(
        gradient: Gradient(colors: [
            Color.lightBlush.opacity(0.3),
            Color.softLavender.opacity(0.2)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGlow = LinearGradient(
        gradient: Gradient(colors: [
            Color.blushPink.opacity(0.1),
            Color.roseMagenta.opacity(0.05)
        ]),
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
    static let shadowSoft = Color.black.opacity(0.05)
    static let shadowOffset = CGSize(width: 0, height: 4)
    static let shadowRadius: CGFloat = 12
    
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

// MARK: - Background Components
struct CleanWhiteBackground: View {
    var body: some View {
        GeometryReader { geometry in
            let width = max(geometry.size.width, 1)
            let height = max(geometry.size.height, 1)
            let maxDimension = max(width, height)
            
            ZStack {
                // Base gradient wash
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.pureWhite,
                        Color.softCream.opacity(0.95),
                        Color.lightBlush.opacity(0.25)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Soft top glow
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.9),
                        Color.white.opacity(0.0)
                    ]),
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: maxDimension * 0.9
                )
                .blendMode(.plusLighter)
                .frame(width: maxDimension * 1.2, height: maxDimension * 1.2)
                .offset(x: -width * 0.25, y: -height * 0.45)
                
                // Ambient blush orb
                Circle()
                    .fill(Color.lightBlush.opacity(0.25))
                    .blur(radius: 90)
                    .frame(width: maxDimension * 0.9, height: maxDimension * 0.9)
                    .offset(x: width * 0.35, y: -height * 0.3)
                    .allowsHitTesting(false)
                
                // Subtle lavender wash near bottom
                Ellipse()
                    .fill(Color.softLavender.opacity(0.35))
                    .blur(radius: 120)
                    .frame(width: width * 1.4, height: max(180, height * 0.45))
                    .offset(x: -width * 0.2, y: height * 0.45)
                    .allowsHitTesting(false)
                
                // Soft vignette to keep focus centered
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.0),
                        Color.white.opacity(0.25)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: height)
                .allowsHitTesting(false)
                
                // Fine highlight border for a glassy feel
                RoundedRectangle(cornerRadius: 0)
                    .stroke(LinearGradient.subtleHighlight.opacity(0.35), lineWidth: 1)
                    .blur(radius: 60)
                    .padding(-80)
                    .allowsHitTesting(false)
            }
            .frame(width: width, height: height)
            .background(Color.pureWhite)
            .ignoresSafeArea()
        }
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.pureWhite)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.buttonPaddingVertical)
            .padding(.horizontal, DesignTokens.buttonPaddingHorizontal)
            .background(LinearGradient.primaryBrand)
            .cornerRadius(DesignTokens.radiusMedium)
            .shadow(color: Color.blushPink.opacity(0.3), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: DesignTokens.animationDuration), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.deepPlum)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.buttonPaddingVertical)
            .padding(.horizontal, DesignTokens.buttonPaddingHorizontal)
            .background(Color.pureWhite)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                    .stroke(Color.subtleBorder, lineWidth: 1)
            )
            .cornerRadius(DesignTokens.radiusMedium)
            .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: DesignTokens.animationDuration), value: configuration.isPressed)
    }
}

