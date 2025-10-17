//
//  ModernAuthenticationView.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI
import AuthenticationServices

struct ModernAuthenticationView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var animateElements = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Modern Vibrant Background (matching HomeView)
                ModernVibrantBackground()
                    .ignoresSafeArea(.all)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: adaptiveSpacing(20, for: geometry)) {
                        
                        // Top spacing
                        Spacer()
                            .frame(height: adaptiveSpacing(40, for: geometry))
                        
                        // App Logo and Branding
                        VStack(spacing: adaptiveSpacing(16, for: geometry)) {
                            // App Logo
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.honeyGold.opacity(0.8),
                                                Color.sky.opacity(0.6)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: adaptiveSize(80, for: geometry), height: adaptiveSize(80, for: geometry))
                                    .background(.ultraThinMaterial)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.honeyGold.opacity(0.3),
                                                        Color.sky.opacity(0.2)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                                
                                Text("EW")
                                    .font(.system(size: adaptiveFontSize(28, for: geometry), weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .shadow(
                                color: Color.honeyGold.opacity(0.3),
                                radius: adaptiveSpacing(8, for: geometry),
                                x: 0,
                                y: adaptiveSpacing(4, for: geometry)
                            )
                            
                            // App Name and Tagline
                            VStack(spacing: adaptiveSpacing(6, for: geometry)) {
                                Text("EverWith")
                                    .font(.system(size: adaptiveFontSize(32, for: geometry), weight: .bold, design: .rounded))
                                    .foregroundColor(.charcoal)
                                
                                Text("Together in every photo.")
                                    .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                                    .foregroundColor(.charcoal.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : -20)
                        
                        // Authentication Form Container
                        VStack(spacing: adaptiveSpacing(20, for: geometry)) {
                            
                            // Toggle between Sign In and Sign Up
                            HStack(spacing: adaptiveSpacing(8, for: geometry)) {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isSignUp = false
                                        clearForm()
                                    }
                                }) {
                                    Text("Sign In")
                                        .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .semibold))
                                        .foregroundColor(isSignUp ? .charcoal.opacity(0.6) : .charcoal)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: adaptiveSize(44, for: geometry))
                                        .background(
                                            RoundedRectangle(cornerRadius: adaptiveCornerRadius(12, for: geometry))
                                                .fill(isSignUp ? Color.clear : Color.honeyGold.opacity(0.15))
                                        )
                                }
                                
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isSignUp = true
                                        clearForm()
                                    }
                                }) {
                                    Text("Sign Up")
                                        .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .semibold))
                                        .foregroundColor(isSignUp ? .charcoal : .charcoal.opacity(0.6))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: adaptiveSize(44, for: geometry))
                                        .background(
                                            RoundedRectangle(cornerRadius: adaptiveCornerRadius(12, for: geometry))
                                                .fill(isSignUp ? Color.honeyGold.opacity(0.15) : Color.clear)
                                        )
                                }
                            }
                            .padding(adaptiveSpacing(4, for: geometry))
                            .background(
                                RoundedRectangle(cornerRadius: adaptiveCornerRadius(16, for: geometry))
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: adaptiveCornerRadius(16, for: geometry))
                                            .stroke(Color.honeyGold.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            
                            // Form Fields
                            VStack(spacing: adaptiveSpacing(16, for: geometry)) {
                                
                                // Name field (only for sign up)
                                if isSignUp {
                                    ModernTextField(
                                        title: "Full Name",
                                        text: $name,
                                        icon: "person.fill",
                                        geometry: geometry
                                    )
                                    .opacity(animateElements ? 1 : 0)
                                    .offset(x: animateElements ? 0 : -20)
                                }
                                
                                // Email field
                                ModernTextField(
                                    title: "Email",
                                    text: $email,
                                    icon: "envelope.fill",
                                    keyboardType: .emailAddress,
                                    geometry: geometry
                                )
                                .opacity(animateElements ? 1 : 0)
                                .offset(x: animateElements ? 0 : -20)
                                
                                // Password field
                                ModernPasswordField(
                                    title: "Password",
                                    text: $password,
                                    showPassword: $showPassword,
                                    geometry: geometry
                                )
                                .opacity(animateElements ? 1 : 0)
                                .offset(x: animateElements ? 0 : -20)
                                
                                // Confirm Password field (only for sign up)
                                if isSignUp {
                                    ModernPasswordField(
                                        title: "Confirm Password",
                                        text: $confirmPassword,
                                        showPassword: $showConfirmPassword,
                                        geometry: geometry
                                    )
                                    .opacity(animateElements ? 1 : 0)
                                    .offset(x: animateElements ? 0 : -20)
                                }
                            }
                            
                            // Primary Action Button
                            Button(action: {
                                if isSignUp {
                                    signUp()
                                } else {
                                    signIn()
                                }
                            }) {
                                HStack(spacing: adaptiveSpacing(12, for: geometry)) {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: isSignUp ? "person.badge.plus.fill" : "arrow.right.circle.fill")
                                            .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .medium))
                                    }
                                    
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                        .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: adaptiveSize(52, for: geometry))
                                .background(
                                    RoundedRectangle(cornerRadius: adaptiveCornerRadius(16, for: geometry))
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.honeyGold.opacity(0.8),
                                                    Color.sky.opacity(0.6)
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                                .shadow(
                                    color: Color.honeyGold.opacity(0.3),
                                    radius: adaptiveSpacing(8, for: geometry),
                                    x: 0,
                                    y: adaptiveSpacing(4, for: geometry)
                                )
                            }
                            .disabled(isLoading || !isFormValid)
                            .opacity(isFormValid ? 1 : 0.6)
                            .opacity(animateElements ? 1 : 0)
                            .offset(y: animateElements ? 0 : 20)
                            
                            // Divider
                            HStack {
                                Rectangle()
                                    .fill(Color.charcoal.opacity(0.2))
                                    .frame(height: 1)
                                
                                Text("or")
                                    .font(.system(
                                        size: geometry.isSmallScreen ? 12 : ResponsiveDesign.adaptiveFontSize(baseSize: 14, for: geometry),
                                        weight: .medium
                                    ))
                                    .foregroundColor(.charcoal.opacity(0.6))
                                    .padding(.horizontal, ResponsiveDesign.adaptiveSpacing(baseSpacing: 6, for: geometry))
                                
                                Rectangle()
                                    .fill(Color.charcoal.opacity(0.2))
                                    .frame(height: 1)
                            }
                            .opacity(animateElements ? 1 : 0)
                            
                            // Social Sign In Buttons
                            VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 6, for: geometry)) {
                                
                                // Apple Sign In
                                Button(action: {
                                    signInWithApple()
                                }) {
                                    HStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 6, for: geometry)) {
                                        Image(systemName: "applelogo")
                                            .font(.system(
                                                size: geometry.isSmallScreen ? 16 : ResponsiveDesign.adaptiveFontSize(baseSize: 18, for: geometry),
                                                weight: .medium
                                            ))
                                            .foregroundColor(.charcoal)
                                        
                                        Text("Continue with Apple")
                                            .font(.system(
                                                size: geometry.isSmallScreen ? 14 : ResponsiveDesign.adaptiveFontSize(baseSize: 16, for: geometry),
                                                weight: .medium
                                            ))
                                            .foregroundColor(.charcoal)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: geometry.isSmallScreen ? 42 : ResponsiveDesign.adaptiveButtonHeight(baseHeight: 48, for: geometry))
                                    .background(
                                        RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 16, for: geometry))
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 16, for: geometry))
                                                    .stroke(Color.charcoal.opacity(0.1), lineWidth: 1)
                                            )
                                    )
                                }
                                .disabled(isLoading)
                                
                                // Google Sign In
                                Button(action: {
                                    signInWithGoogle()
                                }) {
                                    HStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 6, for: geometry)) {
                                        Image(systemName: "globe")
                                            .font(.system(
                                                size: geometry.isSmallScreen ? 16 : ResponsiveDesign.adaptiveFontSize(baseSize: 18, for: geometry),
                                                weight: .medium
                                            ))
                                            .foregroundColor(.charcoal)
                                        
                                        Text("Continue with Google")
                                            .font(.system(
                                                size: geometry.isSmallScreen ? 14 : ResponsiveDesign.adaptiveFontSize(baseSize: 16, for: geometry),
                                                weight: .medium
                                            ))
                                            .foregroundColor(.charcoal)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: geometry.isSmallScreen ? 42 : ResponsiveDesign.adaptiveButtonHeight(baseHeight: 48, for: geometry))
                                    .background(
                                        RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 16, for: geometry))
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: ResponsiveDesign.adaptiveCornerRadius(baseRadius: 16, for: geometry))
                                                    .stroke(Color.charcoal.opacity(0.1), lineWidth: 1)
                                            )
                                    )
                                }
                                .disabled(isLoading)
                            }
                            .opacity(animateElements ? 1 : 0)
                            .offset(y: animateElements ? 0 : 20)
                            
                            // Additional Options
                            VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 6, for: geometry)) {
                                if !isSignUp {
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            isSignUp = true
                                            clearForm()
                                        }
                                    }) {
                                        Text("Don't have an account? Sign Up")
                                            .font(.system(
                                                size: geometry.isSmallScreen ? 12 : ResponsiveDesign.adaptiveFontSize(baseSize: 14, for: geometry),
                                                weight: .medium
                                            ))
                                            .foregroundColor(.honeyGold)
                                    }
                                    .disabled(isLoading)
                                } else {
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            isSignUp = false
                                            clearForm()
                                        }
                                    }) {
                                        Text("Already have an account? Sign In")
                                            .font(.system(
                                                size: geometry.isSmallScreen ? 12 : ResponsiveDesign.adaptiveFontSize(baseSize: 14, for: geometry),
                                                weight: .medium
                                            ))
                                            .foregroundColor(.honeyGold)
                                    }
                                    .disabled(isLoading)
                                }
                                
                                // Guest Access (less prominent)
                                Button(action: {
                                    skipAuthentication()
                                }) {
                                    Text("Continue as Guest")
                                        .font(.system(
                                            size: geometry.isSmallScreen ? 10 : ResponsiveDesign.adaptiveFontSize(baseSize: 12, for: geometry),
                                            weight: .regular
                                        ))
                                        .foregroundColor(.charcoal.opacity(0.5))
                                }
                                .disabled(isLoading)
                            }
                            .opacity(animateElements ? 1 : 0)
                            
                            // Error Message
                            if let errorMessage = errorMessage {
                                Text(errorMessage)
                                    .font(.system(
                                        size: geometry.isSmallScreen ? 12 : ResponsiveDesign.adaptiveFontSize(baseSize: 14, for: geometry),
                                        weight: .medium
                                    ))
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry))
                                    .opacity(animateElements ? 1 : 0)
                            }
                        }
                        .padding(.horizontal, adaptiveSpacing(20, for: geometry))
                        .padding(.vertical, adaptiveSpacing(20, for: geometry))
                        .background(
                            RoundedRectangle(cornerRadius: adaptiveCornerRadius(20, for: geometry))
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.honeyGold.opacity(0.12),
                                            Color.sky.opacity(0.08),
                                            Color.softBlush.opacity(0.06)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .background(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: adaptiveCornerRadius(20, for: geometry))
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.honeyGold.opacity(0.25),
                                                    Color.sky.opacity(0.15)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .shadow(
                            color: Color.black.opacity(0.05),
                            radius: adaptiveSpacing(10, for: geometry),
                            x: 0,
                            y: adaptiveSpacing(4, for: geometry)
                        )
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 30)
                        
                        // Bottom spacing
                        Spacer()
                            .frame(height: adaptiveSpacing(24, for: geometry))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, adaptivePadding(for: geometry))
                }
                .scrollIndicators(.hidden)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                animateElements = true
            }
        }
        .alert("Authentication Error", isPresented: $showErrorAlert) {
            Button("OK") {
                showErrorAlert = false
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "An error occurred during authentication. Please try again.")
        }
    }
    
    // MARK: - Adaptive Sizing Functions (matching HomeView)
    private func adaptivePadding(for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        // iPhone SE (375pt) = 12pt, iPhone 15 Pro (393pt) = 14pt, iPhone 15 Pro Max (430pt) = 16pt
        return max(12, min(16, screenWidth * 0.04))
    }
    
    private func adaptiveSpacing(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0 // Base on iPhone SE
        return base * scaleFactor
    }
    
    private func adaptiveFontSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0 // Base on iPhone SE
        return max(base * 0.9, min(base * 1.1, base * scaleFactor))
    }
    
    private func adaptiveSize(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0 // Base on iPhone SE
        return base * scaleFactor
    }
    
    private func adaptiveCornerRadius(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0 // Base on iPhone SE
        return base * scaleFactor
    }
    
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        if isSignUp {
            return !name.isEmpty && 
                   !email.isEmpty && 
                   !password.isEmpty && 
                   !confirmPassword.isEmpty && 
                   password == confirmPassword &&
                   password.count >= 8 &&
                   password.count <= 72
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
    
    
    // MARK: - Private Methods
    private func clearForm() {
        email = ""
        password = ""
        name = ""
        confirmPassword = ""
        errorMessage = nil
        showErrorAlert = false
    }
    
    private func signUp() {
        // Client-side validation
        if password.count < 8 {
            errorMessage = "Password must be at least 8 characters long"
            showErrorAlert = true
            return
        }
        
        if password.count > 72 {
            errorMessage = "Password must be no more than 72 characters long"
            showErrorAlert = true
            return
        }
        
        if password != confirmPassword {
            errorMessage = "Passwords do not match"
            showErrorAlert = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            let result = await authService.signUpWithEmail(email: email, password: password, name: name)
            
            await MainActor.run {
                isLoading = false
                
                switch result {
                case .success(let user):
                    print("User signed up successfully: \(user.name) (\(user.email))")
                    // Success! The app will automatically navigate to HomeView via auth state change
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                case .cancelled:
                    break
                }
            }
        }
    }
    
    private func signIn() {
        print("🎯 UI: Sign In button tapped")
        isLoading = true
        errorMessage = nil
        
        Task {
            print("🚀 UI: Starting sign in task")
            let result = await authService.signInWithEmail(email: email, password: password)
            
            await MainActor.run {
                isLoading = false
                print("📱 UI: Sign in task completed")
                
                switch result {
                case .success(let user):
                    print("🎉 UI: Sign in successful - User: \(user.name) (\(user.email))")
                    // Success! The app will automatically navigate to HomeView via auth state change
                case .failure(let error):
                    print("❌ UI: Sign in failed - Error: \(error.localizedDescription)")
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                case .cancelled:
                    print("🚫 UI: Sign in cancelled")
                    break
                }
            }
        }
    }
    
    private func signInWithApple() {
        isLoading = true
        errorMessage = nil
        
        Task {
            let result = await authService.signInWithApple()
            
            await MainActor.run {
                isLoading = false
                
                switch result {
                case .success(let user):
                    print("User signed in with Apple successfully: \(user.name) (\(user.email))")
                    // Success! The app will automatically navigate to HomeView via auth state change
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                case .cancelled:
                    break
                }
            }
        }
    }
    
    private func signInWithGoogle() {
        isLoading = true
        errorMessage = nil
        
        Task {
            let result = await authService.signInWithGoogle()
            
            await MainActor.run {
                isLoading = false
                
                switch result {
                case .success(let user):
                    print("User signed in with Google successfully: \(user.name) (\(user.email))")
                    // Success! The app will automatically navigate to HomeView via auth state change
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                case .cancelled:
                    break
                }
            }
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
                    print("User skipped authentication successfully: \(user.name)")
                    // Success! The app will automatically navigate to HomeView via auth state change
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                case .cancelled:
                    break
                }
            }
        }
    }
}

// MARK: - Modern Text Field Component
struct ModernTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(alignment: .leading, spacing: adaptiveSpacing(8, for: geometry)) {
            Text(title)
                .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .medium))
                .foregroundColor(.charcoal.opacity(0.8))
                .lineLimit(1)
            
            HStack(spacing: adaptiveSpacing(12, for: geometry)) {
                Image(systemName: icon)
                    .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                    .foregroundColor(.charcoal.opacity(0.6))
                    .frame(width: adaptiveSize(20, for: geometry))
                    .frame(minWidth: adaptiveSize(20, for: geometry))
                
                TextField(title, text: $text)
                    .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                    .foregroundColor(.charcoal)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .lineLimit(1)
            }
            .padding(.horizontal, adaptiveSpacing(12, for: geometry))
            .padding(.vertical, adaptiveSpacing(12, for: geometry))
            .background(
                RoundedRectangle(cornerRadius: adaptiveCornerRadius(14, for: geometry))
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: adaptiveCornerRadius(14, for: geometry))
                            .stroke(Color.charcoal.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Adaptive Functions (matching HomeView)
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

// MARK: - Modern Password Field Component
struct ModernPasswordField: View {
    let title: String
    @Binding var text: String
    @Binding var showPassword: Bool
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(alignment: .leading, spacing: adaptiveSpacing(8, for: geometry)) {
            Text(title)
                .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .medium))
                .foregroundColor(.charcoal.opacity(0.8))
                .lineLimit(1)
            
            HStack(spacing: adaptiveSpacing(12, for: geometry)) {
                Image(systemName: "lock.fill")
                    .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                    .foregroundColor(.charcoal.opacity(0.6))
                    .frame(width: adaptiveSize(20, for: geometry))
                    .frame(minWidth: adaptiveSize(20, for: geometry))
                
                if showPassword {
                    TextField(title, text: $text)
                        .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                        .foregroundColor(.charcoal)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .lineLimit(1)
                } else {
                    SecureField(title, text: $text)
                        .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                        .foregroundColor(.charcoal)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .lineLimit(1)
                }
                
                Button(action: {
                    showPassword.toggle()
                }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                        .foregroundColor(.charcoal.opacity(0.6))
                        .frame(width: adaptiveSize(20, for: geometry))
                        .frame(minWidth: adaptiveSize(20, for: geometry))
                }
            }
            .padding(.horizontal, adaptiveSpacing(12, for: geometry))
            .padding(.vertical, adaptiveSpacing(12, for: geometry))
            .background(
                RoundedRectangle(cornerRadius: adaptiveCornerRadius(14, for: geometry))
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: adaptiveCornerRadius(14, for: geometry))
                            .stroke(Color.charcoal.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Adaptive Functions (matching HomeView)
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

#Preview {
    ModernAuthenticationView()
        .environmentObject(AuthenticationService())
}
