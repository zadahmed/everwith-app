//
//  HomeView.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI

struct HomeView: View {
    let user: User
    @State private var projects: [Project] = Project.mockProjects
    @State private var scrollOffset: CGFloat = 0
    @State private var isTabBarExpanded = true
    
    private let tabBarHeight: CGFloat = 80
    private let collapsedTabBarHeight: CGFloat = 60
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.warmLinen.opacity(0.3),
                        Color.sky.opacity(0.1),
                        Color.honeyGold.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Header Section
                        HomeHeaderView(user: user)
                            .padding(.top, geometry.safeAreaInsets.top + ModernDesignSystem.Spacing.lg)
                        
                        // Hero Actions Section
                        HeroActionsSection()
                            .padding(.top, ModernDesignSystem.Spacing.xl)
                        
                        // Recent Projects Section
                        RecentProjectsSection(projects: projects)
                            .padding(.top, ModernDesignSystem.Spacing.xl)
                        
                        // Bottom spacing for tab bar
                        Spacer()
                            .frame(height: tabBarHeight + ModernDesignSystem.Spacing.lg)
                    }
                }
                .scrollIndicators(.hidden)
                .background(
                    GeometryReader { scrollGeometry in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: scrollGeometry.frame(in: .named("scroll")).minY)
                    }
                )
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isTabBarExpanded = scrollOffset > -50
                    }
                }
                .coordinateSpace(name: "scroll")
                
                // Dynamic Tab Bar
                VStack {
                    Spacer()
                    DynamicTabBar(isExpanded: isTabBarExpanded)
                        .frame(height: isTabBarExpanded ? tabBarHeight : collapsedTabBarHeight)
                }
            }
        }
        .ignoresSafeArea(.all)
    }
}

// MARK: - Home Header View
struct HomeHeaderView: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.sm) {
                    Text("Welcome back")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.charcoal.opacity(0.7))
                    
                    Text(user.name)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.charcoal)
                }
                
                Spacer()
                
                // Profile Image or Initials
                Circle()
                    .fill(Color.brandGradient)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(String(user.name.prefix(1)).uppercased())
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    )
                    .cleanGlassmorphism(
                        style: ModernDesignSystem.GlassEffect.subtle,
                        shadow: ModernDesignSystem.Shadow.light
                    )
            }
            
            Text("Together in every photo.")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(.charcoal.opacity(0.8))
                .padding(.top, ModernDesignSystem.Spacing.sm)
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
    }
}

// MARK: - Hero Actions Section
struct HeroActionsSection: View {
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            ForEach(HeroAction.actions) { action in
                HeroActionCard(action: action)
            }
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
    }
}

// MARK: - Hero Action Card
struct HeroActionCard: View {
    let action: HeroAction
    
    var body: some View {
        Button(action: action.action) {
            HStack(spacing: ModernDesignSystem.Spacing.lg) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: action.gradient),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: action.icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Content
                VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.sm) {
                    Text(action.title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.charcoal)
                    
                    Text(action.subtitle)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.charcoal.opacity(0.8))
                    
                    Text(action.description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.charcoal.opacity(0.6))
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "arrow.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.charcoal.opacity(0.6))
            }
            .padding(ModernDesignSystem.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.lg)
                    .fill(Color.white.opacity(0.1))
                    .background(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.lg)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(0.05),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recent Projects Section
struct RecentProjectsSection: View {
    let projects: [Project]
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.lg) {
            HStack {
                Text("Recent Projects")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.charcoal)
                
                Spacer()
                
                Button("View All") {
                    // Handle view all action
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.honeyGold)
            }
            .padding(.horizontal, ModernDesignSystem.Spacing.lg)
            
            if projects.isEmpty {
                EmptyProjectsView()
            } else {
                LazyVStack(spacing: ModernDesignSystem.Spacing.md) {
                    ForEach(projects) { project in
                        ProjectCard(project: project)
                    }
                }
                .padding(.horizontal, ModernDesignSystem.Spacing.lg)
            }
        }
    }
}

// MARK: - Project Card
struct ProjectCard: View {
    let project: Project
    
    var body: some View {
        HStack(spacing: ModernDesignSystem.Spacing.md) {
            // Thumbnail placeholder
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                .fill(Color.charcoal.opacity(0.1))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: project.type.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.charcoal.opacity(0.6))
                )
            
            // Content
            VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.xs) {
                Text(project.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.charcoal)
                    .lineLimit(1)
                
                if let description = project.description {
                    Text(description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.charcoal.opacity(0.6))
                        .lineLimit(1)
                }
                
                Text(project.updatedAt, style: .relative)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.charcoal.opacity(0.5))
            }
            
            Spacer()
            
            // Status Pill
            Text(project.status.displayName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(project.status.color)
                .padding(.horizontal, ModernDesignSystem.Spacing.sm)
                .padding(.vertical, ModernDesignSystem.Spacing.xs)
                .background(project.status.backgroundColor)
                .cornerRadius(ModernDesignSystem.CornerRadius.sm)
        }
        .padding(ModernDesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                .fill(Color.white.opacity(0.05))
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Empty Projects View
struct EmptyProjectsView: View {
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            // Soft illustration
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.honeyGold.opacity(0.2),
                                Color.sky.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(.charcoal.opacity(0.6))
            }
            
            VStack(spacing: ModernDesignSystem.Spacing.md) {
                Text("Bring an old photo into today.")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.charcoal)
                    .multilineTextAlignment(.center)
                
                Text("Start by uploading a photo to restore or create your first tribute.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.charcoal.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(ModernDesignSystem.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.lg)
                .fill(Color.white.opacity(0.05))
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.lg)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
    }
}

// MARK: - Dynamic Tab Bar
struct DynamicTabBar: View {
    let isExpanded: Bool
    
    var body: some View {
        HStack(spacing: ModernDesignSystem.Spacing.lg) {
            TabBarItem(
                icon: "house.fill",
                title: "Home",
                isSelected: true,
                isExpanded: isExpanded
            )
            
            TabBarItem(
                icon: "photo.badge.plus",
                title: "Restore",
                isSelected: false,
                isExpanded: isExpanded
            )
            
            TabBarItem(
                icon: "heart.circle",
                title: "Together",
                isSelected: false,
                isExpanded: isExpanded
            )
            
            TabBarItem(
                icon: "person.circle",
                title: "Profile",
                isSelected: false,
                isExpanded: isExpanded
            )
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
        .padding(.vertical, ModernDesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.lg)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.lg)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(0.05),
            radius: 8,
            x: 0,
            y: -2
        )
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
        .padding(.bottom, ModernDesignSystem.Spacing.lg)
    }
}

// MARK: - Tab Bar Item
struct TabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let isExpanded: Bool
    
    var body: some View {
        Button(action: {
            // Handle tab selection
        }) {
            HStack(spacing: isExpanded ? ModernDesignSystem.Spacing.sm : 0) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .honeyGold : .charcoal.opacity(0.6))
                
                if isExpanded {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isSelected ? .honeyGold : .charcoal.opacity(0.6))
                }
            }
            .padding(.horizontal, isExpanded ? ModernDesignSystem.Spacing.md : ModernDesignSystem.Spacing.sm)
            .padding(.vertical, ModernDesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                    .fill(isSelected ? Color.honeyGold.opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    HomeView(user: User(
        id: "preview",
        email: "user@example.com",
        name: "John Doe",
        profileImageURL: nil,
        provider: .apple,
        createdAt: Date()
    ))
}