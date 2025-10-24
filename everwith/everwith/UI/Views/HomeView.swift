import SwiftUI

// Import required models and views
// User model is defined in AuthenticationModels.swift
// RestoreView and TogetherSceneView are in the same target
// Brand colors are defined in Assets.xcassets

enum NavigationDestination: Hashable {
    case restore
    case together
    case settings
    case myCreations
    case premium
    case credits
    case feedback
}

struct HomeView: View {
    let user: User
    @State private var navigationPath = NavigationPath()
    @State private var animateElements = false
    @State private var headerScale: CGFloat = 0.9
    @State private var welcomeCardOpacity: Double = 0
    @State private var restoreButtonScale: CGFloat = 0.9
    @State private var togetherButtonScale: CGFloat = 0.9
    @State private var buttonPressedRestore: Bool = false
    @State private var buttonPressedTogether: Bool = false
    @State private var recentImages: [ProcessedImage] = []
    @State private var isLoadingHistory = false
    @StateObject private var imageProcessingService = ImageProcessingService.shared
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { geometry in
                ZStack {
                    // Clean White Background with Subtle Gradient Band
                    CleanWhiteBackground()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .ignoresSafeArea(.all, edges: .all)
                
                VStack(spacing: 0) {
                    // Enhanced Header
                    ModernHomeHeader(user: user, geometry: geometry)
                        .scaleEffect(headerScale)
                        .opacity(animateElements ? 1 : 0)
                    
                    ScrollView {
                        VStack(spacing: adaptiveSpacing(16, for: geometry)) {
                            // Top spacing
                            Spacer()
                                .frame(height: adaptiveSpacing(16, for: geometry))
                            
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
                                        navigationPath.append(NavigationDestination.restore)
                                        buttonPressedRestore = false
                                    }
                                }) {
                                    HStack(spacing: adaptiveSpacing(12, for: geometry)) {
                                        // Gradient Icon
                                        Image(systemName: "photo.badge.plus")
                                            .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .semibold))
                                            .foregroundStyle(LinearGradient.primaryBrand)
                                            .frame(width: adaptiveSize(40, for: geometry), height: adaptiveSize(40, for: geometry))
                                            .background(
                                                Circle()
                                                    .fill(Color.pureWhite)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(LinearGradient.primaryBrand, lineWidth: 2)
                                                    )
                                            )
                                        
                                        VStack(alignment: .leading, spacing: adaptiveSpacing(4, for: geometry)) {
                                            Text("Photo Restore")
                                                .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .bold, design: .rounded))
                                                .foregroundStyle(LinearGradient.primaryBrand)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.8)
                                            
                                            Text("Make old photos HD again")
                                                .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .medium))
                                                .foregroundColor(.softPlum)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.9)
                                        }
                                        
                                        Spacer(minLength: adaptiveSpacing(8, for: geometry))
                                        
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .semibold))
                                            .foregroundStyle(LinearGradient.primaryBrand)
                                    }
                                    .padding(.horizontal, adaptivePadding(for: geometry))
                                    .padding(.vertical, adaptiveSpacing(16, for: geometry))
                                    .background(
                                        RoundedRectangle(cornerRadius: adaptiveCornerRadius(20, for: geometry))
                                            .fill(Color.pureWhite)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: adaptiveCornerRadius(20, for: geometry))
                                                    .stroke(LinearGradient.cardGlow, lineWidth: 1)
                                            )
                                            .shadow(
                                                color: Color.cardShadow,
                                                radius: buttonPressedRestore ? 8 : 12,
                                                x: 0,
                                                y: buttonPressedRestore ? 2 : 4
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .scaleEffect(buttonPressedRestore ? 0.96 : restoreButtonScale)
                                .opacity(animateElements ? 1 : 0)
                                .offset(x: animateElements ? 0 : -20)
                                
                                // Memory Merge Button
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        buttonPressedTogether = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        navigationPath.append(NavigationDestination.together)
                                        buttonPressedTogether = false
                                    }
                                }) {
                                    HStack(spacing: adaptiveSpacing(12, for: geometry)) {
                                        // Gradient Icon
                                        Image(systemName: "heart.circle.fill")
                                            .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .semibold))
                                            .foregroundStyle(LinearGradient.primaryBrand)
                                            .frame(width: adaptiveSize(40, for: geometry), height: adaptiveSize(40, for: geometry))
                                            .background(
                                                Circle()
                                                    .fill(Color.pureWhite)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(LinearGradient.primaryBrand, lineWidth: 2)
                                                    )
                                            )
                                        
                                        VStack(alignment: .leading, spacing: adaptiveSpacing(4, for: geometry)) {
                                            Text("Memory Merge")
                                                .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .bold, design: .rounded))
                                                .foregroundStyle(LinearGradient.primaryBrand)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.8)
                                            
                                            Text("Bring old memories together")
                                                .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .medium))
                                                .foregroundColor(.softPlum)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.9)
                                        }
                                        
                                        Spacer(minLength: adaptiveSpacing(8, for: geometry))
                                        
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .semibold))
                                            .foregroundStyle(LinearGradient.primaryBrand)
                                    }
                                    .padding(.horizontal, adaptivePadding(for: geometry))
                                    .padding(.vertical, adaptiveSpacing(16, for: geometry))
                                    .background(
                                        RoundedRectangle(cornerRadius: adaptiveCornerRadius(20, for: geometry))
                                            .fill(Color.pureWhite)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: adaptiveCornerRadius(20, for: geometry))
                                                    .stroke(LinearGradient.cardGlow, lineWidth: 1)
                                            )
                                            .shadow(
                                                color: Color.cardShadow,
                                                radius: buttonPressedTogether ? 8 : 12,
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
                            
                            // Recent Creations Section
                            if !recentImages.isEmpty {
                                VStack(alignment: .leading, spacing: adaptiveSpacing(16, for: geometry)) {
                                    Text("Recent Creations")
                                        .font(.system(size: adaptiveFontSize(20, for: geometry), weight: .bold, design: .rounded))
                                        .foregroundColor(.deepPlum)
                                        .padding(.horizontal, adaptivePadding(for: geometry))
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: adaptiveSpacing(12, for: geometry)) {
                                            ForEach(recentImages) { image in
                                                RecentImageCard(image: image, geometry: geometry)
                                            }
                                        }
                                        .padding(.horizontal, adaptivePadding(for: geometry))
                                    }
                                }
                                .padding(.top, adaptiveSpacing(16, for: geometry))
                                .opacity(animateElements ? 1 : 0)
                            }
                            
                            // Bottom spacing
                            Spacer()
                                .frame(height: adaptiveSpacing(12, for: geometry))
                        }
                        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom + 8 : 16)
                    }
                    .scrollIndicators(.hidden)
                    .frame(width: geometry.size.width)
                }
            }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .ignoresSafeArea(.all, edges: .all)
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .restore:
                    PhotoRestoreFlow()
                        .navigationBarBackButtonHidden(true)
                case .together:
                    MemoryMergeFlow()
                        .navigationBarBackButtonHidden(true)
                case .settings:
                    SettingsView()
                case .myCreations:
                    MyCreationsView()
                case .premium:
                    PaywallView(trigger: .general)
                case .credits:
                    CreditStoreView()
                case .feedback:
                    FeedbackView()
                }
            }
            .navigationBarHidden(true)
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
            
            // Load recent images
            loadRecentImages()
        }
    }
    
    // MARK: - Load Recent Images
    private func loadRecentImages() {
        Task {
            isLoadingHistory = true
            do {
                let history = try await imageProcessingService.fetchImageHistory(page: 1, pageSize: 10)
                await MainActor.run {
                    recentImages = history.images
                    isLoadingHistory = false
                    print("🏠 HomeView: Loaded \(recentImages.count) images")
                    for (index, image) in recentImages.enumerated() {
                        print("🏠 Image \(index + 1): Type=\(image.imageType ?? "nil"), URL=\(image.processedImageUrl != nil ? "valid" : "nil")")
                    }
                }
            } catch {
                print("❌ Failed to load image history: \(error)")
                await MainActor.run {
                    isLoadingHistory = false
                }
            }
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
                    Color.blushPink.opacity(0.4),
                    Color.roseMagenta.opacity(0.3),
                    Color.memoryViolet.opacity(0.25),
                    Color.lightBlush.opacity(0.2)
                ]),
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true), value: animateGradient)
            
            // Secondary animated gradient layer
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.roseMagenta.opacity(0.2),
                    Color.blushPink.opacity(0.15),
                    Color.memoryViolet.opacity(0.1),
                    Color.lightBlush.opacity(0.15)
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
                                [Color.blushPink, Color.roseMagenta, Color.memoryViolet, Color.lightBlush, Color.blushPink, Color.roseMagenta][index].opacity(animateColors ? 0.6 : 0.3),
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
                                [Color.roseMagenta, Color.blushPink, Color.memoryViolet, Color.lightBlush][index % 4].opacity(0.4),
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
    let geometry: GeometryProxy
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: adaptiveSpacing(6, for: geometry)) {
                HStack(spacing: adaptiveSpacing(8, for: geometry)) {
                    Text("Welcome back")
                        .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                        .foregroundColor(.softPlum)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .medium))
                        .foregroundStyle(LinearGradient.primaryBrand)
                }
                
                Text(user.name)
                    .font(.system(size: adaptiveFontSize(32, for: geometry), weight: .bold, design: .rounded))
                    .foregroundColor(.deepPlum)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            
            Spacer()
        }
        .padding(.horizontal, adaptivePadding(for: geometry))
        .padding(.top, geometry.safeAreaInsets.top > 0 ? geometry.safeAreaInsets.top + 32 : 42)
        .padding(.bottom, adaptiveSpacing(12, for: geometry))
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
                                Color.blushPink.opacity(0.2),
                                Color.roseMagenta.opacity(0.15)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: adaptiveSize(50, for: geometry), height: adaptiveSize(50, for: geometry))
                    .background(.ultraThinMaterial)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: adaptiveFontSize(20, for: geometry), weight: .medium))
                    .foregroundColor(.blushPink)
            }
            
            VStack(alignment: .leading, spacing: adaptiveSpacing(4, for: geometry)) {
                Text("Ready to create?")
                    .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .semibold, design: .rounded))
                    .foregroundColor(.deepPlum)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text("Choose how you'd like to relive your memories")
                    .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .medium))
                    .foregroundColor(.deepPlum.opacity(0.7))
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
            }
            
            Spacer()
        }
        .padding(adaptiveSpacing(16, for: geometry))
        .background(
            RoundedRectangle(cornerRadius: adaptiveCornerRadius(20, for: geometry))
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blushPink.opacity(0.12),
                            Color.roseMagenta.opacity(0.08),
                            Color.lightBlush.opacity(0.06)
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
                                    Color.blushPink.opacity(0.25),
                                    Color.roseMagenta.opacity(0.15)
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

// MARK: - Recent Image Card
struct RecentImageCard: View {
    let image: ProcessedImage
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(alignment: .leading, spacing: adaptiveSpacing(8, for: geometry)) {
            // Image Thumbnail
            AsyncImage(url: image.processedImageUrl.flatMap { URL(string: $0) }) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: adaptiveSize(140, for: geometry), height: adaptiveSize(180, for: geometry))
                        .overlay(
                            ProgressView()
                        )
                case .success(let loadedImage):
                    loadedImage
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: adaptiveSize(140, for: geometry), height: adaptiveSize(180, for: geometry))
                        .clipped()
                case .failure(let error):
                    Rectangle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: adaptiveSize(140, for: geometry), height: adaptiveSize(180, for: geometry))
                        .overlay(
                            VStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 20))
                                    .foregroundColor(.red)
                                Text("Failed to load")
                                    .font(.system(size: 10))
                                    .foregroundColor(.red)
                            }
                        )
                        .onAppear {
                            print("❌ Image load failed: \(error)")
                            print("❌ URL was: \(image.processedImageUrl ?? "nil")")
                        }
                @unknown default:
                    EmptyView()
                }
            }
            .cornerRadius(adaptiveCornerRadius(12, for: geometry))
            
            // Type Badge
            HStack(spacing: adaptiveSpacing(4, for: geometry)) {
                Image(systemName: image.icon)
                    .font(.system(size: adaptiveFontSize(10, for: geometry), weight: .semibold))
                Text(image.displayType)
                    .font(.system(size: adaptiveFontSize(11, for: geometry), weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, adaptiveSpacing(8, for: geometry))
            .padding(.vertical, adaptiveSpacing(4, for: geometry))
            .background(
                Capsule()
                    .fill(image.color)
            )
            
            // Date
            Text(formatDate(image.createdAt ?? Date()))
                .font(.system(size: adaptiveFontSize(12, for: geometry), weight: .regular))
                .foregroundColor(.deepPlum.opacity(0.6))
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
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
