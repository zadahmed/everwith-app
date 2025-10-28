//
//  ModernAuthenticationView.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI

struct ModernAuthenticationView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @FocusState private var focusedField: FocusedField?
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
    @State private var contentOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.8
    
    enum FocusedField {
        case name, email, password, confirmPassword
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundView(geometry: geometry)
                
                VStack(spacing: 0) {
                    // Header Section (fixed)
                    VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 12, for: geometry)) {
                        // App Logo and Branding
                        VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 12, for: geometry)) {
                            // App Logo - circular and larger
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
                                        width: geometry.adaptiveSize(120),
                                        height: geometry.adaptiveSize(120)
                                    )
                                    .blur(radius: 20)
                                
                                Image("AppLogo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(
                                        width: geometry.adaptiveSize(100),
                                        height: geometry.adaptiveSize(100)
                                    )
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.blushPink.opacity(0.9),
                                                        Color.roseMagenta.opacity(0.7)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 3
                                            )
                                    )
                                    .shadow(
                                        color: Color.blushPink.opacity(0.3),
                                        radius: 8,
                                        x: 0,
                                        y: 4
                                    )
                            }
                            .scaleEffect(logoScale)
                            
                            // App Name and Tagline
                            VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 6, for: geometry)) {
                                Text("Everwith")
                                    .font(.system(
                                        size: ResponsiveDesign.adaptiveFontSize(baseSize: 32, for: geometry),
                                        weight: .black,
                                        design: .rounded
                                    ))
                                    .foregroundColor(.deepPlum)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                
                                Text("Create beautiful memories together")
                                    .font(.system(
                                        size: ResponsiveDesign.adaptiveFontSize(baseSize: 15, for: geometry),
                                        weight: .medium
                                    ))
                                    .foregroundColor(.softPlum)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.9)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.horizontal, geometry.adaptivePadding())
                        .padding(.top, geometry.safeAreaInsets.top > 0 ? geometry.safeAreaInsets.top + 60 : 76)
                        .padding(.bottom, ResponsiveDesign.adaptiveSpacing(baseSpacing: 20, for: geometry))
                        .opacity(contentOpacity)
                        .offset(y: animateElements ? 0 : -20)
                    }
                    
                    // Scrollable Form Content with keyboard handling
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 14) {
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
                                            size: geometry.adaptiveFontSize(14),
                                            weight: .semibold
                                        ))
                                        .foregroundColor(isSignUp ? .softPlum : .white)
                                        .frame(height: 42)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            ZStack {
                                                if !isSignUp {
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(
                                                            LinearGradient.primaryBrand
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
                                            size: geometry.adaptiveFontSize(14),
                                            weight: .semibold
                                        ))
                                        .foregroundColor(isSignUp ? .white : .softPlum)
                                        .frame(height: 42)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            ZStack {
                                                if isSignUp {
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(
                                                            LinearGradient.primaryBrand
                                                        )
                                                        .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                                                }
                                            }
                                        )
                                }
                            }
                            .padding(3)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                            )
                            
                            // Form Fields
                            VStack(spacing: 12) {
                                // Name field (only for sign up)
                                if isSignUp {
                                    ModernTextField(
                                        title: "Full Name",
                                        text: $name,
                                        icon: "person.fill",
                                        field: $focusedField,
                                        fieldType: .name,
                                        geometry: geometry
                                    )
                                    .id("name")
                                    .opacity(contentOpacity)
                                    .offset(x: animateElements ? 0 : -20)
                                }
                                
                                // Email field
                                ModernTextField(
                                    title: "Email",
                                    text: $email,
                                    icon: "envelope.fill",
                                    keyboardType: .emailAddress,
                                    field: $focusedField,
                                    fieldType: .email,
                                    geometry: geometry
                                )
                                .id("email")
                                .opacity(contentOpacity)
                                .offset(x: animateElements ? 0 : -20)
                                
                                // Password field
                                ModernPasswordField(
                                    title: "Password",
                                    text: $password,
                                    showPassword: $showPassword,
                                    field: $focusedField,
                                    fieldType: .password,
                                    geometry: geometry
                                )
                                .id("password")
                                .opacity(contentOpacity)
                                .offset(x: animateElements ? 0 : -20)
                                
                                // Confirm Password field (only for sign up)
                                if isSignUp {
                                    ModernPasswordField(
                                        title: "Confirm Password",
                                        text: $confirmPassword,
                                        showPassword: $showConfirmPassword,
                                        field: $focusedField,
                                        fieldType: .confirmPassword,
                                        geometry: geometry
                                    )
                                    .id("confirmPassword")
                                    .opacity(contentOpacity)
                                    .offset(x: animateElements ? 0 : -20)
                                }
                            }
                            
                            // Primary Action Button
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
                                HStack(spacing: 8) {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: isSignUp ? "person.badge.plus.fill" : "arrow.right.circle.fill")
                                            .font(.system(
                                                size: 16,
                                                weight: .medium
                                            ))
                                    }
                                    
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                        .font(.system(
                                            size: 15,
                                            weight: .semibold
                                        ))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .foregroundColor(.white)
                                .frame(height: 48)
                                .frame(maxWidth: .infinity)
                                .background(
                                    ZStack {
                                        // Gradient background
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                LinearGradient.primaryBrand
                                            )
                                        
                                        // Shimmer overlay effect
                                        RoundedRectangle(cornerRadius: 12)
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
                                    color: Color.blushPink.opacity(0.3),
                                    radius: 8,
                                    x: 0,
                                    y: 4
                                )
                            }
                            .scaleEffect(buttonPressedEmail ? 0.96 : 1.0)
                            .disabled(isLoading || !isFormValid)
                            .opacity(isFormValid ? 1 : 0.6)
                            .opacity(contentOpacity)
                            .offset(y: animateElements ? 0 : 20)
                            
                            // Divider
                            HStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 12, for: geometry)) {
                                Rectangle()
                                    .fill(Color.subtleBorder)
                                    .frame(height: 1)
                                
                                Text("or")
                                    .font(.system(
                                        size: geometry.adaptiveFontSize(13),
                                        weight: .medium
                                    ))
                                    .foregroundColor(.softPlum)
                                    .padding(.horizontal, 8)
                                    .fixedSize()
                                
                                Rectangle()
                                    .fill(Color.subtleBorder)
                                    .frame(height: 1)
                            }
                            .opacity(contentOpacity)
                            
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
                                    // Google logo
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.white)
                                            .frame(width: 20, height: 20)
                                        
                                        // Google "G" icon
                                        Text("G")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [Color.blue, Color.green, Color.yellow, Color.orange],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    }
                                    
                                    Text("Continue with Google")
                                        .font(.system(
                                            size: 15,
                                            weight: .medium
                                        ))
                                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .frame(height: 48)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    LinearGradient.cardGlow,
                                                    lineWidth: 1.5
                                                )
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                            }
                            .scaleEffect(buttonPressedGoogle ? 0.96 : 1.0)
                            .disabled(isLoading)
                            .opacity(contentOpacity)
                            .offset(y: animateElements ? 0 : 20)
                            
                            // Additional Options
                            VStack(spacing: ResponsiveDesign.adaptiveSpacing(baseSpacing: 8, for: geometry)) {
                                if !isSignUp {
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            isSignUp = true
                                            clearForm()
                                        }
                                    }) {
                                        Text("Don't have an account? Sign Up")
                                            .font(.system(
                                                size: geometry.adaptiveFontSize(14),
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
                                                size: geometry.adaptiveFontSize(14),
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
                                
                            }
                            .opacity(contentOpacity)
                            
                            // Error Message
                            if let errorMessage = errorMessage {
                                Text(errorMessage)
                                    .font(.system(
                                        size: geometry.adaptiveFontSize(13),
                                        weight: .medium
                                    ))
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, geometry.adaptivePadding())
                                    .opacity(contentOpacity)
                            }
                            
                            // Padding at bottom for keyboard spacing
                            Color.clear.frame(height: 300)
                        }
                        .padding(.all, geometry.adaptivePadding())
                        .background(
                            ZStack {
                                // Base white background
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white)
                                
                                // Subtle gradient overlay
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        LinearGradient.subtleHighlight
                                    )
                                
                                // Border with gradient
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        LinearGradient.cardGlow,
                                        lineWidth: 1
                                    )
                            }
                        )
                        .shadow(
                            color: Color.cardShadow,
                            radius: 8,
                            x: 0,
                            y: 3
                        )
                        .opacity(contentOpacity)
                        .offset(y: animateElements ? 0 : 30)
                    }
                    .padding(.horizontal, geometry.adaptivePadding())
                    .padding(.bottom, 16)
                    .onChange(of: focusedField) { field in
                        if let field = field {
                            // Add small delay to ensure keyboard is shown
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    proxy.scrollTo(field, anchor: .center)
                                }
                            }
                        }
                    }
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                contentOpacity = 1.0
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
    
    // MARK: - View Builders
    
    @ViewBuilder
    private func backgroundView(geometry: GeometryProxy) -> some View {
        CleanWhiteBackground()
            .frame(width: geometry.size.width, height: geometry.size.height)
            .ignoresSafeArea(.all, edges: .all)
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
            
            // Wait for Google modal to fully dismiss
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            await MainActor.run {
                isLoading = false
                
                switch result {
                case .success(let user):
                    print("User signed in with Google successfully: \(user.name) (\(user.email))")
                    // Success! The app will automatically navigate to HomeView via auth state change
                case .failure(let error):
                    // Delay error presentation to avoid conflicts
                    errorMessage = error.localizedDescription
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showErrorAlert = true
                    }
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
    @FocusState.Binding var field: ModernAuthenticationView.FocusedField?
    let fieldType: ModernAuthenticationView.FocusedField
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(
                    size: 12,
                    weight: .medium
                ))
                .foregroundColor(.softPlum)
                .lineLimit(1)
            
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(
                        size: 16,
                        weight: .medium
                    ))
                    .foregroundStyle(
                        LinearGradient.primaryBrand
                    )
                    .frame(width: 20)
                
                TextField(title, text: $text)
                    .font(.system(
                        size: 15,
                        weight: .regular
                    ))
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($field, equals: fieldType)
                    .submitLabel(fieldType == .password || fieldType == .confirmPassword ? .done : .next)
            }
            .frame(height: 48)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.97, green: 0.97, blue: 0.98))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                field == fieldType ? AnyShapeStyle(LinearGradient.primaryBrand) : AnyShapeStyle(Color.subtleBorder),
                                lineWidth: field == fieldType ? 2 : 1
                            )
                    )
            )
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Modern Password Field Component
struct ModernPasswordField: View {
    let title: String
    @Binding var text: String
    @Binding var showPassword: Bool
    @FocusState.Binding var field: ModernAuthenticationView.FocusedField?
    let fieldType: ModernAuthenticationView.FocusedField
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(
                    size: 12,
                    weight: .medium
                ))
                .foregroundColor(.softPlum)
                .lineLimit(1)
            
            HStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .font(.system(
                        size: 16,
                        weight: .medium
                    ))
                    .foregroundStyle(
                        LinearGradient.primaryBrand
                    )
                    .frame(width: 20)
                
                if showPassword {
                    TextField(title, text: $text)
                        .font(.system(
                            size: 15,
                            weight: .regular
                        ))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($field, equals: fieldType)
                        .submitLabel(.done)
                } else {
                    SecureField(title, text: $text)
                        .font(.system(
                            size: 15,
                            weight: .regular
                        ))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($field, equals: fieldType)
                        .submitLabel(.done)
                }
                
                Button(action: {
                    showPassword.toggle()
                }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .font(.system(
                            size: 16,
                            weight: .medium
                        ))
                        .foregroundColor(.softPlum)
                        .frame(width: 20)
                }
            }
            .frame(height: 48)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.97, green: 0.97, blue: 0.98))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                field == fieldType ? AnyShapeStyle(LinearGradient.primaryBrand) : AnyShapeStyle(Color.subtleBorder),
                                lineWidth: field == fieldType ? 2 : 1
                            )
                    )
            )
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ModernAuthenticationView()
        .environmentObject(AuthenticationService())
}
