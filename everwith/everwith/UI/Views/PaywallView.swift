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
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with close button
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Main content
                    ScrollView {
                        VStack(spacing: 24) {
                            // Hero section
                            heroSection(geometry: geometry)
                            
                            // Features list
                            featuresSection
                            
                            // Pricing options
                            pricingSection(geometry: geometry)
                            
                            // Trial info
                            trialInfoSection
                            
                            // Action buttons
                            actionButtons(geometry: geometry)
                            
                            // Footer
                            footerSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await revenueCatService.updateSubscriptionStatus()
            }
        }
    }
    
    // MARK: - Hero Section
    @ViewBuilder
    private func heroSection(geometry: GeometryProxy) -> some View {
        VStack(spacing: 16) {
            // Result preview (if available)
            if case .postResult(let image) = trigger,
               let resultImage = image {
                Image(uiImage: resultImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .blur(radius: 2)
                    .overlay(
                        VStack {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                            Text("Unlock HD Quality")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(16)
                        .background(Color.black.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    )
            }
            
            // Main headline
            Text(heroHeadline)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            
            // Subheadline
            Text(heroSubheadline)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }
    
    // MARK: - Features Section
    private var featuresSection: some View {
        VStack(spacing: 16) {
            FeatureRow(
                icon: "bolt.fill",
                title: "Instant Processing",
                description: "Skip the queue, get results immediately"
            )
            
            FeatureRow(
                icon: "4k.tv",
                title: "4K HD Export",
                description: "Crystal clear quality for your memories"
            )
            
            FeatureRow(
                icon: "wand.and.stars",
                title: "Cinematic Filters",
                description: "Professional-grade photo enhancement"
            )
            
            FeatureRow(
                icon: "infinity",
                title: "Unlimited Usage",
                description: "Process as many photos as you want"
            )
            
            FeatureRow(
                icon: "checkmark.shield",
                title: "No Watermarks",
                description: "Clean, professional results"
            )
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Pricing Section
    @ViewBuilder
    private func pricingSection(geometry: GeometryProxy) -> some View {
        VStack(spacing: 16) {
            // Subscription vs Credits toggle
            HStack(spacing: 0) {
                Button(action: { showingCreditPacks = false }) {
                    Text("Subscription")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(showingCreditPacks ? .white.opacity(0.6) : .white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(showingCreditPacks ? Color.clear : Color.white.opacity(0.2))
                        )
                }
                
                Button(action: { showingCreditPacks = true }) {
                    Text("Pay-as-you-go")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(showingCreditPacks ? .white : .white.opacity(0.6))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(showingCreditPacks ? Color.white.opacity(0.2) : Color.clear)
                        )
                }
            }
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            if showingCreditPacks {
                creditPacksView
            } else {
                subscriptionPlansView
            }
        }
    }
    
    // MARK: - Subscription Plans
    private var subscriptionPlansView: some View {
        VStack(spacing: 12) {
            // Monthly Premium
            PricingCard(
                title: "Premium Monthly",
                price: "£9.99",
                period: "per month",
                features: ["Unlimited processing", "4K HD export", "Instant results", "All filters"],
                isSelected: selectedTier == .premiumMonthly,
                isPopular: false
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
                isPopular: true
            ) {
                selectedTier = .premiumYearly
            }
        }
    }
    
    // MARK: - Credit Packs
    private var creditPacksView: some View {
        VStack(spacing: 12) {
            ForEach(CreditPack.packs) { pack in
                CreditPackCard(pack: pack)
            }
        }
    }
    
    // MARK: - Trial Info
    private var trialInfoSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "gift.fill")
                    .foregroundColor(.yellow)
                Text("Try Premium free for 3 days")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text("Cancel anytime. No commitment.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Action Buttons
    @ViewBuilder
    private func actionButtons(geometry: GeometryProxy) -> some View {
        VStack(spacing: 12) {
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
                HStack {
                    if revenueCatService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            .scaleEffect(0.8)
                    } else {
                        Text(primaryButtonText)
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.yellow)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(revenueCatService.isLoading)
            
            // Secondary action button
            Button(action: { dismiss() }) {
                Text("Keep Free Version")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
        }
    }
    
    // MARK: - Footer
    private var footerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 20) {
                Button("Restore Purchases") {
                    Task {
                        await revenueCatService.restorePurchases()
                    }
                }
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                
                Button("Terms of Service") {
                    // Show terms
                }
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                
                Button("Privacy Policy") {
                    // Show privacy policy
                }
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
            }
            
            Text("Subscriptions auto-renew unless cancelled")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
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
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.yellow)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
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
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        HStack(alignment: .bottom, spacing: 4) {
                            Text(price)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(period)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    if isPopular {
                        Text("POPULAR")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.yellow)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(features, id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                            
                            Text(feature)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

// MARK: - Credit Pack Card Component
struct CreditPackCard: View {
    let pack: CreditPack
    
    var body: some View {
        Button(action: {
            // Handle credit pack selection
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(pack.credits) Credits")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if let savings = pack.savings {
                        Text(savings)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                Text(pack.price)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
        }
    }
}

#Preview {
    PaywallView(trigger: .general)
}
