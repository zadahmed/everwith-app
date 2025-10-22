//
//  PaywallView.swift
//  EverWith
//
//  Subscription and paywall screen
//

import SwiftUI

struct PaywallView: View {
    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var animateElements = false
    @State private var showPurchaseSuccess = false
    @State private var isPurchasing = false
    
    enum SubscriptionPlan {
        case monthly, yearly, lifetime
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Premium Background
                PremiumBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: geometry.adaptiveSpacing(32)) {
                        // Header
                        VStack(spacing: geometry.adaptiveSpacing(16)) {
                            // Crown Icon
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.honeyGold.opacity(0.3),
                                                Color.honeyGold.opacity(0.1)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: geometry.adaptiveSize(100), height: geometry.adaptiveSize(100))
                                    .blur(radius: 20)
                                
                                Image(systemName: "crown.fill")
                                    .font(.system(size: geometry.adaptiveFontSize(48), weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.honeyGold,
                                                Color.honeyGold.opacity(0.8)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            .scaleEffect(animateElements ? 1.0 : 0.8)
                            
                            Text("Make Every Memory HD")
                                .font(.system(size: geometry.adaptiveFontSize(32), weight: .bold, design: .rounded))
                                .foregroundColor(.deepPlum)
                                .multilineTextAlignment(.center)
                                .opacity(animateElements ? 1.0 : 0.0)
                            
                            Text("Unlock unlimited photo restoration and memory creation")
                                .font(.system(size: geometry.adaptiveFontSize(17), weight: .medium))
                                .foregroundColor(.softPlum)
                                .multilineTextAlignment(.center)
                                .opacity(animateElements ? 1.0 : 0.0)
                        }
                        .padding(.horizontal, geometry.adaptivePadding())
                        .padding(.top, geometry.safeAreaInsets.top > 0 ? geometry.safeAreaInsets.top + 16 : 32)
                        
                        // Features List
                        VStack(spacing: geometry.adaptiveSpacing(16)) {
                            PremiumFeatureRow(
                                icon: "infinity",
                                title: "Unlimited Restores & Merges",
                                description: "Process as many photos as you want",
                                geometry: geometry
                            )
                            
                            PremiumFeatureRow(
                                icon: "sparkles",
                                title: "4K HD Exports",
                                description: "Highest quality output available",
                                geometry: geometry
                            )
                            
                            PremiumFeatureRow(
                                icon: "bolt.fill",
                                title: "Instant Results",
                                description: "Priority processing queue",
                                geometry: geometry
                            )
                            
                            PremiumFeatureRow(
                                icon: "eye.slash.fill",
                                title: "No Watermark",
                                description: "Clean, professional results",
                                geometry: geometry
                            )
                            
                            PremiumFeatureRow(
                                icon: "wand.and.stars",
                                title: "Cinematic Filters Unlocked",
                                description: "Access all premium filters",
                                geometry: geometry
                            )
                        }
                        .padding(.horizontal, geometry.adaptivePadding())
                        .opacity(animateElements ? 1.0 : 0.0)
                        
                        // Subscription Plans
                        VStack(spacing: geometry.adaptiveSpacing(12)) {
                            // Yearly Plan (Most Popular)
                            SubscriptionPlanCard(
                                isSelected: selectedPlan == .yearly,
                                badge: "BEST VALUE",
                                title: "Yearly",
                                price: "£29.99",
                                period: "/year",
                                savings: "Save 58%",
                                pricePerMonth: "Just £2.50/month",
                                onTap: { selectedPlan = .yearly },
                                geometry: geometry
                            )
                            
                            // Monthly Plan
                            SubscriptionPlanCard(
                                isSelected: selectedPlan == .monthly,
                                title: "Monthly",
                                price: "£5.99",
                                period: "/month",
                                pricePerMonth: "Billed monthly",
                                onTap: { selectedPlan = .monthly },
                                geometry: geometry
                            )
                            
                            // Lifetime Plan
                            SubscriptionPlanCard(
                                isSelected: selectedPlan == .lifetime,
                                badge: "ONE-TIME",
                                title: "Lifetime Access",
                                price: "£79.99",
                                period: "forever",
                                pricePerMonth: "Pay once, use forever",
                                onTap: { selectedPlan = .lifetime },
                                geometry: geometry
                            )
                        }
                        .padding(.horizontal, geometry.adaptivePadding())
                        .opacity(animateElements ? 1.0 : 0.0)
                        
                        // CTA Buttons
                        VStack(spacing: geometry.adaptiveSpacing(16)) {
                            // Start Free Trial Button
                            if selectedPlan != .lifetime {
                                Button(action: {
                                    handlePurchase()
                                }) {
                                    HStack(spacing: geometry.adaptiveSpacing(12)) {
                                        if isPurchasing {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        } else {
                                            Text(selectedPlan == .yearly ? "Start 7-Day Free Trial" : "Start Free Trial")
                                                .font(.system(size: geometry.adaptiveFontSize(17), weight: .semibold))
                                            
                                            Image(systemName: "arrow.right")
                                                .font(.system(size: geometry.adaptiveFontSize(16), weight: .semibold))
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: geometry.adaptiveSize(56))
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.blushPink,
                                                Color.roseMagenta
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(geometry.adaptiveCornerRadius(16))
                                    .shadow(color: Color.blushPink.opacity(0.4), radius: 12, x: 0, y: 6)
                                }
                                .disabled(isPurchasing)
                            } else {
                                Button(action: {
                                    handlePurchase()
                                }) {
                                    HStack(spacing: geometry.adaptiveSpacing(12)) {
                                        if isPurchasing {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        } else {
                                            Text("Buy Lifetime Access")
                                                .font(.system(size: geometry.adaptiveFontSize(17), weight: .semibold))
                                            
                                            Image(systemName: "arrow.right")
                                                .font(.system(size: geometry.adaptiveFontSize(16), weight: .semibold))
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: geometry.adaptiveSize(56))
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.honeyGold,
                                                Color.honeyGold.opacity(0.8)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(geometry.adaptiveCornerRadius(16))
                                    .shadow(color: Color.honeyGold.opacity(0.4), radius: 12, x: 0, y: 6)
                                }
                                .disabled(isPurchasing)
                            }
                            
                            // Restore Purchases
                            Button(action: {
                                // Handle restore purchases
                            }) {
                                Text("Restore Purchases")
                                    .font(.system(size: geometry.adaptiveFontSize(15), weight: .medium))
                                    .foregroundColor(.softPlum)
                            }
                            
                            // Fine Print
                            Text("Cancel anytime in Settings. No commitment.")
                                .font(.system(size: geometry.adaptiveFontSize(13), weight: .regular))
                                .foregroundColor(.softPlum.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, geometry.adaptivePadding())
                        
                        Spacer()
                            .frame(height: geometry.adaptiveSpacing(32))
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom + 16 : 24)
                }
                .opacity(animateElements ? 1.0 : 0.0)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Premium")
            .sheet(isPresented: $showPurchaseSuccess) {
                PurchaseSuccessView()
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                    animateElements = true
                }
            }
        }
    }
    
    private func handlePurchase() {
        isPurchasing = true
        
        // Simulate purchase
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isPurchasing = false
            showPurchaseSuccess = true
        }
    }
}

// MARK: - Premium Background
struct PremiumBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.pureWhite,
                    Color.lightBlush.opacity(0.15),
                    Color.blushPink.opacity(0.1)
                ]),
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .animation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true), value: animateGradient)
            
            // Floating orbs
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                [Color.blushPink, Color.honeyGold, Color.roseMagenta, Color.lightBlush][index].opacity(0.15),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: CGFloat(100 + index * 60), height: CGFloat(100 + index * 60))
                    .offset(
                        x: CGFloat(-100 + index * 100),
                        y: CGFloat(-150 + index * 120)
                    )
                    .blur(radius: 20)
                    .opacity(0.6)
            }
        }
        .onAppear {
            animateGradient = true
        }
    }
}

// MARK: - Premium Feature Row
struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let geometry: GeometryProxy
    
    var body: some View {
        HStack(spacing: geometry.adaptiveSpacing(16)) {
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
                    .frame(width: geometry.adaptiveSize(48), height: geometry.adaptiveSize(48))
                
                Image(systemName: icon)
                    .font(.system(size: geometry.adaptiveFontSize(20), weight: .semibold))
                    .foregroundStyle(LinearGradient.primaryBrand)
            }
            
            VStack(alignment: .leading, spacing: geometry.adaptiveSpacing(4)) {
                Text(title)
                    .font(.system(size: geometry.adaptiveFontSize(16), weight: .semibold))
                    .foregroundColor(.deepPlum)
                
                Text(description)
                    .font(.system(size: geometry.adaptiveFontSize(14), weight: .regular))
                    .foregroundColor(.softPlum)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: geometry.adaptiveFontSize(24)))
                .foregroundColor(.blushPink)
        }
        .padding(geometry.adaptiveSpacing(16))
        .background(
            RoundedRectangle(cornerRadius: geometry.adaptiveCornerRadius(16))
                .fill(Color.pureWhite)
                .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Subscription Plan Card
struct SubscriptionPlanCard: View {
    let isSelected: Bool
    var badge: String? = nil
    let title: String
    let price: String
    let period: String
    var savings: String? = nil
    let pricePerMonth: String
    let onTap: () -> Void
    let geometry: GeometryProxy
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: geometry.adaptiveSpacing(12)) {
                // Badge if present
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: geometry.adaptiveFontSize(11), weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, geometry.adaptiveSpacing(8))
                        .padding(.vertical, geometry.adaptiveSpacing(4))
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.blushPink,
                                            Color.roseMagenta
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: geometry.adaptiveSpacing(4)) {
                        Text(title)
                            .font(.system(size: geometry.adaptiveFontSize(18), weight: .bold))
                            .foregroundColor(.deepPlum)
                        
                        HStack(alignment: .firstTextBaseline, spacing: geometry.adaptiveSpacing(4)) {
                            Text(price)
                                .font(.system(size: geometry.adaptiveFontSize(28), weight: .bold))
                                .foregroundColor(.deepPlum)
                            
                            Text(period)
                                .font(.system(size: geometry.adaptiveFontSize(16), weight: .medium))
                                .foregroundColor(.softPlum)
                        }
                        
                        if let savings = savings {
                            Text(savings)
                                .font(.system(size: geometry.adaptiveFontSize(13), weight: .semibold))
                                .foregroundColor(.blushPink)
                        }
                        
                        Text(pricePerMonth)
                            .font(.system(size: geometry.adaptiveFontSize(14), weight: .regular))
                            .foregroundColor(.softPlum)
                    }
                    
                    Spacer()
                    
                    // Selection Indicator
                    ZStack {
                        Circle()
                            .stroke(isSelected ? LinearGradient.primaryBrand : LinearGradient(colors: [Color.softPlum.opacity(0.3)], startPoint: .leading, endPoint: .trailing), lineWidth: 2)
                            .frame(width: geometry.adaptiveSize(28), height: geometry.adaptiveSize(28))
                        
                        if isSelected {
                            Circle()
                                .fill(LinearGradient.primaryBrand)
                                .frame(width: geometry.adaptiveSize(16), height: geometry.adaptiveSize(16))
                        }
                    }
                }
            }
            .padding(geometry.adaptiveSpacing(20))
            .background(
                RoundedRectangle(cornerRadius: geometry.adaptiveCornerRadius(16))
                    .fill(Color.pureWhite)
                    .overlay(
                        RoundedRectangle(cornerRadius: geometry.adaptiveCornerRadius(16))
                            .stroke(
                                isSelected ? LinearGradient.primaryBrand : LinearGradient(colors: [Color.subtleBorder], startPoint: .leading, endPoint: .trailing),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ? Color.blushPink.opacity(0.3) : Color.cardShadow,
                        radius: isSelected ? 12 : 4,
                        x: 0,
                        y: isSelected ? 6 : 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    NavigationStack {
        PaywallView()
    }
}

