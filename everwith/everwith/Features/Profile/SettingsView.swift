//
//  SettingsView.swift
//  EverWith
//
//  Settings screen with account, subscription, preferences, and legal sections
//

import SwiftUI
import Foundation

struct SettingsView: View {
    @StateObject private var authService = AuthenticationService()
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var showSignOutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showSignInView = false
    @State private var isDarkMode = false
    @State private var notificationsEnabled = true
    @State private var animateElements = false
    @State private var isLoading = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Clean background
                CleanWhiteBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Consistent Header
                    ModernPageHeader(title: "Settings", geometry: geometry)
                    
                    // Main Content
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: adaptiveSpacing(24, for: geometry)) {
                            // Account Section
                            AccountSection(
                                authService: authService,
                                subscriptionService: subscriptionService,
                                showSignInView: $showSignInView,
                                geometry: geometry
                            )
                            
                            // Subscription Section
                            SubscriptionSection(geometry: geometry)
                            
                            // Preferences Section
                            PreferencesSection(
                                isDarkMode: $isDarkMode,
                                notificationsEnabled: $notificationsEnabled,
                                geometry: geometry
                            )
                            
                            // Support Section
                            SupportSection(geometry: geometry)
                            
                            // Legal Section
                            LegalSection(
                                showDeleteAccountAlert: $showDeleteAccountAlert,
                                geometry: geometry
                            )
                            
                            // Version Info
                            VersionSection(geometry: geometry)
                            
                            // Sign Out Button
                            if authService.currentUser != nil {
                                SignOutSection(
                                    showSignOutAlert: $showSignOutAlert,
                                    geometry: geometry
                                )
                            }
                            
                            // Bottom spacing
                            Spacer()
                                .frame(height: adaptiveSpacing(8, for: geometry))
                        }
                        .padding(.horizontal, adaptivePadding(for: geometry))
                        .padding(.top, adaptiveSpacing(16, for: geometry))
                        .padding(.bottom, adaptiveSpacing(8, for: geometry))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showSignInView) {
            ModernAuthenticationView()
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
                Task {
                    await deleteAccount()
                }
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
        .onAppear {
            Task {
                await loadSubscriptionData()
            }
            withAnimation(.easeOut(duration: 0.6)) {
                animateElements = true
            }
        }
    }
    
    // MARK: - Private Methods
    private func loadSubscriptionData() async {
        isLoading = true
        do {
            async let subscription = subscriptionService.fetchSubscriptionStatus()
            async let credits = subscriptionService.fetchUserCredits()
            _ = try await (subscription, credits)
        } catch {
            print("Failed to load subscription data: \(error)")
        }
        isLoading = false
    }
    
    private func restorePurchases() async {
        do {
            let receiptData = "mock_receipt_data" // Replace with actual receipt
            _ = try await subscriptionService.restorePurchases(receiptData: receiptData)
        } catch {
            print("Failed to restore purchases: \(error)")
        }
    }
    
    private func deleteAccount() async {
        // Implement account deletion logic
        do {
            // Call API to delete account
            print("Account deletion requested")
        } catch {
            print("Failed to delete account: \(error)")
        }
    }
    
// MARK: - Adaptive Functions
private func adaptivePadding(for geometry: GeometryProxy) -> CGFloat {
    let screenWidth = geometry.size.width
        return max(12, min(20, screenWidth * 0.05))
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

private func adaptiveCornerRadius(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
    let screenWidth = geometry.size.width
    let scaleFactor = screenWidth / 375.0
    return base * scaleFactor
}

private func adaptiveSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
    let screenWidth = geometry.size.width
    let scaleFactor = screenWidth / 375.0
    return base * scaleFactor
    }
}


// MARK: - Account Section
struct AccountSection: View {
    @ObservedObject var authService: AuthenticationService
    @ObservedObject var subscriptionService: SubscriptionService
    @Binding var showSignInView: Bool
    let geometry: GeometryProxy
    
    var body: some View {
        ModernSettingsCard(title: "Account", geometry: geometry) {
                                    if let user = authService.currentUser {
                AccountInfoRow(
                                            icon: "person.circle.fill",
                                            title: "Email",
                                            value: user.email,
                                            geometry: geometry
                                        )
                                        
                Divider()
                    .background(Color.subtleBorder)
                    .padding(.horizontal, adaptiveSpacing(16, for: geometry))
                
                AccountInfoRow(
                                            icon: "star.circle.fill",
                                            title: "Plan",
                                            value: subscriptionService.currentSubscription?.tier.capitalized ?? "Free",
                                            geometry: geometry
                                        )
                                        
                Divider()
                    .background(Color.subtleBorder)
                    .padding(.horizontal, adaptiveSpacing(16, for: geometry))
                
                AccountInfoRow(
                                            icon: "creditcard.circle.fill",
                    title: "Credits",
                                            value: "\(subscriptionService.userCredits?.creditsRemaining ?? 0)",
                                            geometry: geometry
                                        )
                                    } else {
                SignInPrompt(showSignInView: $showSignInView, geometry: geometry)
            }
        }
    }
    
    private func adaptiveSpacing(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
}

// MARK: - Subscription Section
struct SubscriptionSection: View {
    let geometry: GeometryProxy
    
    var body: some View {
        ModernSettingsCard(title: "Subscription", geometry: geometry) {
                                    NavigationLink {
                                        PaywallView(trigger: .general)
                                    } label: {
                SettingsActionRow(
                                            icon: "crown.fill",
                                            title: "Upgrade to Premium",
                                            iconColor: .honeyGold,
                                            geometry: geometry
                                        )
                                    }
                                    
            Divider()
                .background(Color.subtleBorder)
                .padding(.horizontal, adaptiveSpacing(16, for: geometry))
            
                                    Button(action: {
                                        Task {
                                            await restorePurchases()
                                        }
                                    }) {
                SettingsActionRow(
                                            icon: "arrow.clockwise.circle.fill",
                                            title: "Restore Purchases",
                                            iconColor: .softPlum,
                                            geometry: geometry
                                        )
                                    }
                                }
    }
    
    private func restorePurchases() async {
        // Implement restore purchases
        print("Restoring purchases...")
    }
    
    private func adaptiveSpacing(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
}

// MARK: - Preferences Section
struct PreferencesSection: View {
    @Binding var isDarkMode: Bool
    @Binding var notificationsEnabled: Bool
    let geometry: GeometryProxy
    
    var body: some View {
        ModernSettingsCard(title: "Preferences", geometry: geometry) {
            SettingsToggleRow(
                icon: "moon.circle.fill",
                title: "Dark Mode",
                isOn: $isDarkMode,
                geometry: geometry
            )
            
            Divider()
                .background(Color.subtleBorder)
                .padding(.horizontal, adaptiveSpacing(16, for: geometry))
            
            SettingsToggleRow(
                icon: "bell.circle.fill",
                title: "Notifications",
                isOn: $notificationsEnabled,
                geometry: geometry
            )
        }
    }
    
    private func adaptiveSpacing(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
}

// MARK: - Support Section
struct SupportSection: View {
    let geometry: GeometryProxy
    
    var body: some View {
        ModernSettingsCard(title: "Support", geometry: geometry) {
            NavigationLink {
                FeedbackView()
            } label: {
                SettingsActionRow(
                    icon: "envelope.circle.fill",
                    title: "Contact Support",
                    iconColor: .softPlum,
                    geometry: geometry
                )
            }
        }
    }
}

// MARK: - Legal Section
struct LegalSection: View {
    @Binding var showDeleteAccountAlert: Bool
    let geometry: GeometryProxy
    
    var body: some View {
        ModernSettingsCard(title: "Legal", geometry: geometry) {
                                    NavigationLink {
                                        LegalView(type: .privacy)
                                    } label: {
                SettingsActionRow(
                                            icon: "hand.raised.circle.fill",
                                            title: "Privacy Policy",
                                            iconColor: .softPlum,
                                            geometry: geometry
                                        )
                                    }
                                    
            Divider()
                .background(Color.subtleBorder)
                .padding(.horizontal, adaptiveSpacing(16, for: geometry))
            
                                    NavigationLink {
                                        LegalView(type: .terms)
                                    } label: {
                SettingsActionRow(
                                            icon: "doc.text.circle.fill",
                                            title: "Terms of Service",
                                            iconColor: .softPlum,
                                            geometry: geometry
                                        )
                                    }
                                    
            Divider()
                .background(Color.subtleBorder)
                .padding(.horizontal, adaptiveSpacing(16, for: geometry))
            
                                    Button(action: {
                                        showDeleteAccountAlert = true
                                    }) {
                SettingsActionRow(
                                            icon: "trash.circle.fill",
                                            title: "Delete Account",
                                            iconColor: .red,
                                            geometry: geometry
                                        )
            }
        }
    }
    
    private func adaptiveSpacing(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
}

// MARK: - Version Section
struct VersionSection: View {
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: adaptiveSpacing(8, for: geometry)) {
            Text("Version 1.0.0")
                .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                .foregroundColor(.deepPlum)
            
            Text("Build 1")
                                    .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .regular))
                .foregroundColor(.softPlum.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, adaptiveSpacing(16, for: geometry))
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
}

// MARK: - Sign Out Section
struct SignOutSection: View {
    @Binding var showSignOutAlert: Bool
    let geometry: GeometryProxy
    
    var body: some View {
                                    Button(action: {
                                        showSignOutAlert = true
                                    }) {
                                        Text("Sign Out")
                                            .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .semibold))
                                            .foregroundColor(.red)
                                            .frame(maxWidth: .infinity)
                .frame(height: adaptiveSize(52, for: geometry))
                                            .background(
                    RoundedRectangle(cornerRadius: adaptiveCornerRadius(16, for: geometry))
                        .fill(Color.red.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: adaptiveCornerRadius(16, for: geometry))
                                .stroke(Color.red.opacity(0.2), lineWidth: 1)
                        )
                )
        }
        .padding(.top, adaptiveSpacing(8, for: geometry))
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
    
    private func adaptiveSpacing(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
}

// MARK: - Modern Settings Card
struct ModernSettingsCard<Content: View>: View {
    let title: String
    let geometry: GeometryProxy
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: adaptiveSpacing(12, for: geometry)) {
            Text(title)
                .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .semibold))
                .foregroundColor(.softPlum.opacity(0.8))
                .textCase(.uppercase)
                .tracking(0.5)
            
            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: adaptiveCornerRadius(20, for: geometry))
                    .fill(Color.pureWhite)
                    .shadow(
                        color: Color.cardShadow,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
        }
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
    
    private func adaptiveCornerRadius(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
}

// MARK: - Account Info Row
struct AccountInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let geometry: GeometryProxy
    
    var body: some View {
        HStack(spacing: adaptiveSpacing(16, for: geometry)) {
            Image(systemName: icon)
                .font(.system(size: adaptiveFontSize(20, for: geometry), weight: .medium))
                .foregroundColor(.deepPlum)
                .frame(width: adaptiveSize(24, for: geometry))
            
            Text(title)
                .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                .foregroundColor(.deepPlum)
            
            Spacer()
            
            Text(value)
                .font(.system(size: adaptiveFontSize(15, for: geometry), weight: .regular))
                .foregroundColor(.softPlum)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, adaptiveSpacing(20, for: geometry))
        .padding(.vertical, adaptiveSpacing(16, for: geometry))
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

// MARK: - Sign In Prompt
struct SignInPrompt: View {
    @Binding var showSignInView: Bool
    let geometry: GeometryProxy
    
    var body: some View {
        Button(action: {
            showSignInView = true
        }) {
            HStack(spacing: adaptiveSpacing(12, for: geometry)) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .semibold))
                    .foregroundStyle(LinearGradient.primaryBrand)
                
                Text("Sign In to View Account")
                    .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .semibold))
                    .foregroundStyle(LinearGradient.primaryBrand)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .semibold))
                    .foregroundStyle(LinearGradient.primaryBrand)
            }
            .padding(.horizontal, adaptiveSpacing(20, for: geometry))
            .padding(.vertical, adaptiveSpacing(18, for: geometry))
            .background(
                RoundedRectangle(cornerRadius: adaptiveCornerRadius(12, for: geometry))
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blushPink.opacity(0.1),
                                Color.roseMagenta.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: adaptiveCornerRadius(12, for: geometry))
                            .stroke(LinearGradient.primaryBrand, lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, adaptiveSpacing(20, for: geometry))
        .padding(.vertical, adaptiveSpacing(16, for: geometry))
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
    
    private func adaptiveCornerRadius(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
}

// MARK: - Settings Action Row
struct SettingsActionRow: View {
    let icon: String
    let title: String
    let iconColor: Color
    let geometry: GeometryProxy
    
    var body: some View {
        HStack(spacing: adaptiveSpacing(16, for: geometry)) {
            Image(systemName: icon)
                .font(.system(size: adaptiveFontSize(20, for: geometry), weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: adaptiveSize(24, for: geometry))
            
            Text(title)
                .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                .foregroundColor(.deepPlum)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .semibold))
                .foregroundColor(.softPlum.opacity(0.5))
        }
        .padding(.horizontal, adaptiveSpacing(20, for: geometry))
        .padding(.vertical, adaptiveSpacing(16, for: geometry))
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

// MARK: - Settings Toggle Row
struct SettingsToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    let geometry: GeometryProxy
    
    var body: some View {
        HStack(spacing: adaptiveSpacing(16, for: geometry)) {
            Image(systemName: icon)
                .font(.system(size: adaptiveFontSize(20, for: geometry), weight: .medium))
                .foregroundColor(.deepPlum)
                .frame(width: adaptiveSize(24, for: geometry))
            
            Text(title)
                .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                .foregroundColor(.deepPlum)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(Color.blushPink)
        }
        .padding(.horizontal, adaptiveSpacing(20, for: geometry))
        .padding(.vertical, adaptiveSpacing(16, for: geometry))
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

// MARK: - Legal View
struct LegalView: View {
    enum LegalType {
        case privacy, terms
    }
    
    let type: LegalType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CleanWhiteBackground()
                    .ignoresSafeArea()
                
            ScrollView {
                    VStack(alignment: .leading, spacing: adaptiveSpacing(20, for: geometry)) {
                    Text(type == .privacy ? privacyPolicyText : termsOfServiceText)
                        .font(.system(size: adaptiveFontSize(15, for: geometry), weight: .regular))
                        .foregroundColor(.deepPlum)
                            .lineSpacing(6)
                    }
                    .padding(adaptivePadding(for: geometry))
                    .padding(.top, geometry.safeAreaInsets.top > 0 ? geometry.safeAreaInsets.top + 20 : 30)
                }
            }
            .navigationTitle(type == .privacy ? "Privacy Policy" : "Terms of Service")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var privacyPolicyText: String {
        """
        Privacy Policy
        
        Last updated: October 2025
        
        At EverWith, we take your privacy seriously. This policy explains how we handle your data.
        
        Data Collection:
        • We only access photos you explicitly select for processing
        • Processed images are temporarily stored during creation
        • No photos are permanently stored without your consent
        
        Data Usage:
        • Images are processed using AI technology
        • Processing happens securely on our servers
        • Results are delivered back to your device
        
        Data Storage:
        • Original photos remain on your device
        • Processed images can be saved to your photo library
        • Cloud sync is optional and requires explicit permission
        
        Third Parties:
        • We use secure payment processors for purchases
        • Analytics data is anonymized and aggregated
        • No personal data is sold to third parties
        
        Your Rights:
        • Access your data at any time
        • Delete your account and all associated data
        • Export your created images
        
        Contact: privacy@everwith.app
        """
    }
    
    private var termsOfServiceText: String {
        """
        Terms of Service
        
        Last updated: October 2025
        
        By using EverWith, you agree to these terms.
        
        Service Description:
        • EverWith provides AI-powered photo restoration and merging
        • Results may vary based on input quality
        • Processing times depend on server load
        
        User Responsibilities:
        • Use the service for personal, non-commercial purposes
        • Own or have rights to photos you process
        • Do not process illegal or inappropriate content
        
        Subscriptions:
        • Premium features require active subscription
        • Subscriptions auto-renew unless cancelled
        • Cancel anytime through device settings
        
        Credits:
        • One-time credit purchases available
        • Credits never expire
        • Non-refundable once used
        
        Limitations:
        • Service provided "as is"
        • Results are not guaranteed
        • We reserve the right to modify features
        
        Termination:
        • You may delete your account at any time
        • We may suspend accounts violating these terms
        
        Contact: legal@everwith.app
        """
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
    
    private func adaptivePadding(for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        return max(12, min(20, screenWidth * 0.05))
    }
}

#Preview {
    SettingsView()
}