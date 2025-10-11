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
    @State private var showPhotoPicker = false
    @State private var showTogetherPicker = false
    @State private var showSettings = false
    @State private var selectedRestorePhotos: [ImportedPhoto] = []
    @State private var selectedTogetherPhotos: [ImportedPhoto] = []
    @State private var animateElements = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Vibrant Modern Background
                ModernVibrantBackground()
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Enhanced Header
                    ModernHomeHeader(user: user, showSettings: $showSettings, geometry: geometry)
                        .padding(.top, geometry.safeAreaInsets.top + ResponsiveDesign.adaptiveSpacing(baseSpacing: 16, for: geometry))
                    
                    ScrollView {
                        VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 28, for: geometry)) {
                            // Welcome Message
                            WelcomeMessageCard(geometry: geometry)
                                .padding(.horizontal, ResponsiveDesign.adaptiveSpacing(baseSpacing: 24, for: geometry))
                                .padding(.top, ResponsiveDesign.adaptiveSpacing(baseSpacing: 20, for: geometry))
                            
                            // Main Action Buttons
                            VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 20, for: geometry)) {
                                // Restore Photo Button
                                ModernActionButton(
                                    title: "Restore a Photo",
                                    subtitle: "Bring memories back to life",
                                    icon: "photo.badge.plus",
                                    gradient: [Color.honeyGold, Color.honeyGold.opacity(0.7)],
                                    accentColor: Color.honeyGold,
                                    geometry: geometry,
                                    action: {
                                        showPhotoPicker = true
                                    }
                                )
                                
                                // Together Scene Button
                                ModernActionButton(
                                    title: "Together Scene",
                                    subtitle: "Create beautiful tributes",
                                    icon: "heart.circle.fill",
                                    gradient: [Color.sky, Color.fern],
                                    accentColor: Color.sky,
                                    geometry: geometry,
                                    action: {
                                        showTogetherPicker = true
                                    }
                                )
                            }
                            .padding(.horizontal, ResponsiveDesign.adaptiveSpacing(baseSpacing: 24, for: geometry))
                            
                            // Quick Stats Card
                            QuickStatsCard(geometry: geometry)
                                .padding(.horizontal, ResponsiveDesign.adaptiveSpacing(baseSpacing: 24, for: geometry))
                            
                            // Recent Projects Section
                            if !projects.isEmpty {
                                ModernRecentProjectsRow(projects: Array(projects.prefix(3)), geometry: geometry)
                                    .padding(.horizontal, ResponsiveDesign.adaptiveSpacing(baseSpacing: 24, for: geometry))
                            }
                            
                            // Bottom spacing
                            Spacer()
                                .frame(height: geometry.safeAreaInsets.bottom + ResponsiveDesign.adaptiveSpacing(baseSpacing: 32, for: geometry))
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                animateElements = true
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPickerView(mode: .restore, selectedPhotos: $selectedRestorePhotos)
        }
        .sheet(isPresented: $showTogetherPicker) {
            PhotoPickerView(mode: .togetherScene, selectedPhotos: $selectedTogetherPhotos)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

// MARK: - Modern Vibrant Background
struct ModernVibrantBackground: View {
    @State private var animateGradient = false
    @State private var animateOrbs = false
    
    var body: some View {
        ZStack {
            // Dynamic gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.honeyGold.opacity(0.15),
                    Color.sky.opacity(0.12),
                    Color.fern.opacity(0.08),
                    Color.warmLinen.opacity(0.3)
                ]),
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 6.0).repeatForever(autoreverses: true), value: animateGradient)
            
            // Floating gradient orbs
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                [Color.honeyGold, Color.sky, Color.fern, Color.softBlush][index].opacity(0.2),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: CGFloat(100 + index * 60), height: CGFloat(100 + index * 60))
                    .offset(
                        x: animateOrbs ? CGFloat(-50 + index * 100) : CGFloat(50 + index * 80),
                        y: animateOrbs ? CGFloat(-80 + index * 120) : CGFloat(-120 + index * 100)
                    )
                    .blur(radius: 25)
                    .opacity(0.4)
            }
            
            // Subtle overlay for better text readability
            Rectangle()
                .fill(Color.white.opacity(0.02))
                .ignoresSafeArea()
        }
        .onAppear {
            animateGradient = true
            withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true).delay(Double.random(in: 0...2))) {
                animateOrbs = true
            }
        }
    }
}

// MARK: - Modern Home Header
struct ModernHomeHeader: View {
    let user: User
    @Binding var showSettings: Bool
    let geometry: GeometryProxy
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 6, for: geometry)) {
                HStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry)) {
                    Text("Welcome back")
                        .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 16, for: geometry), weight: .medium))
                        .foregroundColor(.charcoal.opacity(0.8))
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 14, for: geometry), weight: .medium))
                        .foregroundColor(.honeyGold)
                }
                
                Text(user.name)
                    .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 32, for: geometry), weight: .bold, design: .rounded))
                    .foregroundColor(.charcoal)
            }
            
            Spacer()
            
            // Enhanced Settings Button
            Button(action: {
                showSettings = true
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.honeyGold.opacity(0.15),
                                    Color.sky.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(
                            width: ResponsiveDesign.adaptiveSpacing(baseSpacing: 44, for: geometry),
                            height: ResponsiveDesign.adaptiveSpacing(baseSpacing: 44, for: geometry)
                        )
                        .background(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.honeyGold.opacity(0.3),
                                            Color.sky.opacity(0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                    
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 18, for: geometry), weight: .medium))
                        .foregroundColor(.charcoal.opacity(0.8))
                }
            }
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 0.1), value: showSettings)
        }
        .padding(.horizontal, ResponsiveDesign.adaptiveSpacing(baseSpacing: 24, for: geometry))
        .padding(.bottom, ResponsiveDesign.adaptiveSpacing(baseSpacing: 16, for: geometry))
    }
}

// MARK: - Welcome Message Card
struct WelcomeMessageCard: View {
    let geometry: GeometryProxy
    
    var body: some View {
        HStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 16, for: geometry)) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.honeyGold.opacity(0.2),
                                Color.sky.opacity(0.15)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(
                        width: ResponsiveDesign.adaptiveSpacing(baseSpacing: 50, for: geometry),
                        height: ResponsiveDesign.adaptiveSpacing(baseSpacing: 50, for: geometry)
                    )
                    .background(.ultraThinMaterial)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 20, for: geometry), weight: .medium))
                    .foregroundColor(.honeyGold)
            }
            
            VStack(alignment: .leading, spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 4, for: geometry)) {
                Text("Ready to create?")
                    .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 18, for: geometry), weight: .semibold, design: .rounded))
                    .foregroundColor(.charcoal)
                
                Text("Choose how you'd like to honor your memories")
                    .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 14, for: geometry), weight: .medium))
                    .foregroundColor(.charcoal.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(ResponsiveDesign.adaptiveSpacing(baseSpacing: 20, for: geometry))
        .background(
            RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 20, for: geometry))
                .fill(Color.white.opacity(0.08))
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 20, for: geometry))
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.honeyGold.opacity(0.2),
                                    Color.sky.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: Color.black.opacity(0.05),
            radius: ResponsiveDesign.adaptiveSpacing(baseSpacing: 10, for: geometry),
            x: 0,
            y: ResponsiveDesign.adaptiveSpacing(baseSpacing: 4, for: geometry)
        )
    }
}

// MARK: - Modern Action Button
struct ModernActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: [Color]
    let accentColor: Color
    let geometry: GeometryProxy
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var animateGlow = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 20, for: geometry)) {
                // Enhanced Icon with Glow
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    accentColor.opacity(animateGlow ? 0.4 : 0.2),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: ResponsiveDesign.adaptiveSpacing(baseSpacing: 60, for: geometry)
                            )
                        )
                        .frame(
                            width: ResponsiveDesign.adaptiveSpacing(baseSpacing: 120, for: geometry),
                            height: ResponsiveDesign.adaptiveSpacing(baseSpacing: 120, for: geometry)
                        )
                        .blur(radius: ResponsiveDesign.adaptiveSpacing(baseSpacing: 25, for: geometry))
                    
                    // Main icon circle
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: gradient),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(
                            width: ResponsiveDesign.adaptiveSpacing(baseSpacing: 70, for: geometry),
                            height: ResponsiveDesign.adaptiveSpacing(baseSpacing: 70, for: geometry)
                        )
                        .overlay(
                            Image(systemName: icon)
                                .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 28, for: geometry), weight: .medium))
                                .foregroundColor(.white)
                        )
                        .shadow(
                            color: accentColor.opacity(0.3),
                            radius: ResponsiveDesign.adaptiveSpacing(baseSpacing: 15, for: geometry),
                            x: 0,
                            y: ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry)
                        )
                }
                
                // Content
                VStack(alignment: .leading, spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 6, for: geometry)) {
                    Text(title)
                        .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 22, for: geometry), weight: .bold, design: .rounded))
                        .foregroundColor(.charcoal)
                    
                    Text(subtitle)
                        .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 15, for: geometry), weight: .medium))
                        .foregroundColor(.charcoal.opacity(0.8))
                }
                
                Spacer()
                
                // Enhanced Arrow
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.1))
                        .frame(
                            width: ResponsiveDesign.adaptiveSpacing(baseSpacing: 32, for: geometry),
                            height: ResponsiveDesign.adaptiveSpacing(baseSpacing: 32, for: geometry)
                        )
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 16, for: geometry), weight: .semibold))
                        .foregroundColor(accentColor)
                }
            }
            .padding(ResponsiveDesign.adaptiveSpacing(baseSpacing: 24, for: geometry))
            .background(
                RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 24, for: geometry))
                    .fill(Color.white.opacity(0.12))
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 24, for: geometry))
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        accentColor.opacity(0.3),
                                        Color.clear
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: Color.black.opacity(0.08),
                radius: ResponsiveDesign.adaptiveSpacing(baseSpacing: 20, for: geometry),
                x: 0,
                y: ResponsiveDesign.adaptiveSpacing(baseSpacing: 10, for: geometry)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateGlow = true
            }
        }
    }
}

// MARK: - Quick Stats Card
struct QuickStatsCard: View {
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 16, for: geometry)) {
            HStack {
                Text("Your Journey")
                    .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 18, for: geometry), weight: .semibold, design: .rounded))
                    .foregroundColor(.charcoal)
                
                Spacer()
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 16, for: geometry), weight: .medium))
                    .foregroundColor(.honeyGold)
            }
            
            HStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 20, for: geometry)) {
                StatItem(
                    icon: "photo.fill",
                    value: "12",
                    label: "Photos Restored",
                    color: Color.honeyGold,
                    geometry: geometry
                )
                
                StatItem(
                    icon: "heart.fill",
                    value: "8",
                    label: "Tributes Created",
                    color: Color.sky,
                    geometry: geometry
                )
                
                StatItem(
                    icon: "star.fill",
                    value: "4.9",
                    label: "Rating",
                    color: Color.fern,
                    geometry: geometry
                )
            }
        }
        .padding(ResponsiveDesign.adaptiveSpacing(baseSpacing: 20, for: geometry))
        .background(
            RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 20, for: geometry))
                .fill(Color.white.opacity(0.08))
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 20, for: geometry))
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.honeyGold.opacity(0.2),
                                    Color.sky.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: Color.black.opacity(0.05),
            radius: ResponsiveDesign.adaptiveSpacing(baseSpacing: 10, for: geometry),
            x: 0,
            y: ResponsiveDesign.adaptiveSpacing(baseSpacing: 4, for: geometry)
        )
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 6, for: geometry)) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(
                        width: ResponsiveDesign.adaptiveSpacing(baseSpacing: 40, for: geometry),
                        height: ResponsiveDesign.adaptiveSpacing(baseSpacing: 40, for: geometry)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 16, for: geometry), weight: .medium))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 18, for: geometry), weight: .bold, design: .rounded))
                .foregroundColor(.charcoal)
            
            Text(label)
                .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 12, for: geometry), weight: .medium))
                .foregroundColor(.charcoal.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Modern Recent Projects Row
struct ModernRecentProjectsRow: View {
    let projects: [Project]
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(alignment: .leading, spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 16, for: geometry)) {
            HStack {
                Text("Recent Projects")
                    .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 20, for: geometry), weight: .semibold, design: .rounded))
                    .foregroundColor(.charcoal)
                
                Spacer()
                
                Button(action: {
                    // Handle view all action
                }) {
                    HStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 4, for: geometry)) {
                        Text("View All")
                            .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 14, for: geometry), weight: .medium))
                            .foregroundColor(.honeyGold)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 12, for: geometry), weight: .medium))
                            .foregroundColor(.honeyGold)
                    }
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 16, for: geometry)) {
                    ForEach(projects) { project in
                        ModernProjectCard(project: project, geometry: geometry)
                    }
                }
                .padding(.horizontal, ResponsiveDesign.adaptiveSpacing(baseSpacing: 4, for: geometry))
            }
        }
    }
}

// MARK: - Modern Project Card
struct ModernProjectCard: View {
    let project: Project
    let geometry: GeometryProxy
    
    var body: some View {
        Button(action: {
            // Handle project tap
        }) {
            VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 12, for: geometry)) {
                // Enhanced Thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 16, for: geometry))
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.honeyGold.opacity(0.15),
                                    Color.sky.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(
                            width: ResponsiveDesign.adaptiveSpacing(baseSpacing: 90, for: geometry),
                            height: ResponsiveDesign.adaptiveSpacing(baseSpacing: 90, for: geometry)
                        )
                        .background(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 16, for: geometry))
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.honeyGold.opacity(0.3),
                                            Color.sky.opacity(0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                    
                    Image(systemName: project.type.icon)
                        .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 28, for: geometry), weight: .medium))
                        .foregroundColor(.honeyGold)
                }
                
                // Enhanced Content
                VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 4, for: geometry)) {
                    Text(project.title)
                        .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 14, for: geometry), weight: .semibold))
                        .foregroundColor(.charcoal)
                        .lineLimit(1)
                    
                    Text(project.updatedAt, style: .relative)
                        .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 12, for: geometry), weight: .medium))
                        .foregroundColor(.charcoal.opacity(0.6))
                }
            }
            .frame(width: ResponsiveDesign.adaptiveSpacing(baseSpacing: 110, for: geometry))
            .padding(ResponsiveDesign.adaptiveSpacing(baseSpacing: 12, for: geometry))
            .background(
                RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 20, for: geometry))
                    .fill(Color.white.opacity(0.08))
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 20, for: geometry))
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.honeyGold.opacity(0.2),
                                        Color.sky.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: Color.black.opacity(0.05),
                radius: ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry),
                x: 0,
                y: ResponsiveDesign.adaptiveSpacing(baseSpacing: 4, for: geometry)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Settings content would go here
                Text("Settings")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.charcoal)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(ModernButtonStyle(style: .primary))
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .background(Color.warmLinen)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
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