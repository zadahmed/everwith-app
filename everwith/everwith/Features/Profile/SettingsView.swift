//
//  SettingsView.swift
//  EverWith
//
//  Settings screen with account, subscription, preferences, and legal sections
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var authService = AuthenticationService()
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var showSignOutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var isDarkMode = false
    @State private var notificationsEnabled = true
    @State private var animateElements = false
    
    var body: some View {
        GeometryReader { geometry in
            NavigationStack {
                ZStack {
                    CleanWhiteBackground()
                        .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: geometry.adaptiveSpacing(24)) {
                            // Account Section
                            SettingsSection(title: "Account", geometry: geometry) {
                                if let user = authService.currentUser {
                                    SettingsRow(
                                        icon: "person.circle.fill",
                                        title: "Email",
                                        value: user.email,
                                        geometry: geometry
                                    )
                                    
                                    SettingsRow(
                                        icon: "star.circle.fill",
                                        title: "Plan",
                                        value: subscriptionService.currentSubscription?.tier.capitalized ?? "Free",
                                        geometry: geometry
                                    )
                                    
                                    SettingsRow(
                                        icon: "creditcard.circle.fill",
                                        title: "Credits Remaining",
                                        value: "\(subscriptionService.userCredits?.creditsRemaining ?? 0)",
                                        geometry: geometry
                                    )
                                } else {
                                    Button(action: {
                                        // Navigate to sign in
                                    }) {
                                        HStack {
                                            Image(systemName: "person.badge.plus")
                                                .font(.system(size: geometry.adaptiveFontSize(18), weight: .semibold))
                                            Text("Sign In")
                                                .font(.system(size: geometry.adaptiveFontSize(16), weight: .semibold))
                                        }
                                        .foregroundStyle(LinearGradient.primaryBrand)
                                    }
                                    .padding(geometry.adaptiveSpacing(16))
                                }
                            }
                            
                            // Subscription Section
                            SettingsSection(title: "Subscription", geometry: geometry) {
                                NavigationLink {
                                    PaywallView()
                                } label: {
                                    SettingsNavRow(
                                        icon: "crown.fill",
                                        title: "Upgrade to Premium",
                                        iconColor: .honeyGold,
                                        geometry: geometry
                                    )
                                }
                                
                                Button(action: {
                                    Task {
                                        await restorePurchases()
                                    }
                                }) {
                                    SettingsNavRow(
                                        icon: "arrow.clockwise.circle.fill",
                                        title: "Restore Purchases",
                                        iconColor: .softPlum,
                                        geometry: geometry
                                    )
                                }
                            }
                            
                            // Preferences Section
                            SettingsSection(title: "Preferences", geometry: geometry) {
                                Toggle(isOn: $isDarkMode) {
                                    HStack(spacing: geometry.adaptiveSpacing(12)) {
                                        Image(systemName: "moon.circle.fill")
                                            .font(.system(size: geometry.adaptiveFontSize(20), weight: .medium))
                                            .foregroundColor(.deepPlum)
                                        
                                        Text("Dark Mode")
                                            .font(.system(size: geometry.adaptiveFontSize(16), weight: .medium))
                                            .foregroundColor(.deepPlum)
                                    }
                                }
                                .tint(Color.blushPink)
                                
                                Toggle(isOn: $notificationsEnabled) {
                                    HStack(spacing: geometry.adaptiveSpacing(12)) {
                                        Image(systemName: "bell.circle.fill")
                                            .font(.system(size: geometry.adaptiveFontSize(20), weight: .medium))
                                            .foregroundColor(.deepPlum)
                                        
                                        Text("Notifications")
                                            .font(.system(size: geometry.adaptiveFontSize(16), weight: .medium))
                                            .foregroundColor(.deepPlum)
                                    }
                                }
                                .tint(Color.blushPink)
                            }
                            
                            // Legal Section
                            SettingsSection(title: "Legal", geometry: geometry) {
                                NavigationLink {
                                    LegalView(type: .privacy)
                                } label: {
                                    SettingsNavRow(
                                        icon: "hand.raised.circle.fill",
                                        title: "Privacy Policy",
                                        iconColor: .softPlum,
                                        geometry: geometry
                                    )
                                }
                                
                                NavigationLink {
                                    LegalView(type: .terms)
                                } label: {
                                    SettingsNavRow(
                                        icon: "doc.text.circle.fill",
                                        title: "Terms of Service",
                                        iconColor: .softPlum,
                                        geometry: geometry
                                    )
                                }
                                
                                Button(action: {
                                    showDeleteAccountAlert = true
                                }) {
                                    SettingsNavRow(
                                        icon: "trash.circle.fill",
                                        title: "Delete Account",
                                        iconColor: .red,
                                        geometry: geometry
                                    )
                                }
                            }
                            
                            // Support Section
                            SettingsSection(title: "Support", geometry: geometry) {
                                NavigationLink {
                                    FeedbackView()
                                } label: {
                                    SettingsNavRow(
                                        icon: "envelope.circle.fill",
                                        title: "Contact Support",
                                        iconColor: .softPlum,
                                        geometry: geometry
                                    )
                                }
                            }
                            
                            // Version
                            Text("Version 1.0.0 (Build 1)")
                                .font(.system(size: geometry.adaptiveFontSize(14), weight: .regular))
                                .foregroundColor(.softPlum.opacity(0.6))
                                .padding(.top, geometry.adaptiveSpacing(8))
                            
                            // Sign Out Button
                            if authService.currentUser != nil {
                                Button(action: {
                                    showSignOutAlert = true
                                }) {
                                    Text("Sign Out")
                                        .font(.system(size: geometry.adaptiveFontSize(16), weight: .semibold))
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: geometry.adaptiveSize(48))
                                        .background(
                                            RoundedRectangle(cornerRadius: geometry.adaptiveCornerRadius(12))
                                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                        )
                                }
                                .padding(.horizontal, geometry.adaptivePadding())
                                .padding(.top, geometry.adaptiveSpacing(16))
                            }
                            
                            Spacer()
                                .frame(height: geometry.adaptiveSpacing(32))
                        }
                        .padding(.top, geometry.adaptiveSpacing(16))
                        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom + 16 : 24)
                    }
                }
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.large)
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authService.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    // Handle account deletion
                }
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
            .onAppear {
                Task {
                    await loadSubscriptionData()
                }
            }
        }
    }
    
    private func loadSubscriptionData() async {
        do {
            async let subscription = subscriptionService.fetchSubscriptionStatus()
            async let credits = subscriptionService.fetchUserCredits()
            _ = try await (subscription, credits)
        } catch {
            print("Failed to load subscription data: \(error)")
        }
    }
    
    private func restorePurchases() async {
        // In a real implementation, get receipt data from StoreKit
        do {
            let receiptData = "mock_receipt_data" // Replace with actual receipt
            _ = try await subscriptionService.restorePurchases(receiptData: receiptData)
        } catch {
            print("Failed to restore purchases: \(error)")
        }
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    let geometry: GeometryProxy
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: geometry.adaptiveSpacing(12)) {
            Text(title)
                .font(.system(size: geometry.adaptiveFontSize(14), weight: .semibold))
                .foregroundColor(.softPlum.opacity(0.7))
                .textCase(.uppercase)
                .padding(.horizontal, geometry.adaptivePadding())
            
            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: geometry.adaptiveCornerRadius(16))
                    .fill(Color.pureWhite)
                    .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
            )
            .padding(.horizontal, geometry.adaptivePadding())
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let title: String
    let value: String
    let geometry: GeometryProxy
    
    var body: some View {
        HStack(spacing: geometry.adaptiveSpacing(12)) {
            Image(systemName: icon)
                .font(.system(size: geometry.adaptiveFontSize(20), weight: .medium))
                .foregroundColor(.deepPlum)
            
            Text(title)
                .font(.system(size: geometry.adaptiveFontSize(16), weight: .medium))
                .foregroundColor(.deepPlum)
            
            Spacer()
            
            Text(value)
                .font(.system(size: geometry.adaptiveFontSize(15), weight: .regular))
                .foregroundColor(.softPlum)
        }
        .padding(geometry.adaptiveSpacing(16))
    }
}

// MARK: - Settings Nav Row
struct SettingsNavRow: View {
    let icon: String
    let title: String
    let iconColor: Color
    let geometry: GeometryProxy
    
    var body: some View {
        HStack(spacing: geometry.adaptiveSpacing(12)) {
            Image(systemName: icon)
                .font(.system(size: geometry.adaptiveFontSize(20), weight: .medium))
                .foregroundColor(iconColor)
            
            Text(title)
                .font(.system(size: geometry.adaptiveFontSize(16), weight: .medium))
                .foregroundColor(.deepPlum)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: geometry.adaptiveFontSize(14), weight: .semibold))
                .foregroundColor(.softPlum.opacity(0.5))
        }
        .padding(geometry.adaptiveSpacing(16))
    }
}

// MARK: - Legal View
struct LegalView: View {
    enum LegalType {
        case privacy, terms
    }
    
    let type: LegalType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: geometry.adaptiveSpacing(16)) {
                    Text(type == .privacy ? privacyPolicyText : termsOfServiceText)
                        .font(.system(size: geometry.adaptiveFontSize(15), weight: .regular))
                        .foregroundColor(.deepPlum)
                        .lineSpacing(4)
                }
                .padding(geometry.adaptivePadding())
            }
            .background(Color.warmLinen)
            .navigationTitle(type == .privacy ? "Privacy Policy" : "Terms of Service")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var privacyPolicyText: String {
        """
        Privacy Policy
        
        Last updated: October 2025
        
        At Everwith, we take your privacy seriously. This policy explains how we handle your data.
        
        Data Collection:
        - We only access photos you explicitly select for processing
        - Processed images are temporarily stored during creation
        - No photos are permanently stored without your consent
        
        Data Usage:
        - Images are processed using AI technology
        - Processing happens securely on our servers
        - Results are delivered back to your device
        
        Data Storage:
        - Original photos remain on your device
        - Processed images can be saved to your photo library
        - Cloud sync is optional and requires explicit permission
        
        Third Parties:
        - We use secure payment processors for purchases
        - Analytics data is anonymized and aggregated
        - No personal data is sold to third parties
        
        Your Rights:
        - Access your data at any time
        - Delete your account and all associated data
        - Export your created images
        
        Contact: privacy@everwith.app
        """
    }
    
    private var termsOfServiceText: String {
        """
        Terms of Service
        
        Last updated: October 2025
        
        By using Everwith, you agree to these terms.
        
        Service Description:
        - Everwith provides AI-powered photo restoration and merging
        - Results may vary based on input quality
        - Processing times depend on server load
        
        User Responsibilities:
        - Use the service for personal, non-commercial purposes
        - Own or have rights to photos you process
        - Do not process illegal or inappropriate content
        
        Subscriptions:
        - Premium features require active subscription
        - Subscriptions auto-renew unless cancelled
        - Cancel anytime through device settings
        
        Credits:
        - One-time credit purchases available
        - Credits never expire
        - Non-refundable once used
        
        Limitations:
        - Service provided "as is"
        - Results are not guaranteed
        - We reserve the right to modify features
        
        Termination:
        - You may delete your account at any time
        - We may suspend accounts violating these terms
        
        Contact: legal@everwith.app
        """
    }
}

#Preview {
    SettingsView()
}

