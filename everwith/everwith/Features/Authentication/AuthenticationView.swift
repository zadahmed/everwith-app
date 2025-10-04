//
//  AuthenticationView.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.honeyGold.opacity(0.15),
                        Color.sky.opacity(0.15),
                        Color.warmLinen.opacity(0.8)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: ModernDesignSystem.Spacing.xl) {
                    Spacer()
                    
                    // App Logo with glassmorphism
                    Circle()
                        .fill(Color.brandGradient)
                        .frame(width: 120, height: 120)
                        .overlay(
                            Text("EW")
                                .font(.system(size: 48, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        )
                        .cleanGlassmorphism(
                            style: ModernDesignSystem.GlassEffect.subtle,
                            shadow: ModernDesignSystem.Shadow.light
                        )
                
                    // App Name and Tagline
                    VStack(spacing: ModernDesignSystem.Spacing.md) {
                        Text("EverWith")
                            .font(.system(size: 40, weight: .semibold, design: .rounded))
                            .foregroundColor(.charcoal)
                        
                        Text("Together in every photo.")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.charcoal.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(ModernDesignSystem.Spacing.lg)
                    .cleanGlassmorphism(
                        style: ModernDesignSystem.GlassEffect.warmLinen,
                        blur: ModernDesignSystem.BlurEffect.subtle,
                        shadow: ModernDesignSystem.Shadow.none
                    )
                
                    Spacer()
                    
                    // Sign In Options
                    VStack(spacing: ModernDesignSystem.Spacing.lg) {
                    // Apple Sign In Button
                    Button(action: {
                        Task {
                            await signInWithApple()
                        }
                    }) {
                        HStack(spacing: DesignTokens.spacingMedium) {
                            Image(systemName: "applelogo")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text("Continue with Apple")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.black)
                        .cornerRadius(ModernDesignSystem.CornerRadius.md)
                    }
                    
                    // Google Sign In Button
                    Button(action: {
                        Task {
                            await signInWithGoogle()
                        }
                    }) {
                        HStack(spacing: DesignTokens.spacingMedium) {
                            Image(systemName: "globe")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.charcoal)
                            
                            Text("Continue with Google")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.charcoal)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.warmLinen.opacity(0.8))
                        .cornerRadius(ModernDesignSystem.CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.md)
                                .stroke(Color.charcoal.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .disabled(isLoading)
                    
                    // Error Message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(ModernDesignSystem.Spacing.lg)
                .cleanGlassmorphism(
                    style: ModernDesignSystem.GlassEffect.light,
                    blur: ModernDesignSystem.BlurEffect.subtle,
                    shadow: ModernDesignSystem.Shadow.subtle
                )
                
                // Skip for now button
                Button(action: {
                    skipAuthentication()
                }) {
                    Text("Skip for now")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.charcoal.opacity(0.7))
                }
                .buttonStyle(ModernButtonStyle(style: .minimal))
                .padding(.horizontal, ModernDesignSystem.Spacing.lg)
                
                    // Terms and Privacy
                    VStack(spacing: ModernDesignSystem.Spacing.sm) {
                        Text("By continuing, you agree to our")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.charcoal.opacity(0.6))
                        
                        HStack(spacing: 4) {
                            Button("Terms of Service") {
                                // Handle terms action
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.honeyGold)
                            
                            Text("and")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.charcoal.opacity(0.6))
                            
                            Button("Privacy Policy") {
                                // Handle privacy action
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.honeyGold)
                        }
                    }
                    .padding(ModernDesignSystem.Spacing.md)
                
                    Spacer()
                }
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height
                )
            }
            .overlay(
                // Loading Overlay
                Group {
                    if isLoading {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: DesignTokens.spacingMedium) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .honeyGold))
                                .scaleEffect(1.2)
                            
                            Text("Signing you in...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.charcoal)
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
            )
        }
        .ignoresSafeArea(.all)
    }
    
    // MARK: - Private Methods
    
    private func signInWithApple() async {
        isLoading = true
        errorMessage = nil
        
        let result = await authService.signInWithApple()
        
        await MainActor.run {
            isLoading = false
            
            switch result {
            case .success(let user):
                print("User signed in: \(user.name) (\(user.email))")
            case .failure(let error):
                errorMessage = error.localizedDescription
            case .cancelled:
                // User cancelled, don't show error
                break
            }
        }
    }
    
    private func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        let result = await authService.signInWithGoogle()
        
        await MainActor.run {
            isLoading = false
            
            switch result {
            case .success(let user):
                print("User signed in: \(user.name) (\(user.email))")
            case .failure(let error):
                errorMessage = error.localizedDescription
            case .cancelled:
                // User cancelled, don't show error
                break
            }
        }
    }
    
    private func handleSignInError(_ error: Error) {
        isLoading = false
        
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                // User cancelled, don't show error
                return
            default:
                errorMessage = authError.localizedDescription
            }
        } else {
            errorMessage = error.localizedDescription
        }
    }
    
    private func skipAuthentication() {
        isLoading = true
        errorMessage = nil
        
        Task {
            let result = await authService.signInAsGuest()
            
            await MainActor.run {
                isLoading = false
                
                switch result {
                case .success(let user):
                    print("User skipped authentication: \(user.name)")
                case .failure(let error):
                    errorMessage = error.localizedDescription
                case .cancelled:
                    // User cancelled, don't show error
                    break
                }
            }
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationService())
}
