import SwiftUI

// Import required models and views
// User model is defined in AuthenticationModels.swift
// RestoreView and TogetherSceneView are in the same target
// Brand colors are defined in Assets.xcassets

enum NavigationDestination: Hashable {
    case restore
    case together
    case timeline
    case celebrity
    case reunite
    case family
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
    @State private var cardOpacity: Double = 0
    @State private var buttonPressedRestore: Bool = false
    @State private var buttonPressedTogether: Bool = false
    @State private var recentImages: [ProcessedImage] = []
    @State private var isLoadingHistory = false
    @StateObject private var imageProcessingService = ImageProcessingService.shared
    @State private var carouselOffset: CGFloat = 0
    @State private var galleryTimer: Timer?
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { geometry in
                ZStack {
                    // Clean White Background
                    CleanWhiteBackground()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .ignoresSafeArea(.all, edges: .all)
                
                VStack(spacing: 0) {
                    // Scrollable Content
                    ScrollView {
                        VStack(spacing: 0) {
                            // Header with Trust Bar
                            ModernHomeHeader3(user: user, geometry: geometry)
                                .scaleEffect(headerScale)
                                .opacity(animateElements ? 1 : 0)
                                .padding(.top, adaptiveSpacing(8, for: geometry))
                            
                            // Section: Get Started
                            VStack(alignment: .leading, spacing: adaptiveSpacing(8, for: geometry)) {
                                Text("Get Started")
                                    .font(.system(size: adaptiveFontSize(20, for: geometry), weight: .bold, design: .rounded))
                                    .foregroundColor(.deepPlum)
                                    .padding(.horizontal, adaptivePadding(for: geometry))
                                
                                Text("Choose how you'd like to transform your memories")
                                    .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .medium))
                                    .foregroundColor(.softPlum)
                                    .padding(.horizontal, adaptivePadding(for: geometry))
                            }
                            .padding(.top, adaptiveSpacing(24, for: geometry))
                            .opacity(cardOpacity)
                            
                            // Main Feature Cards
                        VStack(spacing: adaptiveSpacing(16, for: geometry)) {
                                    // Photo Restore Card
                                    FeatureCard3(
                                        title: "Photo Restore",
                                        subtitle: "Make old photos HD again",
                                        icon: "photo.badge.plus",
                                        imageName: "restore_image",
                                        isPressed: buttonPressedRestore,
                                        geometry: geometry,
                                        action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        buttonPressedRestore = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        navigationPath.append(NavigationDestination.restore)
                                        buttonPressedRestore = false
                                            }
                                        }
                                    )
                                    
                                    // Memory Merge Card
                                    FeatureCard3(
                                        title: "Memory Merge",
                                        subtitle: "Bring old memories together",
                                        icon: "heart.circle.fill",
                                        imageName: "together_image",
                                        isPressed: buttonPressedTogether,
                                        geometry: geometry,
                                        action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        buttonPressedTogether = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        navigationPath.append(NavigationDestination.together)
                                        buttonPressedTogether = false
                                            }
                                        }
                                    )
                            }
                            .padding(.horizontal, adaptivePadding(for: geometry))
                                .padding(.top, adaptiveSpacing(24, for: geometry))
                                .opacity(cardOpacity)
                                
                                // Explore AI Magic Carousel
                                ExploreAICarousel(geometry: geometry, navigationPath: $navigationPath)
                                    .padding(.top, adaptiveSpacing(32, for: geometry))
                                    .opacity(cardOpacity)
                                
                                // Section: Go Premium
                                VStack(alignment: .leading, spacing: adaptiveSpacing(8, for: geometry)) {
                                    Text("Go Premium")
                                        .font(.system(size: adaptiveFontSize(20, for: geometry), weight: .bold, design: .rounded))
                                        .foregroundColor(.deepPlum)
                                    
                                    Text("Get unlimited creations with premium features")
                                        .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .medium))
                                        .foregroundColor(.softPlum)
                                }
                                .padding(.horizontal, adaptivePadding(for: geometry))
                                .padding(.top, adaptiveSpacing(32, for: geometry))
                                .opacity(cardOpacity)
                                
                                // Premium Highlight Card
                                PremiumHighlightCard(geometry: geometry)
                                    .padding(.top, adaptiveSpacing(12, for: geometry))
                                    .padding(.horizontal, adaptivePadding(for: geometry))
                                    .opacity(cardOpacity)
                                
                                // Bottom Spacing
                                Spacer()
                                    .frame(height: adaptiveSpacing(32, for: geometry))
                            }
                    }
                    .scrollIndicators(.hidden)
                    .frame(width: geometry.size.width)
                }
            }
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .restore:
                    PhotoRestoreFlow()
                        .navigationBarBackButtonHidden(true)
                case .together:
                    MemoryMergeFlow()
                        .navigationBarBackButtonHidden(true)
                case .timeline:
                    TimelineComparisonFlow()
                        .navigationBarBackButtonHidden(true)
                case .celebrity:
                    CelebrityFlow()
                        .navigationBarBackButtonHidden(true)
                case .reunite:
                    ReuniteFlow()
                        .navigationBarBackButtonHidden(true)
                case .family:
                    FamilyFlow()
                        .navigationBarBackButtonHidden(true)
                case .settings:
                    SettingsView()
                case .myCreations:
                    MyCreationsView()
                case .premium:
                    PaywallView(trigger: .general)
                        .navigationBarHidden(true)
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
                cardOpacity = 1.0
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
                }
            } catch {
                print("❌ Failed to load image history: \(error)")
                await MainActor.run {
                    isLoadingHistory = false
                }
            }
        }
    }
}

// MARK: - Modern Home Header 3.0
struct ModernHomeHeader3: View {
    let user: User
    let geometry: GeometryProxy
    @StateObject private var monetizationManager = MonetizationManager.shared
    @State private var userCredits: Int = 0
    @State private var isLoadingCredits = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Greeting
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: adaptiveSpacing(4, for: geometry)) {
                    Text("Welcome back, \(user.name)")
                        .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .semibold, design: .rounded))
                        .foregroundColor(.deepPlum)
                            .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text("Bring your memories to life today")
                        .font(.system(size: adaptiveFontSize(13, for: geometry), weight: .regular))
                        .foregroundColor(.softPlum)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Credits Badge
                CreditsBadge(credits: userCredits, isLoading: isLoadingCredits, geometry: geometry)
            }
            .padding(.horizontal, adaptivePadding(for: geometry))
            .padding(.top, adaptiveSpacing(16, for: geometry))
            .padding(.bottom, adaptiveSpacing(20, for: geometry))
        }
        .onAppear {
            loadUserCredits()
        }
        .onReceive(monetizationManager.$userCredits) { credits in
            userCredits = credits
        }
    }
    
    private func loadUserCredits() {
        Task {
            userCredits = monetizationManager.userCredits
            isLoadingCredits = false
        }
    }
}

// MARK: - Trust Bar
struct TrustBar: View {
    let geometry: GeometryProxy
    
    var body: some View {
        HStack(spacing: adaptiveSpacing(20, for: geometry)) {
            TrustItem(icon: "lock.shield.fill", text: "Your photos are private", geometry: geometry)
            TrustItem(icon: "star.fill", text: "Rated 4.9★", geometry: geometry)
            TrustItem(icon: "photo.on.rectangle.angled", text: "54k+ memories", geometry: geometry)
        }
        .font(.system(size: adaptiveFontSize(11, for: geometry), weight: .medium))
        .foregroundColor(.softPlum)
    }
}

// MARK: - Trust Item
struct TrustItem: View {
    let icon: String
    let text: String
    let geometry: GeometryProxy
    
    var body: some View {
        HStack(spacing: adaptiveSpacing(4, for: geometry)) {
            Image(systemName: icon)
                .font(.system(size: adaptiveFontSize(10, for: geometry)))
                .foregroundColor(.blushPink)
            Text(text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

// MARK: - Credits Badge
struct CreditsBadge: View {
    let credits: Int
    let isLoading: Bool
    let geometry: GeometryProxy
    
    var body: some View {
        HStack(spacing: adaptiveSpacing(6, for: geometry)) {
            Image(systemName: "diamond.fill")
                .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .semibold))
                .foregroundStyle(LinearGradient.primaryBrand)
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            } else {
                Text("\(credits)")
                    .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .bold, design: .rounded))
                    .foregroundColor(.deepPlum)
            }
        }
        .padding(.horizontal, adaptiveSpacing(10, for: geometry))
        .padding(.vertical, adaptiveSpacing(6, for: geometry))
        .background(
            RoundedRectangle(cornerRadius: adaptiveCornerRadius(10, for: geometry))
                .fill(Color.pureWhite)
                .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Feature Card 3.0
struct FeatureCard3: View {
    let title: String
    let subtitle: String
    let icon: String
    let imageName: String
    let isPressed: Bool
    let geometry: GeometryProxy
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                // Image Preview
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: adaptiveSize(120, for: geometry), height: adaptiveSize(120, for: geometry))
                    .clipped()
                    .cornerRadius(adaptiveCornerRadius(20, for: geometry), corners: [.topLeft, .bottomLeft])
                
                // Content
                VStack(alignment: .leading, spacing: adaptiveSpacing(8, for: geometry)) {
                    HStack(spacing: adaptiveSpacing(8, for: geometry)) {
                        Image(systemName: icon)
                            .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .semibold))
                            .foregroundStyle(LinearGradient.primaryBrand)
                        
                        Text(title)
                            .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .bold, design: .rounded))
                            .foregroundStyle(LinearGradient.primaryBrand)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    }
                
                    Text(subtitle)
                    .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .medium))
                        .foregroundColor(.softPlum)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                        .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
                    
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .semibold))
                            .foregroundStyle(LinearGradient.primaryBrand)
                    }
        }
        .padding(adaptiveSpacing(16, for: geometry))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: adaptiveSize(120, for: geometry))
        .background(
            RoundedRectangle(cornerRadius: adaptiveCornerRadius(20, for: geometry))
                    .fill(Color.pureWhite)
                    .overlay(
                        RoundedRectangle(cornerRadius: adaptiveCornerRadius(20, for: geometry))
                            .stroke(LinearGradient.cardGlow, lineWidth: 1)
                    )
                    .shadow(
                        color: Color.cardShadow,
                        radius: isPressed ? 8 : 12,
                        x: 0,
                        y: isPressed ? 2 : 4
                    )
            )
            .clipped()
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Explore AI Grid
struct ExploreAICarousel: View {
    let geometry: GeometryProxy
    @Binding var navigationPath: NavigationPath
    
    let aiCards = [
        AICard(id: 0, emoji: "🩵", title: "Me Then vs Me Now", caption: "Tap to create your timeline", image: "best_friends_reunion_image", tone: "blush-white"),
        AICard(id: 1, emoji: "🌸", title: "Childhood Smile", caption: "Restore your precious moments", image: "childhood_photo", tone: "peach-white"),
        AICard(id: 2, emoji: "🪞", title: "Famous Frame", caption: "Get the celebrity treatment", image: "celebrity_image", tone: "violet-gray"),
        AICard(id: 3, emoji: "🕊", title: "Lost Connection", caption: "Reunite with loved ones", image: "wedding_photo", tone: "gray-blush"),
        AICard(id: 4, emoji: "🧬", title: "Family Legacy", caption: "Preserve family memories", image: "family_photo", tone: "beige-blush")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: adaptiveSpacing(16, for: geometry)) {
            VStack(alignment: .leading, spacing: adaptiveSpacing(8, for: geometry)) {
                HStack {
                    Text("Explore AI Magic")
                        .font(.system(size: adaptiveFontSize(20, for: geometry), weight: .bold, design: .rounded))
                        .foregroundColor(.deepPlum)
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(.system(size: adaptiveFontSize(18, for: geometry)))
                        .foregroundStyle(LinearGradient.primaryBrand)
                }
                
                Text("Get inspired • Try these creative ideas")
                    .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .medium))
                    .foregroundColor(.softPlum)
            }
            .padding(.horizontal, adaptivePadding(for: geometry))
            
            // Fixed 2-column grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: adaptiveSpacing(12, for: geometry)),
                GridItem(.flexible(), spacing: adaptiveSpacing(12, for: geometry))
            ], spacing: adaptiveSpacing(12, for: geometry)) {
                ForEach(aiCards) { card in
                    AICarouselCard(card: card, geometry: geometry, navigationPath: $navigationPath)
                }
            }
            .padding(.horizontal, adaptivePadding(for: geometry))
        }
    }
}

// MARK: - AI Card Model
struct AICard: Identifiable {
    let id: Int
    let emoji: String
    let title: String
    let caption: String
    let image: String
    let tone: String
}

// MARK: - AI Carousel Card
struct AICarouselCard: View {
    let card: AICard
    let geometry: GeometryProxy
    @Binding var navigationPath: NavigationPath
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            // Navigate based on card ID
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                switch card.id {
                case 0:
                    navigationPath.append(NavigationDestination.timeline)
                case 1:
                    navigationPath.append(NavigationDestination.restore)
                case 2:
                    navigationPath.append(NavigationDestination.celebrity)
                case 3:
                    navigationPath.append(NavigationDestination.reunite)
                case 4:
                    navigationPath.append(NavigationDestination.family)
                default:
                    break
                }
            }
        }) {
            VStack(spacing: adaptiveSpacing(8, for: geometry)) {
                // Image - Flexible width for grid
                Image(card.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: adaptiveSize(140, for: geometry))
                    .clipped()
                    .cornerRadius(adaptiveCornerRadius(12, for: geometry))
                
                // Content
                VStack(alignment: .leading, spacing: adaptiveSpacing(4, for: geometry)) {
                    HStack(spacing: 4) {
                        Text(card.emoji)
                            .font(.system(size: adaptiveFontSize(14, for: geometry)))
                        Text(card.title)
                            .font(.system(size: adaptiveFontSize(11, for: geometry), weight: .semibold, design: .rounded))
                            .foregroundColor(.deepPlum)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    
                    Text(card.caption)
                        .font(.system(size: adaptiveFontSize(10, for: geometry), weight: .medium))
                        .foregroundColor(.softPlum)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.2)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.2)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Community Stories Feed
struct CommunityStoriesFeed: View {
    let recentImages: [ProcessedImage]
    let geometry: GeometryProxy
    
    var body: some View {
        if !recentImages.isEmpty {
            VStack(alignment: .leading, spacing: adaptiveSpacing(16, for: geometry)) {
                VStack(alignment: .leading, spacing: adaptiveSpacing(8, for: geometry)) {
                    HStack {
                        Image(systemName: "photo.stack")
                            .font(.system(size: adaptiveFontSize(18, for: geometry)))
                            .foregroundStyle(LinearGradient.primaryBrand)
                        Text("What people are creating today")
                            .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .bold, design: .rounded))
                            .foregroundColor(.deepPlum)
                        Spacer()
                    }
                    
                    Text("See how others are transforming their memories")
                        .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .medium))
                        .foregroundColor(.softPlum)
                }
                .padding(.horizontal, adaptivePadding(for: geometry))
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: adaptiveSpacing(8, for: geometry)), count: 4), spacing: adaptiveSpacing(8, for: geometry)) {
                    ForEach(recentImages.prefix(8)) { image in
                        CommunityImageThumbnail(image: image, geometry: geometry)
                    }
                }
                .padding(.horizontal, adaptivePadding(for: geometry))
            }
            .padding(.bottom, adaptiveSpacing(16, for: geometry))
        }
    }
}

// MARK: - Community Image Thumbnail
struct CommunityImageThumbnail: View {
    let image: ProcessedImage
    let geometry: GeometryProxy
    
    var body: some View {
            AsyncImage(url: image.processedImageUrl.flatMap { URL(string: $0) }) { phase in
                switch phase {
                case .empty:
                RoundedRectangle(cornerRadius: adaptiveCornerRadius(8, for: geometry))
                    .fill(Color.gray.opacity(0.15))
                    .aspectRatio(1, contentMode: .fit)
                case .success(let loadedImage):
                    loadedImage
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: (geometry.size.width - adaptivePadding(for: geometry) * 2 - adaptiveSpacing(8, for: geometry) * 3) / 4)
                        .clipped()
                    .cornerRadius(adaptiveCornerRadius(8, for: geometry))
            case .failure:
                RoundedRectangle(cornerRadius: adaptiveCornerRadius(8, for: geometry))
                        .fill(Color.red.opacity(0.1))
                    .aspectRatio(1, contentMode: .fit)
                @unknown default:
                    EmptyView()
                }
            }
    }
}

// MARK: - Premium Highlight Card
struct PremiumHighlightCard: View {
    let geometry: GeometryProxy
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }) {
            HStack(spacing: adaptiveSpacing(16, for: geometry)) {
                VStack(alignment: .leading, spacing: adaptiveSpacing(12, for: geometry)) {
                    HStack(spacing: adaptiveSpacing(8, for: geometry)) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .semibold))
                            .foregroundStyle(LinearGradient.primaryBrand)
                        
                        Text("Unlock Unlimited Creations")
                            .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .bold, design: .rounded))
                            .foregroundColor(.deepPlum)
                    }
                    
                    VStack(alignment: .leading, spacing: adaptiveSpacing(4, for: geometry)) {
                        PremiumFeatureItem(icon: "photo.badge.plus", text: "HD exports", geometry: geometry)
                        PremiumFeatureItem(icon: "bolt.fill", text: "Instant results", geometry: geometry)
                        PremiumFeatureItem(icon: "checkmark.shield.fill", text: "No watermark", geometry: geometry)
                    }
                    
                    Text("Cancel anytime • Secure App Store billing")
                    .font(.system(size: adaptiveFontSize(11, for: geometry), weight: .medium))
                        .foregroundColor(.softPlum.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(adaptiveSpacing(20, for: geometry))
            .background(
                RoundedRectangle(cornerRadius: adaptiveCornerRadius(24, for: geometry))
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.lightBlush.opacity(0.4),
                                Color.pureWhite
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: adaptiveCornerRadius(24, for: geometry))
                            .stroke(LinearGradient.primaryBrand.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color.cardShadow, radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
    }
}

// MARK: - Premium Feature Item
struct PremiumFeatureItem: View {
    let icon: String
    let text: String
    let geometry: GeometryProxy
    
    var body: some View {
        HStack(spacing: adaptiveSpacing(8, for: geometry)) {
            Image(systemName: icon)
                .font(.system(size: adaptiveFontSize(12, for: geometry), weight: .semibold))
                .foregroundStyle(LinearGradient.primaryBrand)
            Text(text)
                .font(.system(size: adaptiveFontSize(13, for: geometry), weight: .medium))
                .foregroundColor(.deepPlum)
        }
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
