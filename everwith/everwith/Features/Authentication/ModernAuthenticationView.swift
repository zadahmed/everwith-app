//
//  ModernAuthenticationView.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI

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
    @State private var buttonPressedEmail: Bool = false
    @State private var buttonPressedGoogle: Bool = false
    @State private var formOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.8
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Clean White Background with Subtle Gradient Band
                CleanWhiteBackground()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea(.all, edges: .all)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        
                        // App Logo and Branding - Modern & Vibrant
                        VStack(spacing: geometry.isSmallScreen ? 12 : 16) {
                            // App Logo with brand gradient (matching HomeView)
                            ZStack {
                                // Glow effect
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.blushPink.opacity(0.3),
                                                Color.roseMagenta.opacity(0.2)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(
                                        width: geometry.isSmallScreen ? 72 : adaptiveSize(85, for: geometry),
                                        height: geometry.isSmallScreen ? 72 : adaptiveSize(85, for: geometry)
                                    )
                                    .blur(radius: 20)
                                
                                // Main logo circle
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.blushPink.opacity(0.9),
                                                Color.roseMagenta.opacity(0.7),
                                                Color.memoryViolet.opacity(0.6)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(
                                        width: geometry.isSmallScreen ? 68 : adaptiveSize(80, for: geometry),
                                        height: geometry.isSmallScreen ? 68 : adaptiveSize(80, for: geometry)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                Color.white.opacity(0.3),
                                                lineWidth: 2
                                            )
                                    )
                                
                                Image("AppLogo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(
                                        width: geometry.isSmallScreen ? 40 : adaptiveSize(48, for: geometry),
                                        height: geometry.isSmallScreen ? 40 : adaptiveSize(48, for: geometry)
                                    )
                            }
                            .scaleEffect(logoScale)
                            .shadow(
                                color: Color.blushPink.opacity(0.4),
                                radius: geometry.isSmallScreen ? 10 : adaptiveSpacing(15, for: geometry),
                                x: 0,
                                y: geometry.isSmallScreen ? 4 : adaptiveSpacing(6, for: geometry)
                            )
                            
                            // App Name and Tagline - Modern
                            VStack(spacing: geometry.isSmallScreen ? 6 : adaptiveSpacing(8, for: geometry)) {
                                Text("Everwith")
                                    .font(.system(
                                        size: geometry.isSmallScreen ? 32 : adaptiveFontSize(36, for: geometry),
                                        weight: .black,
                                        design: .rounded
                                    ))
                                    .foregroundColor(.deepPlum)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                
                                Text("Create beautiful memories together")
                                    .font(.system(
                                        size: geometry.isSmallScreen ? 14 : adaptiveFontSize(16, for: geometry),
                                        weight: .medium
                                    ))
                                    .foregroundColor(.softPlum)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.9)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.top, geometry.safeAreaInsets.top > 0 ? geometry.safeAreaInsets.top + 24 : 36)
                        .padding(.bottom, 24)
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : -20)
                        
                        // Authentication Form Container
                        VStack(spacing: geometry.isSmallScreen ? 14 : 18) {
                            
                            // Modern Segmented Control - Sign In / Sign Up
                            HStack(spacing: 0) {
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        isSignUp = false
                                        clearForm()
                                    }
                                }) {
                                    Text("Sign In")
                                        .font(.system(
                                            size: geometry.isSmallScreen ? 15 : adaptiveFontSize(16, for: geometry),
                                            weight: .bold
                                        ))
                                        .foregroundColor(isSignUp ? .softPlum : .white)
                                        .frame(height: geometry.isSmallScreen ? 48 : adaptiveSize(52, for: geometry))
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            ZStack {
                                                if !isSignUp {
                                                    RoundedRectangle(cornerRadius: adaptiveCornerRadius(16, for: geometry))
                                                        .fill(
                                                            LinearGradient.primaryBrand
                                                        )
                                                        .shadow(
                                                            color: Color.blushPink.opacity(0.4),
                                                            radius: 8,
                                                            x: 0,
                                                            y: 4
                                                        )
                                                        .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                                                }
                                            }
                                        )
                                }
                                
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        isSignUp = true
                                        clearForm()
                                    }
                                }) {
                                    Text("Sign Up")
                                        .font(.system(
                                            size: geometry.isSmallScreen ? 15 : adaptiveFontSize(16, for: geometry),
                                            weight: .bold
                                        ))
                                        .foregroundColor(isSignUp ? .white : .softPlum)
                                        .frame(height: geometry.isSmallScreen ? 48 : adaptiveSize(52, for: geometry))
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            ZStack {
                                                if isSignUp {
                                                    RoundedRectangle(cornerRadius: adaptiveCornerRadius(16, for: geometry))
                                                        .fill(
                                                            LinearGradient.primaryBrand
                                                        )
                                                        .shadow(
                                                            color: Color.blushPink.opacity(0.4),
                                                            radius: 8,
                                                            x: 0,
                                                            y: 4
                                                        )
                                                        .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                                                }
                                            }
                                        )
                                }
                            }
                            .padding(4)
                            .background(
                                RoundedRectangle(cornerRadius: adaptiveCornerRadius(18, for: geometry))
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                            )
                            
                            // Form Fields
                            VStack(spacing: geometry.isSmallScreen ? 12 : 14) {
                                
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
                            
                            // Primary Action Button - Vibrant Gradient
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    buttonPressedEmail = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    if isSignUp {
                                        signUp()
                                    } else {
                                        signIn()
                                    }
                                    buttonPressedEmail = false
                                }
                            }) {
                                HStack(spacing: 10) {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.9)
                                    } else {
                                        Image(systemName: isSignUp ? "person.badge.plus.fill" : "arrow.right.circle.fill")
                                            .font(.system(
                                                size: geometry.isSmallScreen ? 17 : 19,
                                                weight: .semibold
                                            ))
                                    }
                                    
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                        .font(.system(
                                            size: geometry.isSmallScreen ? 15 : 16,
                                            weight: .bold
                                        ))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .foregroundColor(.white)
                                .frame(height: geometry.isSmallScreen ? 52 : 56)
                                .frame(maxWidth: .infinity)
                                .background(
                                    ZStack {
                                        // Gradient background (matching HomeView)
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(
                                                LinearGradient.primaryBrand
                                            )
                                        
                                        // Shimmer overlay effect
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.white.opacity(0),
                                                        Color.white.opacity(0.15),
                                                        Color.white.opacity(0)
                                                    ]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    }
                                )
                                .shadow(
                                    color: Color.blushPink.opacity(0.4),
                                    radius: 12,
                                    x: 0,
                                    y: 6
                                )
                            }
                            .scaleEffect(buttonPressedEmail ? 0.96 : 1.0)
                            .disabled(isLoading || !isFormValid)
                            .opacity(isFormValid ? 1 : 0.6)
                            .opacity(animateElements ? 1 : 0)
                            .offset(y: animateElements ? 0 : 20)
                            
                            // Divider
                            HStack(spacing: 12) {
                                Rectangle()
                                    .fill(Color.subtleBorder)
                                    .frame(height: 1)
                                
                                Text("or")
                                    .font(.system(
                                        size: geometry.isSmallScreen ? 12 : 13,
                                        weight: .medium
                                    ))
                                    .foregroundColor(.softPlum)
                                    .padding(.horizontal, 8)
                                    .fixedSize()
                                
                                Rectangle()
                                    .fill(Color.subtleBorder)
                                    .frame(height: 1)
                            }
                            .opacity(animateElements ? 1 : 0)
                            
                            // Social Sign In - Google Button
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    buttonPressedGoogle = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    signInWithGoogle()
                                    buttonPressedGoogle = false
                                }
                            }) {
                                HStack(spacing: 10) {
                                    // Google icon
                                    ZStack {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 26, height: 26)
                                        
                                        Image(systemName: "globe")
                                            .font(.system(
                                                size: 15,
                                                weight: .semibold
                                            ))
                                            .foregroundStyle(
                                                LinearGradient.primaryBrand
                                            )
                                    }
                                    
                                    Text("Continue with Google")
                                        .font(.system(
                                            size: geometry.isSmallScreen ? 14 : 15,
                                            weight: .semibold
                                        ))
                                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .frame(height: geometry.isSmallScreen ? 52 : 56)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(
                                                    LinearGradient.cardGlow,
                                                    lineWidth: 2
                                                )
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                            }
                            .scaleEffect(buttonPressedGoogle ? 0.96 : 1.0)
                            .disabled(isLoading)
                            .opacity(animateElements ? 1 : 0)
                            .offset(y: animateElements ? 0 : 20)
                            
                            // Additional Options
                            VStack(spacing: 8) {
                                if !isSignUp {
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            isSignUp = true
                                            clearForm()
                                        }
                                    }) {
                                        Text("Don't have an account? Sign Up")
                                            .font(.system(
                                                size: geometry.isSmallScreen ? 13 : 14,
                                                weight: .semibold
                                            ))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color(red: 0.5, green: 0.4, blue: 1.0),
                                                        Color(red: 0.7, green: 0.35, blue: 0.9)
                                                    ]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
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
                                                size: geometry.isSmallScreen ? 13 : 14,
                                                weight: .semibold
                                            ))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color(red: 0.5, green: 0.4, blue: 1.0),
                                                        Color(red: 0.7, green: 0.35, blue: 0.9)
                                                    ]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                    }
                                    .disabled(isLoading)
                                }
                                
                                // Guest Access (less prominent)
                                Button(action: {
                                    skipAuthentication()
                                }) {
                                    Text("Continue as Guest")
                                        .font(.system(
                                            size: geometry.isSmallScreen ? 11 : 12,
                                            weight: .regular
                                        ))
                                        .foregroundColor(.lightGray)
                                        .lineLimit(1)
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
                        .padding(.all, 20)
                        .background(
                            ZStack {
                                // Base white background
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.white)
                                
                                // Subtle gradient overlay (matching HomeView)
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(
                                        LinearGradient.subtleHighlight
                                    )
                                
                                // Border with gradient (matching HomeView)
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(
                                        LinearGradient.cardGlow,
                                        lineWidth: 1.5
                                    )
                            }
                        )
                        .shadow(
                            color: Color.cardShadow,
                            radius: 12,
                            x: 0,
                            y: 4
                        )
                        .opacity(formOpacity)
                        .offset(y: animateElements ? 0 : 30)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom + 20 : 36)
                }
                .scrollIndicators(.hidden)
                .frame(width: geometry.size.width)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea(.all, edges: .all)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            // Staggered entrance animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                logoScale = 1.0
            }
            withAnimation(.easeInOut(duration: 0.6).delay(0.2)) {
                animateElements = true
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.3)) {
                formOpacity = 1.0
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
    
    private func signInWithGoogle() {
        // Don't set isLoading immediately to avoid presentation conflicts
        errorMessage = nil
        
        // Wait a brief moment for any pending UI updates to complete
        Task {
            // Small delay to ensure UI is ready
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            
            await MainActor.run {
                isLoading = true
            }
            
            // Additional small delay to ensure loading state is rendered
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
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
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(
                    size: geometry.isSmallScreen ? 11 : 12,
                    weight: .medium
                ))
                .foregroundColor(.softPlum)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
            
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(
                        size: geometry.isSmallScreen ? 16 : adaptiveFontSize(17, for: geometry),
                        weight: .semibold
                    ))
                                    .foregroundStyle(
                                        LinearGradient.primaryBrand
                                    )
                    .frame(width: geometry.isSmallScreen ? 20 : adaptiveSize(22, for: geometry))
                    .frame(minWidth: geometry.isSmallScreen ? 20 : adaptiveSize(22, for: geometry))
                
                TextField(title, text: $text)
                    .font(.system(
                        size: geometry.isSmallScreen ? 14 : 15,
                        weight: .medium
                    ))
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 0.97, green: 0.97, blue: 0.98))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.subtleBorder, lineWidth: 1.5)
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
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(
                    size: geometry.isSmallScreen ? 11 : 12,
                    weight: .medium
                ))
                .foregroundColor(.softPlum)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
            
            HStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .font(.system(
                        size: geometry.isSmallScreen ? 16 : adaptiveFontSize(17, for: geometry),
                        weight: .semibold
                    ))
                                    .foregroundStyle(
                                        LinearGradient.primaryBrand
                                    )
                    .frame(width: geometry.isSmallScreen ? 20 : adaptiveSize(22, for: geometry))
                    .frame(minWidth: geometry.isSmallScreen ? 20 : adaptiveSize(22, for: geometry))
                
                if showPassword {
                    TextField(title, text: $text)
                        .font(.system(
                            size: geometry.isSmallScreen ? 14 : 15,
                            weight: .medium
                        ))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                } else {
                    SecureField(title, text: $text)
                        .font(.system(
                            size: geometry.isSmallScreen ? 14 : 15,
                            weight: .medium
                        ))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                }
                
                Button(action: {
                    showPassword.toggle()
                }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .font(.system(
                            size: geometry.isSmallScreen ? 16 : adaptiveFontSize(17, for: geometry),
                            weight: .medium
                        ))
                                        .foregroundColor(.softPlum)
                        .frame(width: geometry.isSmallScreen ? 20 : adaptiveSize(22, for: geometry))
                        .frame(minWidth: geometry.isSmallScreen ? 20 : adaptiveSize(22, for: geometry))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 0.97, green: 0.97, blue: 0.98))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.subtleBorder, lineWidth: 1.5)
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
