//
//  CreditStoreView.swift
//  EverWith
//
//  Credit store for one-time purchases
//

import SwiftUI

struct CreditStoreView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPackage: CreditPackage? = nil
    @State private var animateElements = false
    @State private var isPurchasing = false
    @State private var showPurchaseSuccess = false
    
    struct CreditPackage: Identifiable {
        let id = UUID()
        let credits: Int
        let price: String
        let priceValue: Double
        var badge: String? = nil
        var isBestValue: Bool = false
    }
    
    let packages: [CreditPackage] = [
        CreditPackage(credits: 5, price: "£4.99", priceValue: 4.99),
        CreditPackage(credits: 15, price: "£9.99", priceValue: 9.99, badge: "POPULAR", isBestValue: true),
        CreditPackage(credits: 50, price: "£24.99", priceValue: 24.99, badge: "BEST VALUE")
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CleanWhiteBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: geometry.adaptiveSpacing(32)) {
                        // Header
                        VStack(spacing: geometry.adaptiveSpacing(16)) {
                            // Credit Icon
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
                                
                                Image(systemName: "star.circle.fill")
                                    .font(.system(size: geometry.adaptiveFontSize(56), weight: .bold))
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
                            
                            Text("Buy Processing Credits")
                                .font(.system(size: geometry.adaptiveFontSize(32), weight: .bold, design: .rounded))
                                .foregroundColor(.deepPlum)
                                .multilineTextAlignment(.center)
                                .opacity(animateElements ? 1.0 : 0.0)
                            
                            Text("1 credit = 1 photo processed\nCredits never expire")
                                .font(.system(size: geometry.adaptiveFontSize(17), weight: .medium))
                                .foregroundColor(.softPlum)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .opacity(animateElements ? 1.0 : 0.0)
                        }
                        .padding(.horizontal, geometry.adaptivePadding())
                        .padding(.top, geometry.safeAreaInsets.top > 0 ? geometry.safeAreaInsets.top + 16 : 32)
                        
                        // Credit Packages
                        VStack(spacing: geometry.adaptiveSpacing(16)) {
                            ForEach(packages) { package in
                                CreditPackageCard(
                                    package: package,
                                    isSelected: selectedPackage?.id == package.id,
                                    onTap: { selectedPackage = package },
                                    geometry: geometry
                                )
                            }
                        }
                        .padding(.horizontal, geometry.adaptivePadding())
                        .opacity(animateElements ? 1.0 : 0.0)
                        
                        // Info Section
                        VStack(alignment: .leading, spacing: geometry.adaptiveSpacing(12)) {
                            HStack(spacing: geometry.adaptiveSpacing(12)) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: geometry.adaptiveFontSize(20)))
                                    .foregroundColor(.blushPink)
                                
                                Text("Credits never expire")
                                    .font(.system(size: geometry.adaptiveFontSize(15), weight: .medium))
                                    .foregroundColor(.deepPlum)
                            }
                            
                            HStack(spacing: geometry.adaptiveSpacing(12)) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: geometry.adaptiveFontSize(20)))
                                    .foregroundColor(.blushPink)
                                
                                Text("Use for any photo mode")
                                    .font(.system(size: geometry.adaptiveFontSize(15), weight: .medium))
                                    .foregroundColor(.deepPlum)
                            }
                            
                            HStack(spacing: geometry.adaptiveSpacing(12)) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: geometry.adaptiveFontSize(20)))
                                    .foregroundColor(.blushPink)
                                
                                Text("No subscription required")
                                    .font(.system(size: geometry.adaptiveFontSize(15), weight: .medium))
                                    .foregroundColor(.deepPlum)
                            }
                        }
                        .padding(geometry.adaptiveSpacing(20))
                        .background(
                            RoundedRectangle(cornerRadius: geometry.adaptiveCornerRadius(16))
                                .fill(Color.lightBlush.opacity(0.15))
                        )
                        .padding(.horizontal, geometry.adaptivePadding())
                        .opacity(animateElements ? 1.0 : 0.0)
                        
                        // Purchase Button
                        if let selected = selectedPackage {
                            Button(action: {
                                handlePurchase()
                            }) {
                                HStack(spacing: geometry.adaptiveSpacing(12)) {
                                    if isPurchasing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Purchase \(selected.credits) Credits")
                                            .font(.system(size: geometry.adaptiveFontSize(17), weight: .semibold))
                                        
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: geometry.adaptiveFontSize(16), weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: geometry.adaptiveSize(56))
                                .background(LinearGradient.primaryBrand)
                                .cornerRadius(geometry.adaptiveCornerRadius(16))
                                .shadow(color: Color.blushPink.opacity(0.4), radius: 12, x: 0, y: 6)
                            }
                            .disabled(isPurchasing)
                            .padding(.horizontal, geometry.adaptivePadding())
                            .opacity(animateElements ? 1.0 : 0.0)
                        }
                        
                        // Alternative Option
                        VStack(spacing: geometry.adaptiveSpacing(8)) {
                            Text("Want unlimited processing?")
                                .font(.system(size: geometry.adaptiveFontSize(15), weight: .medium))
                                .foregroundColor(.softPlum)
                            
                            NavigationLink {
                                PaywallView(trigger: .general)
                            } label: {
                                Text("View Premium Plans")
                                    .font(.system(size: geometry.adaptiveFontSize(16), weight: .semibold))
                                    .foregroundStyle(LinearGradient.primaryBrand)
                            }
                        }
                        .opacity(animateElements ? 1.0 : 0.0)
                        
                        Spacer()
                            .frame(height: geometry.adaptiveSpacing(32))
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom + 16 : 24)
                }
            }
            .navigationTitle("Credits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: geometry.adaptiveFontSize(24)))
                            .foregroundColor(.softPlum)
                    }
                }
            }
            .sheet(isPresented: $showPurchaseSuccess) {
                PurchaseSuccessView(creditCount: selectedPackage?.credits)
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

// MARK: - Credit Package Card
struct CreditPackageCard: View {
    let package: CreditStoreView.CreditPackage
    let isSelected: Bool
    let onTap: () -> Void
    let geometry: GeometryProxy
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: geometry.adaptiveSpacing(12)) {
                // Badge if present
                if let badge = package.badge {
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
                                            package.isBestValue ? Color.honeyGold : Color.blushPink,
                                            package.isBestValue ? Color.honeyGold.opacity(0.8) : Color.roseMagenta
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                
                HStack(alignment: .center) {
                    // Credit Count
                    HStack(alignment: .firstTextBaseline, spacing: geometry.adaptiveSpacing(8)) {
                        Text("\(package.credits)")
                            .font(.system(size: geometry.adaptiveFontSize(48), weight: .bold))
                            .foregroundColor(.deepPlum)
                        
                        VStack(alignment: .leading, spacing: geometry.adaptiveSpacing(2)) {
                            Text("Credits")
                                .font(.system(size: geometry.adaptiveFontSize(16), weight: .semibold))
                                .foregroundColor(.deepPlum)
                            
                            Text("\(String(format: "£%.2f", package.priceValue / Double(package.credits))) each")
                                .font(.system(size: geometry.adaptiveFontSize(13), weight: .regular))
                                .foregroundColor(.softPlum)
                        }
                    }
                    
                    Spacer()
                    
                    // Price
                    VStack(alignment: .trailing, spacing: geometry.adaptiveSpacing(4)) {
                        Text(package.price)
                            .font(.system(size: geometry.adaptiveFontSize(24), weight: .bold))
                            .foregroundColor(.deepPlum)
                        
                        // Selection Indicator
                        ZStack {
                            Circle()
                                .stroke(isSelected ? LinearGradient.primaryBrand : LinearGradient(colors: [Color.softPlum.opacity(0.3)], startPoint: .leading, endPoint: .trailing), lineWidth: 2)
                                .frame(width: geometry.adaptiveSize(24), height: geometry.adaptiveSize(24))
                            
                            if isSelected {
                                Circle()
                                    .fill(LinearGradient.primaryBrand)
                                    .frame(width: geometry.adaptiveSize(14), height: geometry.adaptiveSize(14))
                            }
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
        CreditStoreView()
    }
}

