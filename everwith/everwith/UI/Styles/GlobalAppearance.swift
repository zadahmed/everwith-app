//
//  GlobalAppearance.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI

// MARK: - Global App Appearance Configuration
class GlobalAppearance {
    static func configure() {
        configureNavigationBar()
        configureTabBar()
        configureAlertStyle()
        configureSheetStyle()
    }
    
    // MARK: - Navigation Bar Configuration
    private static func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        
        // Background with glassmorphism effect
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor(Color.warmLinen.opacity(0.8))
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        
        // Title styling
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(Color.charcoal),
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Color.charcoal),
            .font: UIFont.systemFont(ofSize: 32, weight: .bold)
        ]
        
        // Button styling
        appearance.buttonAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.honeyGold),
            .font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ]
        
        // Apply to all navigation bars
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Additional styling
        UINavigationBar.appearance().tintColor = UIColor(Color.honeyGold)
        UINavigationBar.appearance().isTranslucent = true
    }
    
    // MARK: - Tab Bar Configuration
    private static func configureTabBar() {
        let appearance = UITabBarAppearance()
        
        // Background with glassmorphism
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor(Color.warmLinen.opacity(0.9))
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        
        // Tab item styling
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.charcoal.opacity(0.6))
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.charcoal.opacity(0.6)),
            .font: UIFont.systemFont(ofSize: 12, weight: .medium)
        ]
        
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.honeyGold)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.honeyGold),
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold)
        ]
        
        // Apply to tab bar
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().isTranslucent = true
    }
    
    // MARK: - Alert Configuration
    private static func configureAlertStyle() {
        // Custom alert styling would go here
        // This is handled by SwiftUI's alert modifiers
    }
    
    // MARK: - Sheet Configuration
    private static func configureSheetStyle() {
        // Custom sheet styling would go here
        // This is handled by SwiftUI's sheet modifiers
    }
}

// MARK: - iOS 26 Style View Modifiers
struct ModernNavigationView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        NavigationView {
            content
                .background(
                    // Subtle background gradient
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.warmLinen,
                            Color.warmLinen.opacity(0.8)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Modern Sheet Style
struct ModernSheet<Content: View>: View {
    let content: Content
    @Binding var isPresented: Bool
    
    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.content = content()
    }
    
    var body: some View {
        content
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(.ultraThinMaterial)
            .presentationCornerRadius(ModernDesignSystem.CornerRadius.lg)
    }
}

// MARK: - Modern Alert Style
struct ModernAlert {
    static func show(
        title: String,
        message: String,
        primaryButton: String = "OK",
        secondaryButton: String? = nil,
        primaryAction: (() -> Void)? = nil,
        secondaryAction: (() -> Void)? = nil
    ) {
        // This would integrate with a custom alert system
        // For now, we'll use the standard SwiftUI alert
    }
}

// MARK: - Background Gradient Modifier
struct BackgroundGradientModifier: ViewModifier {
    let colors: [Color]
    let startPoint: UnitPoint
    let endPoint: UnitPoint
    
    init(
        colors: [Color] = [Color.honeyGold.opacity(0.1), Color.sky.opacity(0.1)],
        startPoint: UnitPoint = .topLeading,
        endPoint: UnitPoint = .bottomTrailing
    ) {
        self.colors = colors
        self.startPoint = startPoint
        self.endPoint = endPoint
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    gradient: Gradient(colors: colors),
                    startPoint: startPoint,
                    endPoint: endPoint
                )
                .ignoresSafeArea()
            )
    }
}

// MARK: - View Extensions
extension View {
    func modernNavigation() -> some View {
        ModernNavigationView {
            self
        }
    }
    
    func modernSheet(isPresented: Binding<Bool>) -> some View {
        ModernSheet(isPresented: isPresented) {
            self
        }
    }
    
    func backgroundGradient(
        colors: [Color] = [Color.honeyGold.opacity(0.1), Color.sky.opacity(0.1)],
        startPoint: UnitPoint = .topLeading,
        endPoint: UnitPoint = .bottomTrailing
    ) -> some View {
        self.modifier(BackgroundGradientModifier(colors: colors, startPoint: startPoint, endPoint: endPoint))
    }
}

#Preview {
    ModernNavigationView {
        ScrollView {
            VStack(spacing: ModernDesignSystem.Spacing.lg) {
                Text("Modern Navigation")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.charcoal)
                
                ModernCard(style: .light) {
                    VStack(spacing: ModernDesignSystem.Spacing.md) {
                        Text("Glassmorphism Card")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.charcoal)
                        
                        Text("This card demonstrates the modern glassmorphism styling with your Everwith branding.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.charcoal.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                }
                
                VStack(spacing: ModernDesignSystem.Spacing.md) {
                    Button("Primary Action") {
                        print("Primary action")
                    }
                    .buttonStyle(ModernButtonStyle(style: .primary))
                    
                    Button("Secondary Action") {
                        print("Secondary action")
                    }
                    .buttonStyle(ModernButtonStyle(style: .secondary))
                    
                    Button("Subtle Action") {
                        print("Subtle action")
                    }
                    .buttonStyle(ModernButtonStyle(style: .subtle))
                }
            }
            .padding(ModernDesignSystem.Spacing.lg)
        }
        .navigationTitle("Everwith")
        .navigationBarTitleDisplayMode(.large)
    }
}
