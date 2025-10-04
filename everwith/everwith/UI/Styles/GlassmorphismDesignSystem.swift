//
//  ModernDesignSystem.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI

// MARK: - Modern Design System
struct ModernDesignSystem {
    
    // MARK: - Clean Glass Effects
    struct GlassEffect {
        static let subtle = GlassEffectStyle(
            background: Color.white.opacity(0.05),
            border: Color.clear,
            shadow: Color.black.opacity(0.02)
        )
        
        static let light = GlassEffectStyle(
            background: Color.white.opacity(0.08),
            border: Color.clear,
            shadow: Color.black.opacity(0.04)
        )
        
        static let medium = GlassEffectStyle(
            background: Color.white.opacity(0.12),
            border: Color.clear,
            shadow: Color.black.opacity(0.06)
        )
        
        // Brand-specific clean effects
        static let honeyGold = GlassEffectStyle(
            background: Color.honeyGold.opacity(0.08),
            border: Color.clear,
            shadow: Color.honeyGold.opacity(0.05)
        )
        
        static let warmLinen = GlassEffectStyle(
            background: Color.warmLinen.opacity(0.15),
            border: Color.clear,
            shadow: Color.charcoal.opacity(0.02)
        )
    }
    
    // MARK: - Clean Blur Effects
    struct BlurEffect {
        static let subtle = Material.ultraThinMaterial
        static let light = Material.thinMaterial
        static let medium = Material.regularMaterial
    }
    
    // MARK: - Modern Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Clean Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let full: CGFloat = 999
    }
    
    // MARK: - Subtle Shadows
    struct Shadow {
        static let none = ShadowStyle(
            color: Color.clear,
            radius: 0,
            x: 0,
            y: 0
        )
        
        static let subtle = ShadowStyle(
            color: Color.black.opacity(0.03),
            radius: 4,
            x: 0,
            y: 2
        )
        
        static let light = ShadowStyle(
            color: Color.black.opacity(0.05),
            radius: 8,
            x: 0,
            y: 4
        )
        
        static let medium = ShadowStyle(
            color: Color.black.opacity(0.08),
            radius: 12,
            x: 0,
            y: 6
        )
    }
}

// MARK: - Supporting Structures
struct GlassEffectStyle {
    let background: Color
    let border: Color
    let shadow: Color
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Clean Glassmorphism View Modifiers
struct CleanGlassmorphismModifier: ViewModifier {
    let style: GlassEffectStyle
    let blur: Material
    let cornerRadius: CGFloat
    let shadow: ShadowStyle
    
    init(
        style: GlassEffectStyle = ModernDesignSystem.GlassEffect.light,
        blur: Material = ModernDesignSystem.BlurEffect.light,
        cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.md,
        shadow: ShadowStyle = ModernDesignSystem.Shadow.subtle
    ) {
        self.style = style
        self.blur = blur
        self.cornerRadius = cornerRadius
        self.shadow = shadow
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(style.background)
                    .background(blur)
            )
            .shadow(
                color: shadow.color,
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
    }
}

// MARK: - View Extensions
extension View {
    func cleanGlassmorphism(
        style: GlassEffectStyle = ModernDesignSystem.GlassEffect.light,
        blur: Material = ModernDesignSystem.BlurEffect.light,
        cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.md,
        shadow: ShadowStyle = ModernDesignSystem.Shadow.subtle
    ) -> some View {
        self.modifier(CleanGlassmorphismModifier(style: style, blur: blur, cornerRadius: cornerRadius, shadow: shadow))
    }
}

// MARK: - Modern Button Styles
struct ModernButtonStyle: ButtonStyle {
    let style: ButtonType
    let size: ButtonSize
    
    enum ButtonType {
        case primary
        case secondary
        case subtle
        case minimal
    }
    
    enum ButtonSize {
        case small
        case medium
        case large
    }
    
    init(style: ButtonType = .primary, size: ButtonSize = .medium) {
        self.style = style
        self.size = size
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(backgroundView)
            .cornerRadius(ModernDesignSystem.CornerRadius.md)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private var font: Font {
        switch size {
        case .small:
            return .system(size: 14, weight: .medium)
        case .medium:
            return .system(size: 16, weight: .semibold)
        case .large:
            return .system(size: 18, weight: .semibold)
        }
    }
    
    private var height: CGFloat {
        switch size {
        case .small:
            return 44
        case .medium:
            return 52
        case .large:
            return 60
        }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            Color.honeyGold
        case .secondary:
            Color.clear
                .overlay(
                    RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                        .stroke(Color.charcoal.opacity(0.15), lineWidth: 1)
                )
        case .subtle:
            Color.clear
                .cleanGlassmorphism(
                    style: ModernDesignSystem.GlassEffect.honeyGold,
                    blur: ModernDesignSystem.BlurEffect.subtle,
                    shadow: ModernDesignSystem.Shadow.none
                )
        case .minimal:
            Color.clear
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary, .subtle:
            return .charcoal
        case .secondary, .minimal:
            return .charcoal
        }
    }
}

// MARK: - Modern Card Component
struct ModernCard<Content: View>: View {
    let content: Content
    let style: CardStyle
    let padding: CGFloat
    
    enum CardStyle {
        case subtle
        case light
        case medium
    }
    
    init(
        style: CardStyle = .light,
        padding: CGFloat = ModernDesignSystem.Spacing.lg,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(cardBackground)
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        switch style {
        case .subtle:
            Color.clear
                .cleanGlassmorphism(
                    style: ModernDesignSystem.GlassEffect.subtle,
                    blur: ModernDesignSystem.BlurEffect.subtle,
                    shadow: ModernDesignSystem.Shadow.none
                )
        case .light:
            Color.clear
                .cleanGlassmorphism(
                    style: ModernDesignSystem.GlassEffect.light,
                    blur: ModernDesignSystem.BlurEffect.light,
                    shadow: ModernDesignSystem.Shadow.subtle
                )
        case .medium:
            Color.clear
                .cleanGlassmorphism(
                    style: ModernDesignSystem.GlassEffect.medium,
                    blur: ModernDesignSystem.BlurEffect.light,
                    shadow: ModernDesignSystem.Shadow.light
                )
        }
    }
}

#Preview {
    ZStack {
        // Clean background gradient
        LinearGradient(
            gradient: Gradient(colors: [
                Color.warmLinen.opacity(0.3),
                Color.honeyGold.opacity(0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: ModernDesignSystem.Spacing.lg) {
                // Modern Card
                ModernCard(style: .light) {
                    VStack(spacing: ModernDesignSystem.Spacing.md) {
                        Text("Clean Design")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.charcoal)
                        
                        Text("This is a clean, modern card with subtle glassmorphism effects")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.charcoal.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Modern Buttons
                VStack(spacing: ModernDesignSystem.Spacing.md) {
                    Button("Primary Button") {
                        print("Primary tapped")
                    }
                    .buttonStyle(ModernButtonStyle(style: .primary))
                    
                    Button("Secondary Button") {
                        print("Secondary tapped")
                    }
                    .buttonStyle(ModernButtonStyle(style: .secondary))
                    
                    Button("Subtle Button") {
                        print("Subtle tapped")
                    }
                    .buttonStyle(ModernButtonStyle(style: .subtle))
                    
                    Button("Minimal Button") {
                        print("Minimal tapped")
                    }
                    .buttonStyle(ModernButtonStyle(style: .minimal))
                }
            }
            .padding(ModernDesignSystem.Spacing.lg)
        }
    }
}
