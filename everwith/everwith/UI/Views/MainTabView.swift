//
//  MainTabView.swift
//  EverWith
//
//  Main tab bar navigation
//

import SwiftUI

struct MainTabView: View {
    let user: User
    @State private var selectedTab: Tab = .home
    
    enum Tab {
        case home
        case myMemories
        case premium
        case settings
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Content with proper bottom padding
                Group {
                    switch selectedTab {
                    case .home:
                        HomeView(user: user)
                            .padding(.bottom, tabBarHeight(for: geometry))
                    case .myMemories:
                        NavigationStack {
                            MyCreationsView()
                                .navigationBarHidden(true)
                                .padding(.bottom, tabBarHeight(for: geometry))
                        }
                    case .premium:
                        NavigationStack {
                            PaywallView(trigger: .general)
                                .navigationBarHidden(true)
                                .padding(.bottom, tabBarHeight(for: geometry))
                        }
                    case .settings:
                        NavigationStack {
                            SettingsView()
                                .navigationBarHidden(true)
                                .padding(.bottom, tabBarHeight(for: geometry))
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Custom Tab Bar
                CustomTabBar(selectedTab: $selectedTab, geometry: geometry)
            }
            .ignoresSafeArea(.all, edges: .all)
        }
    }
    
    // Calculate tab bar height including safe area
    private func tabBarHeight(for geometry: GeometryProxy) -> CGFloat {
        let baseHeight: CGFloat = 80 // Base tab bar height
        let safeAreaBottom = geometry.safeAreaInsets.bottom
        return baseHeight + safeAreaBottom
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: MainTabView.Tab
    let geometry: GeometryProxy
    @State private var animateTab = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Home Tab
            TabBarButton(
                icon: selectedTab == .home ? "house.fill" : "house",
                label: "Home",
                isSelected: selectedTab == .home,
                geometry: geometry
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = .home
                }
            }
            
            // My Memories Tab
            TabBarButton(
                icon: selectedTab == .myMemories ? "photo.stack.fill" : "photo.stack",
                label: "Memories",
                isSelected: selectedTab == .myMemories,
                geometry: geometry
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = .myMemories
                }
            }
            
            // Premium Tab
            TabBarButton(
                icon: "crown.fill",
                label: "Premium",
                isSelected: selectedTab == .premium,
                isPremium: true,
                geometry: geometry
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = .premium
                }
            }
            
            // Settings Tab
            TabBarButton(
                icon: selectedTab == .settings ? "gearshape.fill" : "gearshape",
                label: "Settings",
                isSelected: selectedTab == .settings,
                geometry: geometry
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = .settings
                }
            }
        }
        .padding(.horizontal, adaptivePadding(for: geometry))
        .padding(.top, adaptiveSpacing(8, for: geometry))
        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom + 4 : 12)
        .background(
            // Glassmorphic background
            ZStack {
                // Blur effect
                Rectangle()
                    .fill(.ultraThinMaterial)
                
                // Gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.pureWhite.opacity(0.8),
                        Color.pureWhite.opacity(0.95)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Top border
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.subtleBorder.opacity(0.5),
                                Color.subtleBorder.opacity(0.2)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            .ignoresSafeArea(edges: .bottom)
        )
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 20,
            x: 0,
            y: -5
        )
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    var isPremium: Bool = false
    let geometry: GeometryProxy
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            VStack(spacing: adaptiveSpacing(4, for: geometry)) {
                ZStack {
                    // Selection indicator background
                    if isSelected {
                        RoundedRectangle(cornerRadius: adaptiveCornerRadius(12, for: geometry))
                            .fill(
                                isPremium
                                ? LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.honeyGold.opacity(0.15),
                                        Color.honeyGold.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.blushPink.opacity(0.15),
                                        Color.roseMagenta.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: adaptiveSize(56, for: geometry), height: adaptiveSize(40, for: geometry))
                    }
                    
                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: adaptiveFontSize(22, for: geometry), weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(
                            isSelected
                            ? (isPremium
                               ? LinearGradient(
                                   gradient: Gradient(colors: [Color.honeyGold, Color.honeyGold.opacity(0.8)]),
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing
                               )
                               : LinearGradient.primaryBrand)
                            : LinearGradient(
                                gradient: Gradient(colors: [Color.softPlum.opacity(0.6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                // Label
                Text(label)
                    .font(.system(size: adaptiveFontSize(11, for: geometry), weight: isSelected ? .semibold : .medium))
                    .foregroundColor(
                        isSelected
                        ? (isPremium ? Color.honeyGold : Color.blushPink)
                        : Color.softPlum.opacity(0.7)
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(isPressed ? 0.92 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
    }
}

#Preview {
    MainTabView(user: User(
        id: "preview-user",
        email: "john@example.com",
        name: "John Doe",
        profileImageURL: nil,
        provider: .guest,
        createdAt: Date()
    ))
}

