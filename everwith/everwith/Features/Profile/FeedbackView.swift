//
//  FeedbackView.swift
//  EverWith
//
//  Feedback and support screen
//

import SwiftUI
import Combine
import MessageUI

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var feedbackType: FeedbackType = .general
    @State private var feedbackText = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var showMailComposer = false
    @State private var animateElements = false
    
    enum FeedbackType: String, CaseIterable {
        case general = "General Feedback"
        case bug = "Report a Bug"
        case feature = "Feature Request"
        case help = "Need Help"
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CleanWhiteBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: geometry.adaptiveSpacing(24)) {
                        // Header
                        VStack(spacing: geometry.adaptiveSpacing(16)) {
                            Image(systemName: "envelope.circle.fill")
                                .font(.system(size: geometry.adaptiveFontSize(64), weight: .medium))
                                .foregroundStyle(LinearGradient.primaryBrand)
                                .scaleEffect(animateElements ? 1.0 : 0.8)
                            
                            Text("We'd Love to Hear From You")
                                .font(.system(size: geometry.adaptiveFontSize(28), weight: .bold, design: .rounded))
                                .foregroundColor(.deepPlum)
                                .multilineTextAlignment(.center)
                                .opacity(animateElements ? 1.0 : 0.0)
                            
                            Text("Your feedback helps us make Everwith better for everyone")
                                .font(.system(size: geometry.adaptiveFontSize(16), weight: .medium))
                                .foregroundColor(.softPlum)
                                .multilineTextAlignment(.center)
                                .opacity(animateElements ? 1.0 : 0.0)
                        }
                        .padding(.horizontal, geometry.adaptivePadding())
                        .padding(.top, geometry.safeAreaInsets.top > 0 ? geometry.safeAreaInsets.top + 16 : 32)
                        
                        // Quick Actions
                        VStack(spacing: geometry.adaptiveSpacing(12)) {
                            Button(action: {
                                openEmail(subject: "Support Request", body: "")
                            }) {
                                QuickActionCard(
                                    icon: "envelope.fill",
                                    title: "Contact Support",
                                    subtitle: "support@everwith.app",
                                    iconColor: .blushPink,
                                    geometry: geometry
                                )
                            }
                            
                            Button(action: {
                                openEmail(subject: "Bug Report", body: getBugTemplate())
                            }) {
                                QuickActionCard(
                                    icon: "ladybug.fill",
                                    title: "Report a Bug",
                                    subtitle: "Help us fix issues quickly",
                                    iconColor: .red,
                                    geometry: geometry
                                )
                            }
                            
                            Button(action: {
                                openEmail(subject: "Feature Request", body: "")
                            }) {
                                QuickActionCard(
                                    icon: "lightbulb.fill",
                                    title: "Send Feedback",
                                    subtitle: "Share your ideas with us",
                                    iconColor: .honeyGold,
                                    geometry: geometry
                                )
                            }
                            
                            Button(action: {
                                rateApp()
                            }) {
                                QuickActionCard(
                                    icon: "star.fill",
                                    title: "Rate Us on the App Store",
                                    subtitle: "It helps us grow!",
                                    iconColor: .roseMagenta,
                                    geometry: geometry
                                )
                            }
                        }
                        .padding(.horizontal, geometry.adaptivePadding())
                        .opacity(animateElements ? 1.0 : 0.0)
                        
                        // FAQ Section
                        VStack(alignment: .leading, spacing: geometry.adaptiveSpacing(12)) {
                            Text("Common Questions")
                                .font(.system(size: geometry.adaptiveFontSize(20), weight: .bold, design: .rounded))
                                .foregroundColor(.deepPlum)
                                .padding(.horizontal, geometry.adaptivePadding())
                            
                            VStack(spacing: geometry.adaptiveSpacing(12)) {
                                FAQCard(
                                    question: "How does photo restoration work?",
                                    answer: "We use advanced AI to analyze and enhance old photos, fixing scratches, improving colors, and sharpening details.",
                                    geometry: geometry
                                )
                                
                                FAQCard(
                                    question: "Are my photos stored on your servers?",
                                    answer: "Photos are temporarily stored during processing and automatically deleted after 24 hours. Your originals always remain on your device.",
                                    geometry: geometry
                                )
                                
                                FAQCard(
                                    question: "How do credits work?",
                                    answer: "Each credit processes one photo. Credits never expire and can be used for any restoration or merge.",
                                    geometry: geometry
                                )
                                
                                FAQCard(
                                    question: "Can I cancel my subscription?",
                                    answer: "Yes, you can cancel anytime from your device settings. You'll retain access until the end of your billing period.",
                                    geometry: geometry
                                )
                            }
                            .padding(.horizontal, geometry.adaptivePadding())
                        }
                        .opacity(animateElements ? 1.0 : 0.0)
                        
                        Spacer()
                            .frame(height: geometry.adaptiveSpacing(32))
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom + 16 : 24)
                }
            }
            .navigationTitle("Support")
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
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                    animateElements = true
                }
            }
        }
    }
    
    private func openEmail(subject: String, body: String) {
        let email = "support@everwith.app"
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "mailto:\(email)?subject=\(subjectEncoded)&body=\(bodyEncoded)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    private func getBugTemplate() -> String {
        """
        Please describe the issue:
        
        
        Steps to reproduce:
        1. 
        2. 
        3. 
        
        Expected behavior:
        
        
        Device: \(UIDevice.current.model)
        iOS Version: \(UIDevice.current.systemVersion)
        App Version: 1.0.0
        """
    }
    
    private func rateApp() {
        // Open App Store rating page
        if let url = URL(string: "https://apps.apple.com/app/id123456789?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    let geometry: GeometryProxy
    
    var body: some View {
        HStack(spacing: geometry.adaptiveSpacing(16)) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: geometry.adaptiveSize(56), height: geometry.adaptiveSize(56))
                
                Image(systemName: icon)
                    .font(.system(size: geometry.adaptiveFontSize(24), weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: geometry.adaptiveSpacing(4)) {
                Text(title)
                    .font(.system(size: geometry.adaptiveFontSize(16), weight: .semibold))
                    .foregroundColor(.deepPlum)
                
                Text(subtitle)
                    .font(.system(size: geometry.adaptiveFontSize(14), weight: .regular))
                    .foregroundColor(.softPlum)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: geometry.adaptiveFontSize(14), weight: .semibold))
                .foregroundColor(.softPlum.opacity(0.5))
        }
        .padding(geometry.adaptiveSpacing(16))
        .background(
            RoundedRectangle(cornerRadius: geometry.adaptiveCornerRadius(16))
                .fill(Color.pureWhite)
                .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - FAQ Card
struct FAQCard: View {
    let question: String
    let answer: String
    let geometry: GeometryProxy
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: geometry.adaptiveSpacing(12)) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(question)
                        .font(.system(size: geometry.adaptiveFontSize(15), weight: .semibold))
                        .foregroundColor(.deepPlum)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: geometry.adaptiveFontSize(14), weight: .semibold))
                        .foregroundColor(.softPlum)
                }
            }
            
            if isExpanded {
                Text(answer)
                    .font(.system(size: geometry.adaptiveFontSize(14), weight: .regular))
                    .foregroundColor(.softPlum)
                    .lineSpacing(4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(geometry.adaptiveSpacing(16))
        .background(
            RoundedRectangle(cornerRadius: geometry.adaptiveCornerRadius(12))
                .fill(Color.pureWhite)
                .shadow(color: Color.cardShadow, radius: 2, x: 0, y: 1)
        )
    }
}

#Preview {
    NavigationStack {
        FeedbackView()
    }
}

