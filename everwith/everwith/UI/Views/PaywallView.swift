//
//  PaywallView.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI
import RevenueCat

// MARK: - Paywall Trigger Type
enum PaywallTrigger {
    case postResult(resultImage: UIImage?)
    case beforeSave(resultImage: UIImage?)
    case queuePriority
    case cinematicFilter
    case creditNeeded
    case general
}

// MARK: - Main Paywall View
struct PaywallView: View {
    let trigger: PaywallTrigger
    @Environment(\.dismiss) private var dismiss
    @StateObject private var revenueCatService = RevenueCatService.shared
    @State private var selectedTier: SubscriptionTier = .premiumMonthly
    @State private var selectedCreditPack: CreditPack?
    @State private var showingCreditPacks = false
    @State private var animateElements = false
    @State private var contentOpacity: Double = 0
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var purchaseSuccess = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Clean background matching app theme
                CleanWhiteBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Consistent header
                    ModernPageHeader(title: "Premium", geometry: geometry)
                    
                    // Main content
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 20, for: geometry)) {
                            // Hero section with result preview
                            HeroSection(trigger: trigger, geometry: geometry)
                                .opacity(contentOpacity)
                                .offset(y: animateElements ? 0 : 30)
                            
                            // Features showcase
                            FeaturesShowcase(geometry: geometry)
                                .opacity(contentOpacity)
                                .offset(y: animateElements ? 0 : 30)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateElements)
                            
                            // Pricing section
                            PricingSection(
                                selectedTier: $selectedTier,
                                selectedCreditPack: $selectedCreditPack,
                                showingCreditPacks: $showingCreditPacks,
                                geometry: geometry
                            )
                            .opacity(contentOpacity)
                            .offset(y: animateElements ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateElements)
                            
                            // Trial information
                            TrialInfoCard(geometry: geometry)
                                .opacity(contentOpacity)
                                .offset(y: animateElements ? 0 : 30)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateElements)
                            
                            // Action buttons
                            ActionButtons(
                                selectedTier: selectedTier,
                                selectedCreditPack: selectedCreditPack,
                                showingCreditPacks: showingCreditPacks,
                                isLoading: revenueCatService.isLoading,
                                geometry: geometry
                            ) {
                                handlePurchase(geometry: geometry)
                            } secondaryAction: {
                                dismiss()
                            }
                            .opacity(contentOpacity)
                            .offset(y: animateElements ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateElements)
                            
                            // Footer with legal links
                            PaywallFooter(geometry: geometry) {
                                Task {
                                    await revenueCatService.restorePurchases()
                                }
                            }
                            .opacity(contentOpacity)
                            .offset(y: animateElements ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: animateElements)
                            
                            // Bottom spacing
                            Spacer()
                                .frame(height: ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry))
                        }
                        .padding(.horizontal, geometry.adaptivePadding())
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await revenueCatService.updateSubscriptionStatus()
            }
            
            // Staggered entrance animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animateElements = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                contentOpacity = 1.0
            }
        }
        .alert("Purchase Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $purchaseSuccess) {
            PurchaseSuccessView()
        }
    }
    
    // MARK: - Purchase Handling
    private func handlePurchase(geometry: GeometryProxy) {
        Task {
            do {
                let success: Bool
                
                if showingCreditPacks, let pack = selectedCreditPack {
                    success = await revenueCatService.purchaseCreditPack(pack)
                } else {
                    success = await revenueCatService.purchaseSubscription(tier: selectedTier)
                }
                
                if success {
                    purchaseSuccess = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                } else if let error = revenueCatService.errorMessage {
                    errorMessage = error
                    showingError = true
                }
            }
        }
    }
}

    // MARK: - Hero Section
struct HeroSection: View {
    let trigger: PaywallTrigger
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 16, for: geometry)) {
            // Result preview (if available)
            if case .postResult(let image) = trigger,
               let resultImage = image {
                ResultPreviewCard(image: resultImage, geometry: geometry)
            }
            
            // Main headline
            Text(heroHeadline)
                .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 28, for: geometry), weight: .bold, design: .rounded))
                .foregroundStyle(LinearGradient.primaryBrand)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
            
            // Subheadline
            Text(heroSubheadline)
                .font(.system(size: ResponsiveDesign.adaptiveFontSize(baseSize: 16, for: geometry), weight: .medium))
                .foregroundColor(.deepPlum.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry))
    }
    
    private var heroHeadline: String {
        switch trigger {
        case .postResult:
            return "Unlock HD Quality"
        case .beforeSave:
            return "Export in Full Quality?"
        case .queuePriority:
            return "Skip the Wait"
        case .cinematicFilter:
            return "Unlock Cinematic Filters"
        case .creditNeeded:
            return "Get More Credits"
        case .general:
            return "Upgrade to Premium"
        }
    }
    
    private var heroSubheadline: String {
        switch trigger {
        case .postResult:
            return "Remove watermark and get crystal clear HD quality"
        case .beforeSave:
            return "Choose your export quality"
        case .queuePriority:
            return "Premium users get instant results"
        case .cinematicFilter:
            return "Professional-grade photo enhancement"
        case .creditNeeded:
            return "Continue processing your memories"
        case .general:
            return "Unlock unlimited processing and HD quality"
        }
    }
}

// MARK: - Result Preview Card
struct ResultPreviewCard: View {
    let image: UIImage
    let geometry: GeometryProxy
    
    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: min(geometry.adaptiveSize(200), geometry.size.height * 0.25))
                .clipShape(RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 16, for: geometry)))
                .overlay(
                    RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 16, for: geometry))
                        .stroke(LinearGradient.cardGlow, lineWidth: 1)
                )
                .blur(radius: 3)
            
            VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry)) {
                Image(systemName: "lock.fill")
                    .font(.system(size: geometry.adaptiveFontSize(24), weight: .semibold))
                    .foregroundStyle(LinearGradient.primaryBrand)
                
                Text("Unlock HD Quality")
                    .font(.system(size: geometry.adaptiveFontSize(16), weight: .semibold))
                    .foregroundColor(.deepPlum)
            }
            .padding(ResponsiveDesign.adaptiveSpacing(baseSpacing: 16, for: geometry))
            .background(
                RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 12, for: geometry))
                    .fill(Color.pureWhite)
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 12, for: geometry))
                            .stroke(LinearGradient.primaryBrand, lineWidth: 1)
                    )
                    .shadow(
                        color: Color.cardShadow,
                        radius: ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry),
                        x: 0,
                        y: ResponsiveDesign.adaptiveSpacing(baseSpacing: 4, for: geometry)
                    )
            )
        }
    }
}

// MARK: - Features Showcase
struct FeaturesShowcase: View {
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 12, for: geometry)) {
            ForEach(features, id: \.title) { feature in
                FeatureRow(
                    icon: feature.icon,
                    title: feature.title,
                    description: feature.description,
                    geometry: geometry
                )
            }
        }
        .padding(ResponsiveDesign.adaptiveSpacing(baseSpacing: 20, for: geometry))
        .background(
            RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 20, for: geometry))
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
                    RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 20, for: geometry))
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
            color: Color.cardShadow,
            radius: ResponsiveDesign.adaptiveSpacing(baseSpacing: 12, for: geometry),
            x: 0,
            y: ResponsiveDesign.adaptiveSpacing(baseSpacing: 6, for: geometry)
        )
    }
    
    private let features = [
        FeatureData(icon: "bolt.fill", title: "Instant Processing", description: "Skip the queue, get results immediately"),
        FeatureData(icon: "4k.tv", title: "4K HD Export", description: "Crystal clear quality for your memories"),
        FeatureData(icon: "wand.and.stars", title: "Cinematic Filters", description: "Professional-grade photo enhancement"),
        FeatureData(icon: "infinity", title: "Unlimited Usage", description: "Process as many photos as you want"),
        FeatureData(icon: "checkmark.shield", title: "No Watermarks", description: "Clean, professional results")
    ]
}

// MARK: - Feature Data
struct FeatureData {
    let icon: String
    let title: String
    let description: String
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let geometry: GeometryProxy
    
    var body: some View {
        HStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 16, for: geometry)) {
            Image(systemName: icon)
                .font(.system(size: geometry.adaptiveFontSize(18), weight: .medium))
                .foregroundStyle(LinearGradient.primaryBrand)
                .frame(width: geometry.adaptiveSize(24))
            
            VStack(alignment: .leading, spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 4, for: geometry)) {
                Text(title)
                    .font(.system(size: geometry.adaptiveFontSize(16), weight: .semibold))
                    .foregroundColor(.deepPlum)
                
                Text(description)
                    .font(.system(size: geometry.adaptiveFontSize(14), weight: .medium))
                    .foregroundColor(.deepPlum.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(.vertical, ResponsiveDesign.adaptiveSpacing(baseSpacing: 4, for: geometry))
    }
}

// MARK: - Pricing Section
struct PricingSection: View {
    @Binding var selectedTier: SubscriptionTier
    @Binding var selectedCreditPack: CreditPack?
    @Binding var showingCreditPacks: Bool
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 16, for: geometry)) {
            // Toggle between subscription and credits
            PricingToggle(showingCreditPacks: $showingCreditPacks, geometry: geometry)
            
            if showingCreditPacks {
                CreditPacksView(selectedPack: $selectedCreditPack, geometry: geometry)
            } else {
                SubscriptionPlansView(selectedTier: $selectedTier, geometry: geometry)
            }
        }
    }
}

// MARK: - Pricing Toggle
struct PricingToggle: View {
    @Binding var showingCreditPacks: Bool
    let geometry: GeometryProxy
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: { showingCreditPacks = false }) {
                Text("Subscription")
                    .font(.system(size: geometry.adaptiveFontSize(14), weight: .semibold))
                    .foregroundColor(showingCreditPacks ? .deepPlum.opacity(0.6) : .deepPlum)
                    .padding(.vertical, ResponsiveDesign.adaptiveSpacing(baseSpacing: 12, for: geometry))
                    .padding(.horizontal, ResponsiveDesign.adaptiveSpacing(baseSpacing: 20, for: geometry))
                    .background(
                        RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 8, for: geometry))
                            .fill(showingCreditPacks ? Color.clear : Color.pureWhite.opacity(0.9))
                    )
            }
            
            Button(action: { showingCreditPacks = true }) {
                Text("Pay-as-you-go")
                    .font(.system(size: geometry.adaptiveFontSize(14), weight: .semibold))
                    .foregroundColor(showingCreditPacks ? .deepPlum : .deepPlum.opacity(0.6))
                    .padding(.vertical, ResponsiveDesign.adaptiveSpacing(baseSpacing: 12, for: geometry))
                    .padding(.horizontal, ResponsiveDesign.adaptiveSpacing(baseSpacing: 20, for: geometry))
                    .background(
                        RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 8, for: geometry))
                            .fill(showingCreditPacks ? Color.pureWhite.opacity(0.9) : Color.clear)
                    )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 8, for: geometry))
                .fill(Color.pureWhite.opacity(0.3))
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 8, for: geometry))
                        .stroke(LinearGradient.cardGlow, lineWidth: 1)
                )
        )
    }
}

// MARK: - Subscription Plans View
struct SubscriptionPlansView: View {
    @Binding var selectedTier: SubscriptionTier
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 12, for: geometry)) {
            ForEach(SubscriptionTier.allCases.filter { $0 != .free }, id: \.self) { tier in
                SubscriptionPlanCard(
                    tier: tier,
                    isSelected: selectedTier == tier,
                    geometry: geometry
                ) {
                    selectedTier = tier
                }
            }
        }
    }
}

// MARK: - Subscription Plan Card
struct SubscriptionPlanCard: View {
    let tier: SubscriptionTier
    let isSelected: Bool
    let geometry: GeometryProxy
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 12, for: geometry)) {
                HStack {
                    VStack(alignment: .leading, spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 4, for: geometry)) {
                        Text(tier.displayName)
                            .font(.system(size: geometry.adaptiveFontSize(18), weight: .semibold))
                            .foregroundColor(.deepPlum)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        
                        HStack(alignment: .bottom, spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 4, for: geometry)) {
                            Text(priceText)
                                .font(.system(size: geometry.adaptiveFontSize(24), weight: .bold))
                                .foregroundStyle(LinearGradient.primaryBrand)
                            
                            Text(periodText)
                                .font(.system(size: geometry.adaptiveFontSize(14), weight: .medium))
                                .foregroundColor(.deepPlum.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    if tier == .premiumYearly {
                        Text("BEST VALUE")
                            .font(.system(size: geometry.adaptiveFontSize(10), weight: .bold))
                            .foregroundColor(.deepPlum)
                            .padding(.horizontal, ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry))
                            .padding(.vertical, ResponsiveDesign.adaptiveSpacing(baseSpacing: 4, for: geometry))
                            .background(
                                RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 4, for: geometry))
                                    .fill(Color.pureWhite)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 4, for: geometry))
                                            .stroke(LinearGradient.primaryBrand, lineWidth: 1)
                                    )
                            )
                    }
                }
                
                VStack(alignment: .leading, spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 6, for: geometry)) {
                    ForEach(features.prefix(3), id: \.self) { feature in
                        HStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry)) {
                            Image(systemName: "checkmark")
                                .font(.system(size: geometry.adaptiveFontSize(12), weight: .semibold))
                                .foregroundStyle(LinearGradient.primaryBrand)
                            
                            Text(feature)
                                .font(.system(size: geometry.adaptiveFontSize(14), weight: .medium))
                                .foregroundColor(.deepPlum.opacity(0.8))
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(ResponsiveDesign.adaptiveSpacing(baseSpacing: 20, for: geometry))
            .background(
                RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 16, for: geometry))
                    .fill(Color.pureWhite)
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 16, for: geometry))
                            .stroke(
                                isSelected ? LinearGradient.primaryBrand : LinearGradient.cardGlow,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(
                        color: Color.cardShadow,
                        radius: isSelected ? ResponsiveDesign.adaptiveSpacing(baseSpacing: 16, for: geometry) : ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry),
                        x: 0,
                        y: isSelected ? ResponsiveDesign.adaptiveSpacing(baseSpacing: 6, for: geometry) : ResponsiveDesign.adaptiveSpacing(baseSpacing: 3, for: geometry)
                    )
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private var priceText: String {
        switch tier {
        case .premiumMonthly:
            return "£4.99"
        case .premiumYearly:
            return "£69.99"
        case .free:
            return "Free"
        }
    }
    
    private var periodText: String {
        switch tier {
        case .premiumMonthly:
            return "per month"
        case .premiumYearly:
            return "per year"
        case .free:
            return ""
        }
    }
    
    private var features: [String] {
        switch tier {
        case .premiumMonthly:
            return ["Unlimited processing", "4K HD export", "Instant results", "All filters"]
        case .premiumYearly:
            return ["Everything in Monthly", "40% discount", "Save £50/year", "Best value"]
        case .free:
            return []
        }
    }
}

// MARK: - Credit Packs View
struct CreditPacksView: View {
    @Binding var selectedPack: CreditPack?
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 12, for: geometry)) {
            ForEach(CreditPack.packs) { pack in
                CreditPackCard(
                    pack: pack,
                    isSelected: selectedPack?.id == pack.id,
                    geometry: geometry
                ) {
                    selectedPack = pack
                }
            }
        }
    }
}

// MARK: - Credit Pack Card
struct CreditPackCard: View {
    let pack: CreditPack
    let isSelected: Bool
    let geometry: GeometryProxy
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 6, for: geometry)) {
                    Text("\(pack.credits) Credits")
                        .font(.system(size: geometry.adaptiveFontSize(20), weight: .semibold))
                        .foregroundColor(.deepPlum)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    if let savings = pack.savings {
                        Text(savings)
                            .font(.system(size: geometry.adaptiveFontSize(14), weight: .medium))
                            .foregroundStyle(LinearGradient.primaryBrand)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                
                Spacer()
                
                Text(pack.price)
                    .font(.system(size: geometry.adaptiveFontSize(24), weight: .bold))
                    .foregroundStyle(LinearGradient.primaryBrand)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(ResponsiveDesign.adaptiveSpacing(baseSpacing: 20, for: geometry))
            .background(
                RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 16, for: geometry))
                    .fill(Color.pureWhite)
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 16, for: geometry))
                            .stroke(
                                isSelected ? LinearGradient.primaryBrand : LinearGradient.cardGlow,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(
                        color: Color.cardShadow,
                        radius: isSelected ? ResponsiveDesign.adaptiveSpacing(baseSpacing: 12, for: geometry) : ResponsiveDesign.adaptiveSpacing(baseSpacing: 6, for: geometry),
                        x: 0,
                        y: isSelected ? ResponsiveDesign.adaptiveSpacing(baseSpacing: 4, for: geometry) : ResponsiveDesign.adaptiveSpacing(baseSpacing: 2, for: geometry)
                    )
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Trial Info Card
struct TrialInfoCard: View {
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry)) {
            HStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry)) {
                Image(systemName: "gift.fill")
                    .font(.system(size: geometry.adaptiveFontSize(16), weight: .medium))
                    .foregroundStyle(LinearGradient.primaryBrand)
                
                Text("Try Premium free for 3 days")
                    .font(.system(size: geometry.adaptiveFontSize(16), weight: .semibold))
                    .foregroundColor(.deepPlum)
            }
            
            Text("Cancel anytime. No commitment.")
                .font(.system(size: geometry.adaptiveFontSize(14), weight: .medium))
                .foregroundColor(.deepPlum.opacity(0.7))
        }
        .padding(ResponsiveDesign.adaptiveSpacing(baseSpacing: 16, for: geometry))
        .background(
            RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 12, for: geometry))
                .fill(Color.pureWhite.opacity(0.8))
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 12, for: geometry))
                        .stroke(LinearGradient.cardGlow, lineWidth: 1)
                )
        )
    }
}

// MARK: - Action Buttons
struct ActionButtons: View {
    let selectedTier: SubscriptionTier
    let selectedCreditPack: CreditPack?
    let showingCreditPacks: Bool
    let isLoading: Bool
    let geometry: GeometryProxy
    let primaryAction: () -> Void
    let secondaryAction: () -> Void
    
    var body: some View {
        VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 12, for: geometry)) {
            // Primary action button
            Button(action: primaryAction) {
                HStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry)) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .deepPlum))
                            .scaleEffect(0.8)
                    } else {
                        Text(primaryButtonText)
                            .font(.system(size: geometry.adaptiveFontSize(18), weight: .semibold))
                    }
                }
                .foregroundColor(.deepPlum)
                .frame(maxWidth: .infinity)
                .frame(height: ResponsiveDesign.adaptiveButtonHeight(baseHeight: 56, for: geometry))
                .background(
                    RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 16, for: geometry))
                        .fill(Color.pureWhite)
                        .background(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 16, for: geometry))
                                .stroke(LinearGradient.primaryBrand, lineWidth: 2)
                        )
                        .shadow(
                            color: Color.cardShadow,
                            radius: ResponsiveDesign.adaptiveSpacing(baseSpacing: 12, for: geometry),
                            x: 0,
                            y: ResponsiveDesign.adaptiveSpacing(baseSpacing: 6, for: geometry)
                        )
                )
            }
            .disabled(isLoading)
            
            // Secondary action button
            Button(action: secondaryAction) {
                Text("Keep Free Version")
                    .font(.system(size: geometry.adaptiveFontSize(16), weight: .medium))
                    .foregroundColor(.deepPlum.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .frame(height: ResponsiveDesign.adaptiveButtonHeight(baseHeight: 48, for: geometry))
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var primaryButtonText: String {
        if showingCreditPacks {
            return "Buy Credits"
        } else {
            switch selectedTier {
            case .premiumMonthly:
                return "Start Free Trial"
            case .premiumYearly:
                return "Start Free Trial"
            case .free:
                return "Upgrade"
            }
        }
    }
}

// MARK: - Paywall Footer
struct PaywallFooter: View {
    let geometry: GeometryProxy
    let onRestore: () -> Void
    
    var body: some View {
        VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry)) {
            HStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 12, for: geometry)) {
                Button("Restore Purchases", action: onRestore)
                    .font(.system(size: geometry.adaptiveFontSize(12), weight: .medium))
                    .foregroundColor(.deepPlum.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Button("Terms") {
                    // Show terms
                }
                .font(.system(size: geometry.adaptiveFontSize(12), weight: .medium))
                .foregroundColor(.deepPlum.opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                
                Button("Privacy") {
                    // Show privacy policy
                }
                .font(.system(size: geometry.adaptiveFontSize(12), weight: .medium))
                .foregroundColor(.deepPlum.opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
            
            Text("Subscriptions auto-renew unless cancelled")
                .font(.system(size: geometry.adaptiveFontSize(11), weight: .medium))
                .foregroundColor(.deepPlum.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry))
    }
}

#Preview {
    PaywallView(trigger: .general)
}