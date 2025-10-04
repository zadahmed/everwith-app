//
//  BrandComponents.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI

// MARK: - Brand Card Component
struct BrandCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack {
            content
        }
        .padding(DesignTokens.spacingLarge)
        .background(Color.warmLinen)
        .cornerRadius(DesignTokens.radiusMedium)
        .shadow(
            color: DesignTokens.shadowSoft,
            radius: DesignTokens.shadowRadius,
            x: DesignTokens.shadowOffset.width,
            y: DesignTokens.shadowOffset.height
        )
    }
}

// MARK: - Brand Input Field
struct BrandTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingSmall) {
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.charcoal)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16, weight: .regular))
                .padding(DesignTokens.spacingMedium)
                .background(Color.warmLinen)
                .cornerRadius(DesignTokens.radiusSmall)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.radiusSmall)
                        .stroke(Color.charcoal.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

// MARK: - Brand Toggle Switch
struct BrandToggle: View {
    let title: String
    let description: String?
    @Binding var isOn: Bool
    
    init(title: String, description: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.description = description
        self._isOn = isOn
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignTokens.spacingSmall) {
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.charcoal)
                
                if let description = description {
                    Text(description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.charcoal.opacity(0.7))
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .honeyGold))
        }
        .padding(DesignTokens.spacingMedium)
        .background(Color.warmLinen)
        .cornerRadius(DesignTokens.radiusSmall)
    }
}

// MARK: - Brand Alert/Consent Component
struct ConsentAlert: View {
    let title: String
    let message: String
    @Binding var isConsented: Bool
    let onConsent: () -> Void
    
    var body: some View {
        VStack(spacing: DesignTokens.spacingMedium) {
            Image(systemName: "heart.fill")
                .font(.system(size: 32))
                .foregroundColor(.honeyGold)
            
            Text(title)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(.charcoal)
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.charcoal.opacity(0.8))
                .multilineTextAlignment(.center)
            
            BrandToggle(
                title: "I have consent from any living person in this photo",
                isOn: $isConsented
            )
            
            Button(action: onConsent) {
                Text("Continue")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!isConsented)
            .opacity(isConsented ? 1.0 : 0.6)
        }
        .padding(DesignTokens.spacingLarge)
        .background(Color.warmLinen)
        .cornerRadius(DesignTokens.radiusLarge)
        .shadow(
            color: DesignTokens.shadowSoft,
            radius: DesignTokens.shadowRadius,
            x: DesignTokens.shadowOffset.width,
            y: DesignTokens.shadowOffset.height
        )
    }
}

// MARK: - Brand Progress Indicator
struct BrandProgressView: View {
    let progress: Double
    let message: String
    
    var body: some View {
        VStack(spacing: DesignTokens.spacingMedium) {
            ZStack {
                Circle()
                    .stroke(Color.charcoal.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.honeyGold, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: DesignTokens.animationDuration), value: progress)
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.charcoal)
            }
            
            Text(message)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.charcoal.opacity(0.8))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Brand Success Message
struct SuccessMessage: View {
    let title: String
    let message: String
    let actionText: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: DesignTokens.spacingMedium) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.fern)
            
            Text(title)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(.charcoal)
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.charcoal.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Button(action: action) {
                Text(actionText)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(DesignTokens.spacingLarge)
        .background(Color.warmLinen)
        .cornerRadius(DesignTokens.radiusLarge)
        .shadow(
            color: DesignTokens.shadowSoft,
            radius: DesignTokens.shadowRadius,
            x: DesignTokens.shadowOffset.width,
            y: DesignTokens.shadowOffset.height
        )
    }
}

// MARK: - Brand Navigation Bar
struct BrandNavigationBar: View {
    let title: String
    let showBackButton: Bool
    let onBack: (() -> Void)?
    
    init(title: String, showBackButton: Bool = false, onBack: (() -> Void)? = nil) {
        self.title = title
        self.showBackButton = showBackButton
        self.onBack = onBack
    }
    
    var body: some View {
        HStack {
            if showBackButton {
                Button(action: { onBack?() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.charcoal)
                }
            }
            
            Spacer()
            
            Text(title)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(.charcoal)
            
            Spacer()
            
            if showBackButton {
                // Invisible spacer to balance the back button
                Color.clear
                    .frame(width: 18, height: 18)
            }
        }
        .padding(.horizontal, DesignTokens.spacingMedium)
        .padding(.vertical, DesignTokens.spacingSmall)
        .background(Color.warmLinen)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            BrandCard {
                VStack(spacing: 16) {
                    Text("Sample Card")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(.charcoal)
                    
                    Text("This is a sample brand card with proper spacing and styling.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.charcoal.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
            
            BrandTextField(title: "Name", placeholder: "Enter your name", text: .constant(""))
            
            BrandToggle(title: "Enable notifications", description: "Receive updates about your tributes", isOn: .constant(true))
            
            ConsentAlert(
                title: "Consent Required",
                message: "Please confirm you have permission to use this photo.",
                isConsented: .constant(false),
                onConsent: {}
            )
            
            BrandProgressView(progress: 0.7, message: "Processing your tribute...")
            
            SuccessMessage(
                title: "Tribute Created",
                message: "Saved to your memories",
                actionText: "View Tribute",
                action: {}
            )
        }
        .padding()
    }
    .background(Color.warmLinen)
}
