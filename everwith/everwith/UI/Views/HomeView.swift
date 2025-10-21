import SwiftUI

struct HomeView: View {
    let user: User
    @State private var showPhotoPicker = false
    @State private var showTogetherPicker = false
    @State private var showSettings = false
    @State private var selectedRestorePhotos: [ImportedPhoto] = []
    @State private var selectedTogetherPhotos: [ImportedPhoto] = []
    @State private var animateElements = false
    @State private var headerScale: CGFloat = 0.9
    @State private var welcomeCardOpacity: Double = 0
    @State private var restoreButtonScale: CGFloat = 0.9
    @State private var togetherButtonScale: CGFloat = 0.9
    @State private var buttonPressedRestore: Bool = false
    @State private var buttonPressedTogether: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Vibrant Modern Background
                ModernVibrantBackground()
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Enhanced Header
                    ModernHomeHeader(user: user, showSettings: $showSettings, geometry: geometry)
                        .scaleEffect(headerScale)
                        .opacity(animateElements ? 1 : 0)
                    
                    ScrollView {
                        VStack(spacing: adaptiveSpacing(16, for: geometry)) {
                            // Welcome Message
                            WelcomeMessageCard(geometry: geometry)
                                .padding(.horizontal, adaptivePadding(for: geometry))
                                .opacity(welcomeCardOpacity)
                                .offset(y: animateElements ? 0 : 20)
                            
                            // Simple Action Buttons
                            VStack(spacing: adaptiveSpacing(12, for: geometry)) {
                                // Restore Photo Button
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        buttonPressedRestore = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        showPhotoPicker = true
                                        buttonPressedRestore = false
                                    }
                                }) {
                                    HStack(spacing: adaptiveSpacing(10, for: geometry)) {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                                            .foregroundColor(.white)
                                            .frame(width: adaptiveSize(32, for: geometry), height: adaptiveSize(32, for: geometry))
                                            .background(
                                                Circle()
                                                    .fill(Color.honeyGold.opacity(0.8))
                                            )
                                        
                                        VStack(alignment: .leading, spacing: adaptiveSpacing(3, for: geometry)) {
                                            Text("Restore a Photo")
                                                .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .bold, design: .rounded))
                                                .foregroundColor(.charcoal)
                                            
                                            Text("Bring memories back to life")
                                                .font(.system(size: adaptiveFontSize(12, for: geometry), weight: .medium))
                                                .foregroundColor(.charcoal.opacity(0.8))
                                                .lineLimit(1)
                                        }
                                        
                                        Spacer(minLength: adaptiveSpacing(6, for: geometry))
                                        
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: adaptiveFontSize(10, for: geometry), weight: .semibold))
                                            .foregroundColor(.honeyGold)
                                            .frame(width: adaptiveSize(18, for: geometry), height: adaptiveSize(18, for: geometry))
                                    }
                                    .padding(.horizontal, adaptivePadding(for: geometry))
                                    .padding(.vertical, adaptiveSpacing(12, for: geometry))
                                    .background(
                                        RoundedRectangle(cornerRadius: adaptiveCornerRadius(14, for: geometry))
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
                                            .background(.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: adaptiveCornerRadius(14, for: geometry))
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
                                            .shadow(
                                                color: Color.honeyGold.opacity(buttonPressedRestore ? 0.1 : 0.2),
                                                radius: buttonPressedRestore ? 4 : 8,
                                                x: 0,
                                                y: buttonPressedRestore ? 2 : 4
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .scaleEffect(buttonPressedRestore ? 0.96 : restoreButtonScale)
                                .opacity(animateElements ? 1 : 0)
                                .offset(x: animateElements ? 0 : -20)
                                
                                // Together Scene Button
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        buttonPressedTogether = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        showTogetherPicker = true
                                        buttonPressedTogether = false
                                    }
                                }) {
                                    HStack(spacing: adaptiveSpacing(10, for: geometry)) {
                                        Image(systemName: "heart.circle.fill")
                                            .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                                            .foregroundColor(.white)
                                            .frame(width: adaptiveSize(32, for: geometry), height: adaptiveSize(32, for: geometry))
                                            .background(
                                                Circle()
                                                    .fill(Color.sky.opacity(0.8))
                                            )
                                        
                                        VStack(alignment: .leading, spacing: adaptiveSpacing(3, for: geometry)) {
                                            Text("Together Scene")
                                                .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .bold, design: .rounded))
                                                .foregroundColor(.charcoal)
                                            
                                            Text("Create beautiful tributes")
                                                .font(.system(size: adaptiveFontSize(12, for: geometry), weight: .medium))
                                                .foregroundColor(.charcoal.opacity(0.8))
                                                .lineLimit(1)
                                        }
                                        
                                        Spacer(minLength: adaptiveSpacing(6, for: geometry))
                                        
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: adaptiveFontSize(10, for: geometry), weight: .semibold))
                                            .foregroundColor(.sky)
                                            .frame(width: adaptiveSize(18, for: geometry), height: adaptiveSize(18, for: geometry))
                                    }
                                    .padding(.horizontal, adaptivePadding(for: geometry))
                                    .padding(.vertical, adaptiveSpacing(12, for: geometry))
                                    .background(
                                        RoundedRectangle(cornerRadius: adaptiveCornerRadius(14, for: geometry))
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.sky.opacity(0.15),
                                                        Color.fern.opacity(0.1)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .background(.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: adaptiveCornerRadius(14, for: geometry))
                                                    .stroke(
                                                        LinearGradient(
                                                            gradient: Gradient(colors: [
                                                                Color.sky.opacity(0.3),
                                                                Color.fern.opacity(0.2)
                                                            ]),
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        ),
                                                        lineWidth: 1
                                                    )
                                            )
                                            .shadow(
                                                color: Color.sky.opacity(buttonPressedTogether ? 0.1 : 0.2),
                                                radius: buttonPressedTogether ? 4 : 8,
                                                x: 0,
                                                y: buttonPressedTogether ? 2 : 4
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .scaleEffect(buttonPressedTogether ? 0.96 : togetherButtonScale)
                                .opacity(animateElements ? 1 : 0)
                                .offset(x: animateElements ? 0 : -20)
                            }
                            .padding(.horizontal, adaptivePadding(for: geometry))
                            
                            // Bottom spacing
                            Spacer()
                                .frame(height: adaptiveSpacing(24, for: geometry))
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
        .onAppear {
            // Staggered entrance animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                headerScale = 1.0
                animateElements = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                welcomeCardOpacity = 1.0
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.3)) {
                restoreButtonScale = 1.0
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.4)) {
                togetherButtonScale = 1.0
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPickerView(mode: .restore, selectedPhotos: $selectedRestorePhotos)
        }
        .sheet(isPresented: $showTogetherPicker) {
            PhotoPickerView(mode: .togetherScene, selectedPhotos: $selectedTogetherPhotos)
        }
        .sheet(isPresented: $showSettings) {
            // Placeholder for SettingsView - to be implemented
            Text("Settings Coming Soon")
                .font(.title)
                .padding()
        }
    }
    
    // MARK: - Adaptive Sizing Functions
    private func adaptivePadding(for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        // iPhone SE (375pt) = 12pt, iPhone 15 Pro (393pt) = 14pt, iPhone 15 Pro Max (430pt) = 16pt
        return max(12, min(16, screenWidth * 0.04))
    }
    
    private func adaptiveSpacing(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0 // Base on iPhone SE
        return base * scaleFactor
    }
    
    private func adaptiveFontSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0 // Base on iPhone SE
        return max(base * 0.9, min(base * 1.1, base * scaleFactor))
    }
    
    private func adaptiveSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0 // Base on iPhone SE
        return base * scaleFactor
    }
    
    private func adaptiveCornerRadius(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0 // Base on iPhone SE
        return base * scaleFactor
    }
}

// MARK: - Modern Vibrant Background
struct ModernVibrantBackground: View {
    @State private var animateGradient = false
    @State private var animateOrbs = false
    @State private var animateColors = false
    
    var body: some View {
        ZStack {
            // Base vibrant gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.honeyGold.opacity(0.4),
                    Color.sky.opacity(0.3),
                    Color.fern.opacity(0.25),
                    Color.softBlush.opacity(0.2)
                ]),
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true), value: animateGradient)
            
            // Secondary animated gradient layer
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.sky.opacity(0.2),
                    Color.honeyGold.opacity(0.15),
                    Color.fern.opacity(0.1),
                    Color.softBlush.opacity(0.15)
                ]),
                startPoint: animateGradient ? .bottomLeading : .topTrailing,
                endPoint: animateGradient ? .topTrailing : .bottomLeading
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 6.0).repeatForever(autoreverses: true), value: animateGradient)
            .opacity(0.7)
            
            // Dynamic floating orbs with more vibrant colors
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                [Color.honeyGold, Color.sky, Color.fern, Color.softBlush, Color.honeyGold, Color.sky][index].opacity(animateColors ? 0.6 : 0.3),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .frame(width: CGFloat(80 + index * 80), height: CGFloat(80 + index * 80))
                    .offset(
                        x: animateOrbs ? CGFloat(-100 + index * 120) : CGFloat(100 + index * 100),
                        y: animateOrbs ? CGFloat(-150 + index * 150) : CGFloat(-200 + index * 120)
                    )
                    .blur(radius: 30)
                    .opacity(0.6)
            }
            
            // Additional smaller animated particles
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                [Color.sky, Color.honeyGold, Color.fern, Color.softBlush][index % 4].opacity(0.4),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: CGFloat(30 + index * 20), height: CGFloat(30 + index * 20))
                    .offset(
                        x: animateOrbs ? CGFloat(-200 + index * 80) : CGFloat(200 + index * 60),
                        y: animateOrbs ? CGFloat(-300 + index * 100) : CGFloat(-400 + index * 80)
                    )
                    .blur(radius: 15)
                    .opacity(0.5)
            }
            
            // Subtle overlay for text readability (much less white)
            Rectangle()
                .fill(Color.black.opacity(0.05))
                .ignoresSafeArea()
        }
        .onAppear {
            animateGradient = true
            withAnimation(.easeInOut(duration: 10.0).repeatForever(autoreverses: true).delay(Double.random(in: 0...3))) {
                animateOrbs = true
            }
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true).delay(Double.random(in: 0...2))) {
                animateColors = true
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
            VStack(alignment: .leading, spacing: adaptiveSpacing(6, for: geometry)) {
                HStack(spacing: adaptiveSpacing(8, for: geometry)) {
                    Text("Welcome back")
                        .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                        .foregroundColor(.charcoal.opacity(0.8))
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .medium))
                        .foregroundColor(.honeyGold)
                }
                
                Text(user.name)
                    .font(.system(size: adaptiveFontSize(32, for: geometry), weight: .bold, design: .rounded))
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
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: adaptiveSize(44, for: geometry), height: adaptiveSize(44, for: geometry))
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
                        .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .medium))
                        .foregroundColor(.charcoal.opacity(0.8))
                }
            }
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 0.1), value: showSettings)
        }
        .padding(.horizontal, adaptivePadding(for: geometry))
        .padding(.bottom, adaptiveSpacing(16, for: geometry))
    }
    
    // MARK: - Adaptive Functions
    private func adaptivePadding(for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        return max(12, min(16, screenWidth * 0.04))
    }
    
    private func adaptiveSpacing(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
    
    private func adaptiveFontSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return max(base * 0.9, min(base * 1.1, base * scaleFactor))
    }
    
    private func adaptiveSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
}

// MARK: - Welcome Message Card
struct WelcomeMessageCard: View {
    let geometry: GeometryProxy
    
    var body: some View {
        HStack(spacing: adaptiveSpacing(16, for: geometry)) {
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
                    .frame(width: adaptiveSize(50, for: geometry), height: adaptiveSize(50, for: geometry))
                    .background(.ultraThinMaterial)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: adaptiveFontSize(20, for: geometry), weight: .medium))
                    .foregroundColor(.honeyGold)
            }
            
            VStack(alignment: .leading, spacing: adaptiveSpacing(4, for: geometry)) {
                Text("Ready to create?")
                    .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .semibold, design: .rounded))
                    .foregroundColor(.charcoal)
                
                Text("Choose how you'd like to honor your memories")
                    .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .medium))
                    .foregroundColor(.charcoal.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(adaptiveSpacing(16, for: geometry))
        .background(
            RoundedRectangle(cornerRadius: adaptiveCornerRadius(20, for: geometry))
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.honeyGold.opacity(0.12),
                            Color.sky.opacity(0.08),
                            Color.softBlush.opacity(0.06)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: adaptiveCornerRadius(20, for: geometry))
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.honeyGold.opacity(0.25),
                                    Color.sky.opacity(0.15)
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
            radius: adaptiveSpacing(10, for: geometry),
            x: 0,
            y: adaptiveSpacing(4, for: geometry)
        )
    }
    
    // MARK: - Adaptive Functions
    private func adaptiveSpacing(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
    
    private func adaptiveFontSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return max(base * 0.9, min(base * 1.1, base * scaleFactor))
    }
    
    private func adaptiveSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
    
    private func adaptiveCornerRadius(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
}

#Preview {
    HomeView(user: User(
        id: "preview-user",
        email: "john@example.com",
        name: "John Doe",
        profileImageURL: nil,
        provider: .guest,
        createdAt: Date()
    ))
}