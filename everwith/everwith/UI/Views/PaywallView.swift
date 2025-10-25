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
    @State private var showingCreditPacks = false
    @State private var showingTrialInfo = false
    @State private var animateElements = false
    @State private var contentOpacity: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Beautiful gradient background matching HomeView
                PremiumBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Main content with proper bounds
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: adaptiveSpacing(16, for: geometry)) {
                            // Hero section
                            heroSection(geometry: geometry)
                            
                            // Features list
                            featuresSection(geometry: geometry)
                            
                            // Pricing options
                            pricingSection(geometry: geometry)
                            
                            // Trial info
                            trialInfoSection(geometry: geometry)
                            
                            // Action buttons
                            actionButtons(geometry: geometry)
                            
                            // Footer
                            footerSection(geometry: geometry)
                        }
                        .frame(maxWidth: geometry.size.width)
                        .padding(.horizontal, adaptivePadding(for: geometry))
                        .padding(.top, adaptiveSpacing(8, for: geometry))
                        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom + 8 : 16)
                        .opacity(contentOpacity)
                        .offset(y: animateElements ? 0 : 20)
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
    }
    
    // MARK: - Hero Section
    @ViewBuilder
    private func heroSection(geometry: GeometryProxy) -> some View {
        VStack(spacing: adaptiveSpacing(12, for: geometry)) {
            // Result preview (if available)
            if case .postResult(let image) = trigger,
               let resultImage = image {
                Image(uiImage: resultImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: min(adaptiveSize(180, for: geometry), geometry.size.height * 0.25))
                    .clipShape(RoundedRectangle(cornerRadius: adaptiveCornerRadius(12, for: geometry)))
                    .overlay(
                        RoundedRectangle(cornerRadius: adaptiveCornerRadius(12, for: geometry))
                            .stroke(LinearGradient.cardGlow, lineWidth: 1)
                    )
                    .blur(radius: 2)
                    .overlay(
                        VStack(spacing: adaptiveSpacing(6, for: geometry)) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: adaptiveFontSize(20, for: geometry)))
                                .foregroundStyle(LinearGradient.primaryBrand)
                            Text("Unlock HD Quality")
                                .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .semibold))
                                .foregroundColor(.deepPlum)
                        }
                        .padding(adaptiveSpacing(12, for: geometry))
                        .background(
                            RoundedRectangle(cornerRadius: adaptiveCornerRadius(8, for: geometry))
                                .fill(Color.pureWhite)
                                .overlay(
                                    RoundedRectangle(cornerRadius: adaptiveCornerRadius(8, for: geometry))
                                        .stroke(LinearGradient.primaryBrand, lineWidth: 1)
                                )
                                .shadow(
                                    color: Color.cardShadow,
                                    radius: 6,
                                    x: 0,
                                    y: 2
                                )
                        )
                    )
            }
            
            // Main headline with gradient
            Text(heroHeadline)
                .font(.system(size: adaptiveFontSize(28, for: geometry), weight: .bold, design: .rounded))
                .foregroundStyle(LinearGradient.primaryBrand)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
            
            // Subheadline
            Text(heroSubheadline)
                .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                .foregroundColor(.deepPlum.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Features Section
    @ViewBuilder
    private func featuresSection(geometry: GeometryProxy) -> some View {
        VStack(spacing: adaptiveSpacing(12, for: geometry)) {
            FeatureRow(
                icon: "bolt.fill",
                title: "Instant Processing",
                description: "Skip the queue, get results immediately",
                geometry: geometry
            )
            
            FeatureRow(
                icon: "4k.tv",
                title: "4K HD Export",
                description: "Crystal clear quality for your memories",
                geometry: geometry
            )
            
            FeatureRow(
                icon: "wand.and.stars",
                title: "Cinematic Filters",
                description: "Professional-grade photo enhancement",
                geometry: geometry
            )
            
            FeatureRow(
                icon: "infinity",
                title: "Unlimited Usage",
                description: "Process as many photos as you want",
                geometry: geometry
            )
            
            FeatureRow(
                icon: "checkmark.shield",
                title: "No Watermarks",
                description: "Clean, professional results",
                geometry: geometry
            )
        }
        .padding(.vertical, adaptiveSpacing(4, for: geometry))
    }
    
    // MARK: - Pricing Section
    @ViewBuilder
    private func pricingSection(geometry: GeometryProxy) -> some View {
        VStack(spacing: adaptiveSpacing(12, for: geometry)) {
            // Subscription vs Credits toggle
            HStack(spacing: 0) {
                Button(action: { showingCreditPacks = false }) {
                    Text("Subscription")
                        .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .semibold))
                        .foregroundColor(showingCreditPacks ? .deepPlum.opacity(0.6) : .deepPlum)
                        .padding(.vertical, adaptiveSpacing(10, for: geometry))
                        .padding(.horizontal, adaptiveSpacing(16, for: geometry))
                        .background(
                            RoundedRectangle(cornerRadius: adaptiveCornerRadius(6, for: geometry))
                                .fill(showingCreditPacks ? Color.clear : Color.pureWhite.opacity(0.8))
                        )
                }
                
                Button(action: { showingCreditPacks = true }) {
                    Text("Pay-as-you-go")
                        .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .semibold))
                        .foregroundColor(showingCreditPacks ? .deepPlum : .deepPlum.opacity(0.6))
                        .padding(.vertical, adaptiveSpacing(10, for: geometry))
                        .padding(.horizontal, adaptiveSpacing(16, for: geometry))
                        .background(
                            RoundedRectangle(cornerRadius: adaptiveCornerRadius(6, for: geometry))
                                .fill(showingCreditPacks ? Color.pureWhite.opacity(0.8) : Color.clear)
                        )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: adaptiveCornerRadius(6, for: geometry))
                    .fill(Color.pureWhite.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: adaptiveCornerRadius(6, for: geometry))
                            .stroke(LinearGradient.cardGlow, lineWidth: 1)
                    )
            )
            
            if showingCreditPacks {
                creditPacksView(geometry: geometry)
            } else {
                subscriptionPlansView(geometry: geometry)
            }
        }
    }
    
    // MARK: - Subscription Plans
    @ViewBuilder
    private func subscriptionPlansView(geometry: GeometryProxy) -> some View {
        VStack(spacing: adaptiveSpacing(8, for: geometry)) {
            // Monthly Premium
            PricingCard(
                title: "Premium Monthly",
                price: "£4.99",
                period: "per month",
                features: ["Unlimited processing", "4K HD export", "Instant results", "All filters"],
                isSelected: selectedTier == .premiumMonthly,
                isPopular: false,
                geometry: geometry
            ) {
                selectedTier = .premiumMonthly
            }
            
            // Yearly Premium
            PricingCard(
                title: "Premium Yearly",
                price: "£69.99",
                period: "per year",
                features: ["Everything in Monthly", "40% discount", "Save £50/year", "Best value"],
                isSelected: selectedTier == .premiumYearly,
                isPopular: true,
                geometry: geometry
            ) {
                selectedTier = .premiumYearly
            }
        }
    }
    
    // MARK: - Credit Packs
    @ViewBuilder
    private func creditPacksView(geometry: GeometryProxy) -> some View {
        VStack(spacing: adaptiveSpacing(8, for: geometry)) {
            ForEach(CreditPack.packs) { pack in
                CreditPackCard(pack: pack, geometry: geometry)
            }
        }
    }
    
    // MARK: - Trial Info
    @ViewBuilder
    private func trialInfoSection(geometry: GeometryProxy) -> some View {
        VStack(spacing: adaptiveSpacing(6, for: geometry)) {
            HStack(spacing: adaptiveSpacing(6, for: geometry)) {
                Image(systemName: "gift.fill")
                    .font(.system(size: adaptiveFontSize(14, for: geometry)))
                    .foregroundStyle(LinearGradient.primaryBrand)
                Text("Try Premium free for 3 days")
                    .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .semibold))
                    .foregroundColor(.deepPlum)
            }
            
            Text("Cancel anytime. No commitment.")
                .font(.system(size: adaptiveFontSize(12, for: geometry)))
                .foregroundColor(.deepPlum.opacity(0.7))
        }
        .padding(.vertical, adaptiveSpacing(4, for: geometry))
    }
    
    // MARK: - Action Buttons
    @ViewBuilder
    private func actionButtons(geometry: GeometryProxy) -> some View {
        VStack(spacing: adaptiveSpacing(8, for: geometry)) {
            // Primary action button
            Button(action: {
                Task {
                    if showingCreditPacks {
                        // Handle credit pack purchase
                        if let selectedPack = CreditPack.packs.first {
                            let success = await revenueCatService.purchaseCreditPack(selectedPack)
                            if success {
                                dismiss()
                            }
                        }
                    } else {
                        // Handle subscription purchase
                        let success = await revenueCatService.purchaseSubscription(tier: selectedTier)
                        if success {
                            dismiss()
                        }
                    }
                }
            }) {
                HStack(spacing: adaptiveSpacing(6, for: geometry)) {
                    if revenueCatService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .deepPlum))
                            .scaleEffect(0.7)
                    } else {
                        Text(primaryButtonText)
                            .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .semibold))
                    }
                }
                .foregroundColor(.deepPlum)
                .frame(maxWidth: .infinity)
                .frame(height: adaptiveSize(48, for: geometry))
                .background(
                    RoundedRectangle(cornerRadius: adaptiveCornerRadius(12, for: geometry))
                        .fill(Color.pureWhite)
                        .overlay(
                            RoundedRectangle(cornerRadius: adaptiveCornerRadius(12, for: geometry))
                                .stroke(LinearGradient.primaryBrand, lineWidth: 2)
                        )
                        .shadow(
                            color: Color.cardShadow,
                            radius: 8,
                            x: 0,
                            y: 3
                        )
                )
            }
            .disabled(revenueCatService.isLoading)
            
            // Secondary action button
            Button(action: { dismiss() }) {
                Text("Keep Free Version")
                    .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .medium))
                    .foregroundColor(.deepPlum.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .frame(height: adaptiveSize(40, for: geometry))
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Footer
    @ViewBuilder
    private func footerSection(geometry: GeometryProxy) -> some View {
        VStack(spacing: adaptiveSpacing(6, for: geometry)) {
            HStack(spacing: adaptiveSpacing(8, for: geometry)) {
                Button("Restore Purchases") {
                    Task {
                        await revenueCatService.restorePurchases()
                    }
                }
                .font(.system(size: adaptiveFontSize(11, for: geometry)))
                .foregroundColor(.deepPlum.opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                
                Button("Terms") {
                    // Show terms
                }
                .font(.system(size: adaptiveFontSize(11, for: geometry)))
                .foregroundColor(.deepPlum.opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                
                Button("Privacy") {
                    // Show privacy policy
                }
                .font(.system(size: adaptiveFontSize(11, for: geometry)))
                .foregroundColor(.deepPlum.opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
            
            Text("Subscriptions auto-renew unless cancelled")
                .font(.system(size: adaptiveFontSize(10, for: geometry)))
                .foregroundColor(.deepPlum.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, adaptiveSpacing(4, for: geometry))
    }
    
    // MARK: - Adaptive Sizing Functions
    private func adaptivePadding(for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        return max(8, min(12, screenWidth * 0.025))
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
    
    private func adaptiveCornerRadius(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
    
    // MARK: - Computed Properties
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

// MARK: - Feature Row Component
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let geometry: GeometryProxy
    
    var body: some View {
        HStack(spacing: adaptiveSpacing(12, for: geometry)) {
            Image(systemName: icon)
                .font(.system(size: adaptiveFontSize(16, for: geometry)))
                .foregroundStyle(LinearGradient.primaryBrand)
                .frame(width: adaptiveSize(20, for: geometry))
            
            VStack(alignment: .leading, spacing: adaptiveSpacing(2, for: geometry)) {
                Text(title)
                    .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .semibold))
                    .foregroundColor(.deepPlum)
                
                Text(description)
                    .font(.system(size: adaptiveFontSize(12, for: geometry)))
                    .foregroundColor(.deepPlum.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(.vertical, adaptiveSpacing(2, for: geometry))
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
}

// MARK: - Pricing Card Component
struct PricingCard: View {
    let title: String
    let price: String
    let period: String
    let features: [String]
    let isSelected: Bool
    let isPopular: Bool
    let geometry: GeometryProxy
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: adaptiveSpacing(8, for: geometry)) {
                HStack {
                    VStack(alignment: .leading, spacing: adaptiveSpacing(2, for: geometry)) {
                        Text(title)
                            .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .semibold))
                            .foregroundColor(.deepPlum)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        
                        HStack(alignment: .bottom, spacing: adaptiveSpacing(2, for: geometry)) {
                            Text(price)
                                .font(.system(size: adaptiveFontSize(20, for: geometry), weight: .bold))
                                .foregroundStyle(LinearGradient.primaryBrand)
                            
                            Text(period)
                                .font(.system(size: adaptiveFontSize(12, for: geometry)))
                                .foregroundColor(.deepPlum.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    if isPopular {
                        Text("POPULAR")
                            .font(.system(size: adaptiveFontSize(10, for: geometry), weight: .bold))
                            .foregroundColor(.deepPlum)
                            .padding(.horizontal, adaptiveSpacing(6, for: geometry))
                            .padding(.vertical, adaptiveSpacing(2, for: geometry))
                            .background(
                                RoundedRectangle(cornerRadius: adaptiveCornerRadius(3, for: geometry))
                                    .fill(Color.pureWhite)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: adaptiveCornerRadius(3, for: geometry))
                                            .stroke(LinearGradient.primaryBrand, lineWidth: 1)
                                    )
                            )
                    }
                }
                
                VStack(alignment: .leading, spacing: adaptiveSpacing(2, for: geometry)) {
                    ForEach(features.prefix(3), id: \.self) { feature in
                        HStack(spacing: adaptiveSpacing(6, for: geometry)) {
                            Image(systemName: "checkmark")
                                .font(.system(size: adaptiveFontSize(10, for: geometry)))
                                .foregroundStyle(LinearGradient.primaryBrand)
                            
                            Text(feature)
                                .font(.system(size: adaptiveFontSize(12, for: geometry)))
                                .foregroundColor(.deepPlum.opacity(0.8))
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(adaptiveSpacing(12, for: geometry))
            .background(
                RoundedRectangle(cornerRadius: adaptiveCornerRadius(10, for: geometry))
                    .fill(Color.pureWhite)
                    .overlay(
                        RoundedRectangle(cornerRadius: adaptiveCornerRadius(10, for: geometry))
                            .stroke(
                                isSelected ? LinearGradient.primaryBrand : LinearGradient.cardGlow,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(
                        color: Color.cardShadow,
                        radius: isSelected ? 12 : 6,
                        x: 0,
                        y: isSelected ? 4 : 2
                    )
            )
        }
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

// MARK: - Credit Pack Card Component
struct CreditPackCard: View {
    let pack: CreditPack
    let geometry: GeometryProxy
    
    var body: some View {
        Button(action: {
            // Handle credit pack selection
        }) {
            HStack {
                VStack(alignment: .leading, spacing: adaptiveSpacing(4, for: geometry)) {
                    Text("\(pack.credits) Credits")
                        .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .semibold))
                        .foregroundColor(.deepPlum)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    if let savings = pack.savings {
                        Text(savings)
                            .font(.system(size: adaptiveFontSize(12, for: geometry), weight: .medium))
                            .foregroundStyle(LinearGradient.primaryBrand)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                
                Spacer()
                
                Text(pack.price)
                    .font(.system(size: adaptiveFontSize(20, for: geometry), weight: .bold))
                    .foregroundStyle(LinearGradient.primaryBrand)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(adaptiveSpacing(16, for: geometry))
            .background(
                RoundedRectangle(cornerRadius: adaptiveCornerRadius(12, for: geometry))
                    .fill(Color.pureWhite)
                    .overlay(
                        RoundedRectangle(cornerRadius: adaptiveCornerRadius(12, for: geometry))
                            .stroke(LinearGradient.cardGlow, lineWidth: 1)
                    )
                    .shadow(
                        color: Color.cardShadow,
                        radius: 8,
                        x: 0,
                        y: 2
                    )
            )
        }
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

// MARK: - Premium Background Component
struct PremiumBackground: View {
    @State private var animateGradient = false
    @State private var animateOrbs = false
    @State private var animateColors = false
    
    var body: some View {
        ZStack {
            // Base vibrant gradient matching HomeView
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
            
            // Dynamic floating orbs
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
            
            // Subtle overlay for text readability
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

#Preview {
    PaywallView(trigger: .general)
}
