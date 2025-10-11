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
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: adaptiveSpacing(16, for: geometry)) {
                        
                        // Top spacing - reduced
                        Spacer()
                            .frame(height: adaptiveSpacing(20, for: geometry))
                        
                        // App Logo and Branding - more compact
                        VStack(spacing: adaptiveSpacing(12, for: geometry)) {
                            // App Logo - smaller
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
                                .overlay(
                                    Text("EW")
                                        .font(.system(size: adaptiveFontSize(28, for: geometry), weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                )
                                .shadow(
                                    color: Color.honeyGold.opacity(0.3),
                                    radius: adaptiveSpacing(8, for: geometry),
                                    x: 0,
                                    y: adaptiveSpacing(3, for: geometry)
                                )
                            
                            // App Name and Tagline - more compact
                            VStack(spacing: adaptiveSpacing(4, for: geometry)) {
                                Text("EverWith")
                                    .font(.system(size: adaptiveFontSize(28, for: geometry), weight: .bold, design: .rounded))
                                    .foregroundColor(.charcoal)
                                
                                Text("Together in every photo.")
                                    .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .medium))
                                    .foregroundColor(.charcoal.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : -20)
                        
                        // Authentication Form
                        VStack(spacing: adaptiveSpacing(16, for: geometry)) {
                            
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
                                        .frame(height: adaptiveSize(40, for: geometry))
                                        .background(
                                            RoundedRectangle(cornerRadius: adaptiveCornerRadius(12, for: geometry))
                                                .fill(isSignUp ? Color.clear : Color.honeyGold.opacity(0.1))
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
                                        .frame(height: adaptiveSize(40, for: geometry))
                                        .background(
                                            RoundedRectangle(cornerRadius: adaptiveCornerRadius(12, for: geometry))
                                                .fill(isSignUp ? Color.honeyGold.opacity(0.1) : Color.clear)
                                        )
                                }
                            }
                            .frame(maxWidth: .infinity)
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
                                HStack(spacing: adaptiveSpacing(8, for: geometry)) {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: isSignUp ? "person.badge.plus.fill" : "arrow.right.circle.fill")
                                            .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
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
                                    .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .medium))
                                    .foregroundColor(.charcoal.opacity(0.6))
                                    .padding(.horizontal, adaptiveSpacing(16, for: geometry))
                                
                                Rectangle()
                                    .fill(Color.charcoal.opacity(0.2))
                                    .frame(height: 1)
                            }
                            .opacity(animateElements ? 1 : 0)
                            
                            // Social Sign In Buttons
                            VStack(spacing: adaptiveSpacing(12, for: geometry)) {
                                
                                // Apple Sign In
                                Button(action: {
                                    signInWithApple()
                                }) {
                                    HStack(spacing: adaptiveSpacing(12, for: geometry)) {
                                        Image(systemName: "applelogo")
                                            .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .medium))
                                            .foregroundColor(.charcoal)
                                        
                                        Text("Continue with Apple")
                                            .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                                            .foregroundColor(.charcoal)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: adaptiveSize(52, for: geometry))
                                    .background(
                                        RoundedRectangle(cornerRadius: adaptiveCornerRadius(16, for: geometry))
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: adaptiveCornerRadius(16, for: geometry))
                                                    .stroke(Color.charcoal.opacity(0.1), lineWidth: 1)
                                            )
                                    )
                                }
                                .disabled(isLoading)
                                
                                // Google Sign In
                                Button(action: {
                                    signInWithGoogle()
                                }) {
                                    HStack(spacing: adaptiveSpacing(12, for: geometry)) {
                                        Image(systemName: "globe")
                                            .font(.system(size: adaptiveFontSize(18, for: geometry), weight: .medium))
                                            .foregroundColor(.charcoal)
                                        
                                        Text("Continue with Google")
                                            .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                                            .foregroundColor(.charcoal)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: adaptiveSize(52, for: geometry))
                                    .background(
                                        RoundedRectangle(cornerRadius: adaptiveCornerRadius(16, for: geometry))
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: adaptiveCornerRadius(16, for: geometry))
                                                    .stroke(Color.charcoal.opacity(0.1), lineWidth: 1)
                                            )
                                    )
                                }
                                .disabled(isLoading)
                            }
                            .opacity(animateElements ? 1 : 0)
                            .offset(y: animateElements ? 0 : 20)
                            
                            // Additional Options
                            VStack(spacing: adaptiveSpacing(8, for: geometry)) {
                                if !isSignUp {
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            isSignUp = true
                                            clearForm()
                                        }
                                    }) {
                                        Text("Don't have an account? Sign Up")
                                            .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .medium))
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
                                            .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .medium))
                                            .foregroundColor(.honeyGold)
                                    }
                                    .disabled(isLoading)
                                }
                                
                                // Guest Access (less prominent)
                                Button(action: {
                                    skipAuthentication()
                                }) {
                                    Text("Continue as Guest")
                                        .font(.system(size: adaptiveFontSize(12, for: geometry), weight: .regular))
                                        .foregroundColor(.charcoal.opacity(0.5))
                                }
                                .disabled(isLoading)
                            }
                            .opacity(animateElements ? 1 : 0)
                            
                            // Error Message
                            if let errorMessage = errorMessage {
                                Text(errorMessage)
                                    .font(.system(size: adaptiveFontSize(14, for: geometry), weight: .medium))
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, adaptiveSpacing(16, for: geometry))
                                    .opacity(animateElements ? 1 : 0)
                            }
                        }
                        .padding(.horizontal, adaptivePadding(for: geometry))
                        .padding(.vertical, adaptiveSpacing(24, for: geometry))
                        .background(
                            RoundedRectangle(cornerRadius: adaptiveCornerRadius(24, for: geometry))
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: adaptiveCornerRadius(24, for: geometry))
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
                        )
                        .shadow(
                            color: Color.black.opacity(0.1),
                            radius: adaptiveSpacing(20, for: geometry),
                            x: 0,
                            y: adaptiveSpacing(8, for: geometry)
                        )
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 30)
                        
                        // Bottom spacing - reduced
                        Spacer()
                            .frame(height: adaptiveSpacing(20, for: geometry))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, adaptivePadding(for: geometry))
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                animateElements = true
            }
        }
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
    
    // MARK: - Adaptive Sizing Functions
    private func adaptivePadding(for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        return max(16, min(24, screenWidth * 0.06))
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
    
    private func adaptiveCornerRadius(_ base: CGFloat, for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        let scaleFactor = screenWidth / 375.0
        return base * scaleFactor
    }
    
    // MARK: - Private Methods
    private func clearForm() {
        email = ""
        password = ""
        name = ""
        confirmPassword = ""
        errorMessage = nil
    }
    
    private func signUp() {
        // Client-side validation
        if password.count < 8 {
            errorMessage = "Password must be at least 8 characters long"
            return
        }
        
        if password.count > 72 {
            errorMessage = "Password must be no more than 72 characters long"
            return
        }
        
        if password != confirmPassword {
            errorMessage = "Passwords do not match"
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
                    print("User signed up: \(user.name) (\(user.email))")
                case .failure(let error):
                    errorMessage = error.localizedDescription
                case .cancelled:
                    break
                }
            }
        }
    }
    
    private func signIn() {
        isLoading = true
        errorMessage = nil
        
        Task {
            let result = await authService.signInWithEmail(email: email, password: password)
            
            await MainActor.run {
                isLoading = false
                
                switch result {
                case .success(let user):
                    print("User signed in: \(user.name) (\(user.email))")
                case .failure(let error):
                    errorMessage = error.localizedDescription
                case .cancelled:
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
                    print("User signed in with Apple: \(user.name) (\(user.email))")
                case .failure(let error):
                    errorMessage = error.localizedDescription
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
                    print("User signed in with Google: \(user.name) (\(user.email))")
                case .failure(let error):
                    errorMessage = error.localizedDescription
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
                    print("User skipped authentication: \(user.name)")
                case .failure(let error):
                    errorMessage = error.localizedDescription
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
            
            HStack(spacing: adaptiveSpacing(12, for: geometry)) {
                Image(systemName: icon)
                    .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                    .foregroundColor(.charcoal.opacity(0.6))
                    .frame(width: adaptiveSize(20, for: geometry))
                
                TextField(title, text: $text)
                    .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                    .foregroundColor(.charcoal)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            .padding(.horizontal, adaptiveSpacing(16, for: geometry))
            .padding(.vertical, adaptiveSpacing(14, for: geometry))
            .background(
                RoundedRectangle(cornerRadius: adaptiveCornerRadius(12, for: geometry))
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: adaptiveCornerRadius(12, for: geometry))
                            .stroke(Color.charcoal.opacity(0.1), lineWidth: 1)
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
            
            HStack(spacing: adaptiveSpacing(12, for: geometry)) {
                Image(systemName: "lock.fill")
                    .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                    .foregroundColor(.charcoal.opacity(0.6))
                    .frame(width: adaptiveSize(20, for: geometry))
                
                if showPassword {
                    TextField(title, text: $text)
                        .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                        .foregroundColor(.charcoal)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } else {
                    SecureField(title, text: $text)
                        .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                        .foregroundColor(.charcoal)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Button(action: {
                    showPassword.toggle()
                }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: adaptiveFontSize(16, for: geometry), weight: .medium))
                        .foregroundColor(.charcoal.opacity(0.6))
                }
            }
            .padding(.horizontal, adaptiveSpacing(16, for: geometry))
            .padding(.vertical, adaptiveSpacing(14, for: geometry))
            .background(
                RoundedRectangle(cornerRadius: adaptiveCornerRadius(12, for: geometry))
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: adaptiveCornerRadius(12, for: geometry))
                            .stroke(Color.charcoal.opacity(0.1), lineWidth: 1)
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
