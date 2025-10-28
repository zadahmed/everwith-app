//
//  AuthenticationService.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import Foundation
import SwiftUI
import Combine
import GoogleSignIn

class AuthenticationService: ObservableObject {
    @Published var authenticationState: AuthenticationState = .loading
    @Published var currentUser: User?
    
    private let userDefaults = UserDefaults.standard
    private let userKey = "current_user"
    private let tokenKey = "access_token"
    private let tokenExpiryKey = "token_expiry"
    
    // Optimization: Cache validation results
    private var lastValidationResult: (isValid: Bool, timestamp: Date)?
    private let validationCacheTime: TimeInterval = 60.0 // Cache for 1 minute
    
    init() {
        // Load stored user and validate session on startup
        Task {
            await validateSessionOnStartup()
        }
    }
    
    // MARK: - Google Sign In
    func signInWithGoogle() async -> SignInResult {
        print("🔵 GOOGLE SIGN IN: Starting...")
        
        // Wait for any pending UI updates to complete
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Find the appropriate presenting view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first else {
            print("❌ GOOGLE SIGN IN: No window scene found")
            return .failure(AuthenticationError.noPresentingViewController)
        }
        
        // Get the top-most view controller to avoid presentation conflicts
        var presentingViewController = window.rootViewController
        while let presented = presentingViewController?.presentedViewController {
            presentingViewController = presented
        }
        
        guard let finalViewController = presentingViewController else {
            print("❌ GOOGLE SIGN IN: No presenting view controller found")
            return .failure(AuthenticationError.noPresentingViewController)
        }
        
        print("✅ GOOGLE SIGN IN: Found presenting view controller: \(type(of: finalViewController))")
        
        do {
            // Configure Google Sign-In with multiple fallback approaches
            var clientId: String?
            
            // Approach 1: Try loading from GoogleService-Info.plist
            if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
               let plist = NSDictionary(contentsOfFile: path),
               let id = plist["CLIENT_ID"] as? String {
                clientId = id
                print("✅ GOOGLE SIGN IN: Found GoogleService-Info.plist")
            }
            // Approach 2: Try loading from Info.plist
            else if let id = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String {
                clientId = id
                print("✅ GOOGLE SIGN IN: Found GIDClientID in Info.plist")
            }
            // Approach 3: Use configured client ID
            else {
                clientId = "1033332546845-859k5rlpul70f5uu9sdi05rfevi45hgf.apps.googleusercontent.com"
                print("✅ GOOGLE SIGN IN: Using configured client ID")
            }
            
            guard let finalClientId = clientId else {
                print("❌ GOOGLE SIGN IN: Could not find client ID")
                return .failure(AuthenticationError.googleConfigurationError)
            }
            
            print("✅ GOOGLE SIGN IN: Client ID configured: \(finalClientId.prefix(20))...")
            
            // Configure Google Sign-In
            let configuration = GIDConfiguration(clientID: finalClientId)
            GIDSignIn.sharedInstance.configuration = configuration
            
            print("🔵 GOOGLE SIGN IN: Presenting sign-in UI...")
            
            // Perform Google Sign-In with the final view controller
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: finalViewController)
            let user = result.user
            
            print("✅ GOOGLE SIGN IN: User signed in - Email: \(user.profile?.email ?? "no email")")
            
            guard let idToken = user.idToken?.tokenString else {
                print("❌ GOOGLE SIGN IN: Missing ID token")
                return .failure(AuthenticationError.missingGoogleToken)
            }
            
            print("✅ GOOGLE SIGN IN: ID token obtained - \(idToken.prefix(20))...")
            print("🔵 GOOGLE SIGN IN: Authenticating with backend...")
            
            // Send ID token to backend for verification
            let authResult = await authenticateWithBackend(idToken: idToken, provider: .google)
            
            switch authResult {
            case .success(let user):
                print("🎉 GOOGLE SIGN IN: Successfully authenticated - User: \(user.name)")
            case .failure(let error):
                print("❌ GOOGLE SIGN IN: Backend authentication failed - \(error.localizedDescription)")
            case .cancelled:
                print("🚫 GOOGLE SIGN IN: Cancelled")
            }
            
            return authResult
            
        } catch let error as NSError {
            print("❌ GOOGLE SIGN IN: Error occurred - Code: \(error.code), Domain: \(error.domain)")
            print("❌ GOOGLE SIGN IN: Error description: \(error.localizedDescription)")
            
            // Handle specific Google Sign-In errors
            if error.domain == "com.google.GIDSignIn" {
                if error.code == -4 {
                    print("🚫 GOOGLE SIGN IN: User cancelled")
                    return .cancelled
                }
            }
            
            return .failure(error)
        }
    }
    
    // MARK: - Email/Password Authentication
    func signUpWithEmail(email: String, password: String, name: String) async -> SignInResult {
        // Validate inputs before sending to backend
        guard !email.isEmpty, !password.isEmpty, !name.isEmpty else {
            return .failure(AuthenticationError.backendError("All fields are required"))
        }
        
        guard email.contains("@") else {
            return .failure(AuthenticationError.backendError("Please enter a valid email address"))
        }
        
        guard password.count >= 8 else {
            return .failure(AuthenticationError.backendError("Password must be at least 8 characters long"))
        }
        
        guard password.count <= 72 else {
            return .failure(AuthenticationError.backendError("Password must be no more than 72 characters long"))
        }
        
        let request = AuthRequest(email: email, password: password, name: name)
        return await authenticateWithBackend(request: request, endpoint: AppConfiguration.AuthEndpoints.register)
    }
    
    func signInWithEmail(email: String, password: String) async -> SignInResult {
        print("🔐 SIGN IN: Starting email/password authentication")
        print("📧 EMAIL: \(email)")
        
        // Validate inputs before sending to backend
        guard !email.isEmpty, !password.isEmpty else {
            print("❌ VALIDATION: Email and password are required")
            return .failure(AuthenticationError.backendError("Email and password are required"))
        }
        
        guard email.contains("@") else {
            print("❌ VALIDATION: Invalid email format")
            return .failure(AuthenticationError.backendError("Please enter a valid email address"))
        }
        
        print("✅ VALIDATION: Input validation passed")
        
        let request = LoginRequest(email: email, password: password)
        return await authenticateWithBackend(request: request, endpoint: AppConfiguration.AuthEndpoints.login)
    }
    
    // MARK: - Guest Sign In
    func signInAsGuest() async -> SignInResult {
        let guestUser = User(
            id: "guest_\(UUID().uuidString)",
            email: "guest@everwith.app",
            name: "Guest User",
            profileImageURL: nil,
            provider: .guest,
            createdAt: Date()
        )
        
        await signInUser(guestUser)
        return .success(guestUser)
    }
    
    // MARK: - Session Management
    
    /// Validates session on app startup - only called once when app launches
    private func validateSessionOnStartup() async {
        print("🔄 SESSION: Validating session on startup...")
        
        // Try to load stored user
        guard let data = userDefaults.data(forKey: userKey),
              let user = try? JSONDecoder().decode(User.self, from: data),
              let token = userDefaults.string(forKey: tokenKey) else {
            print("ℹ️ SESSION: No stored session found")
            await MainActor.run {
                self.authenticationState = .unauthenticated
            }
            return
        }
        
        // Reject guest users - require full authentication
        if user.provider == .guest {
            print("🚫 SESSION: Guest session detected - clearing and requiring authentication")
            userDefaults.removeObject(forKey: userKey)
            userDefaults.removeObject(forKey: tokenKey)
            userDefaults.removeObject(forKey: tokenExpiryKey)
            await MainActor.run {
                self.authenticationState = .unauthenticated
            }
            return
        }
        
        // Check local token expiry first
        if isTokenExpired() {
            print("⚠️ SESSION: Token expired locally")
            await MainActor.run {
                self.authenticationState = .unauthenticated
            }
            return
        }
        
        // Validate token with backend
        let isValid = await validateTokenWithBackend(token)
        
        if isValid {
            print("✅ SESSION: Session restored successfully")
            await MainActor.run {
                self.currentUser = user
                self.authenticationState = .authenticated(user)
            }
        } else {
            print("⚠️ SESSION: Backend validation failed")
            // Clear invalid session
            userDefaults.removeObject(forKey: userKey)
            userDefaults.removeObject(forKey: tokenKey)
            userDefaults.removeObject(forKey: tokenExpiryKey)
            
            await MainActor.run {
                self.authenticationState = .unauthenticated
            }
        }
    }
    
    func validateSession() async -> Bool {
        guard let token = userDefaults.string(forKey: tokenKey) else {
            // Silently fail - no token is expected for fresh installs or when not authenticated
            print("ℹ️ SESSION: No token found - user needs to authenticate")
            return false
        }
        
        // Check if token is expired
        if isTokenExpired() {
            print("⚠️ SESSION: Token expired")
            await forceLogout(reason: "Token expired")
            return false
        }
        
        // Check cached validation result
        if let cachedResult = lastValidationResult,
           Date().timeIntervalSince(cachedResult.timestamp) < validationCacheTime {
            print("📋 SESSION: Using cached validation result: \(cachedResult.isValid)")
            return cachedResult.isValid
        }
        
        // Validate token with backend
        let isValid = await validateTokenWithBackend(token)
        
        // Cache the result
        lastValidationResult = (isValid: isValid, timestamp: Date())
        
        return isValid
    }
    
    private func isTokenExpired() -> Bool {
        guard let expiryDate = userDefaults.object(forKey: tokenExpiryKey) as? Date else {
            return true // No expiry date means expired
        }
        return Date() >= expiryDate
    }
    
    private func validateTokenWithBackend(_ token: String) async -> Bool {
        guard let url = URL(string: AppConfiguration.authURL(for: AppConfiguration.AuthEndpoints.me)) else {
            print("❌ SESSION: Invalid URL for /me endpoint")
            return false
        }
        
        do {
            // Make request with the token
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("ℹ️ SESSION: Invalid response from backend")
                return false
            }
            
            if httpResponse.statusCode == 200 {
                print("✅ SESSION: Backend validation successful")
                return true
            } else {
                // 401/403 is expected for invalid/expired tokens - not an error
                print("ℹ️ SESSION: Token not valid (status: \(httpResponse.statusCode))")
                return false
            }
        } catch {
            // Network errors or other issues
            print("ℹ️ SESSION: Could not validate with backend - \(error.localizedDescription)")
            return false
        }
    }
    
    
    private func forceLogout(reason: String) async {
        print("🔓 SESSION: Logging out - \(reason)")
        
        // Sign out from Google if user was signed in with Google
        if let user = currentUser, user.provider == .google {
            GIDSignIn.sharedInstance.signOut()
            print("🔵 GOOGLE: Signed out")
        }
        
        // Clear stored user data
        userDefaults.removeObject(forKey: userKey)
        userDefaults.removeObject(forKey: tokenKey)
        userDefaults.removeObject(forKey: tokenExpiryKey)
        
        // Update state
        await MainActor.run {
            self.currentUser = nil
            self.authenticationState = .unauthenticated
        }
    }
    
    // MARK: - Sign Out
    func signOut() async {
        // Sign out from Google if user was signed in with Google
        if let user = currentUser, user.provider == .google {
            GIDSignIn.sharedInstance.signOut()
        }
        
        // Call backend logout endpoint
        await logoutFromBackend()
        
        // Clear stored user data
        userDefaults.removeObject(forKey: userKey)
        userDefaults.removeObject(forKey: tokenKey)
        userDefaults.removeObject(forKey: tokenExpiryKey)
        
        // Update state
        DispatchQueue.main.async {
            self.currentUser = nil
            self.authenticationState = .unauthenticated
            
            // Reset onboarding state so user sees onboarding again
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            
            // Post notification to reset onboarding in AppCoordinator
            NotificationCenter.default.post(name: .onboardingReset, object: nil)
        }
    }
    
    // MARK: - Backend Integration
    private func authenticateWithBackend(idToken: String, provider: User.AuthProvider) async -> SignInResult {
        let request = GoogleAuthRequest(id_token: idToken)
        return await authenticateWithBackend(request: request, endpoint: AppConfiguration.AuthEndpoints.google, provider: provider)
    }
    
    private func authenticateWithBackend<T: Codable>(request: T, endpoint: String, provider: User.AuthProvider = .email) async -> SignInResult {
        guard let url = URL(string: AppConfiguration.authURL(for: endpoint)) else {
            return .failure(AuthenticationError.networkError)
        }
        
        do {
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let jsonData = try JSONEncoder().encode(request)
            urlRequest.httpBody = jsonData
            
            // Debug: Log the request being sent
            if let requestString = String(data: jsonData, encoding: .utf8) {
                print("🔐 AUTH REQUEST: Sending to \(url)")
                print("📤 REQUEST BODY: \(requestString)")
            }
            
            // Configure URLSession with timeout
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30
            config.timeoutIntervalForResource = 60
            
            let session = URLSession(configuration: config)
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ AUTH ERROR: Invalid response type")
                return .failure(AuthenticationError.networkError)
            }
            
            // Log the response for debugging
            print("📥 AUTH RESPONSE: Status \(httpResponse.statusCode)")
            print("📥 AUTH RESPONSE: Headers \(httpResponse.allHeaderFields)")
            print("📥 AUTH RESPONSE: Data size \(data.count) bytes")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 RESPONSE BODY: \(responseString)")
            } else {
                print("❌ RESPONSE: Unable to convert to UTF-8 string")
            }
            
            // Check for empty response
            guard !data.isEmpty else {
                print("❌ AUTH ERROR: Empty response from server")
                return .failure(AuthenticationError.backendError("Empty response from server"))
            }
            
            if httpResponse.statusCode == 200 {
                do {
                    // Simple decoder - backend uses snake_case
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    
                    // Use flexible date handling
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    decoder.dateDecodingStrategy = .custom { decoder in
                        let container = try decoder.singleValueContainer()
                        let dateString = try container.decode(String.self)
                        
                        // Try ISO8601 first
                        if let date = formatter.date(from: dateString) {
                            return date
                        }
                        
                        // Try simple format
                        let simpleFormatter = ISO8601DateFormatter()
                        if let date = simpleFormatter.date(from: dateString) {
                            return date
                        }
                        
                        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
                    }
                    
                    let authResponse = try decoder.decode(AuthResponse.self, from: data)
                    print("✅ AUTH SUCCESS: Successfully decoded response")
                    print("👤 USER DATA: ID=\(authResponse.user.id), Email=\(authResponse.user.email), Name=\(authResponse.user.name)")
                    print("🎫 ACCESS TOKEN: \(authResponse.access_token.prefix(20))...")
                    
                    let user = User(
                        id: authResponse.user.id,
                        email: authResponse.user.email,
                        name: authResponse.user.name,
                        profileImageURL: authResponse.user.profileImageUrl,
                        provider: provider,
                        createdAt: authResponse.user.createdAt ?? Date()
                    )
                    
                    await signInUser(user, accessToken: authResponse.access_token)
                    print("🎉 AUTH COMPLETE: User signed in successfully")
                    return .success(user)
                } catch {
                    print("❌ JSON DECODING ERROR: \(error)")
                    print("🔍 ERROR DETAILS: \(error.localizedDescription)")
                    
                    // Try to extract more info from the decoding error
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .dataCorrupted(let context):
                            print("❌ DATA CORRUPTED: \(context.debugDescription)")
                        case .keyNotFound(let key, let context):
                            print("❌ KEY NOT FOUND: \(key.stringValue) - \(context.debugDescription)")
                        case .typeMismatch(let type, let context):
                            print("❌ TYPE MISMATCH: \(type) - \(context.debugDescription)")
                        case .valueNotFound(let type, let context):
                            print("❌ VALUE NOT FOUND: \(type) - \(context.debugDescription)")
                        @unknown default:
                            print("❌ UNKNOWN DECODING ERROR")
                        }
                    }
                    
                    print("📄 RAW RESPONSE: \(String(data: data, encoding: .utf8) ?? "Unable to convert to string")")
                    print("📄 RESPONSE FIRST 200 CHARS: \(String(data: data.prefix(200), encoding: .utf8) ?? "Unable to convert")")
                    
                    return .failure(AuthenticationError.backendError("Invalid response format from server: \(error.localizedDescription)"))
                }
            } else {
                // Handle different error status codes
                print("⚠️ AUTH ERROR: Non-200 status code: \(httpResponse.statusCode)")
                
                // Try to decode error response
                let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                var errorMessage = errorResponse?.detail ?? "Authentication failed (Status: \(httpResponse.statusCode))"
                
                // If decoding failed, try to get raw response
                if errorResponse == nil, let rawResponse = String(data: data, encoding: .utf8) {
                    errorMessage = rawResponse.isEmpty ? "Server returned error \(httpResponse.statusCode)" : rawResponse
                }
                
                return .failure(AuthenticationError.backendError(errorMessage))
            }
        } catch let error as URLError {
            // Handle URL-specific errors
            print("❌ URL ERROR: \(error.localizedDescription)")
            print("❌ CODE: \(error.code.rawValue)")
            
            var errorMessage = "Network error: \(error.localizedDescription)"
            switch error.code {
            case .timedOut:
                errorMessage = "Request timed out. Please check your connection and try again."
            case .notConnectedToInternet:
                errorMessage = "No internet connection. Please check your network."
            case .cannotFindHost:
                errorMessage = "Cannot reach server. Please try again later."
            case .cannotConnectToHost:
                errorMessage = "Cannot connect to server. Please check your network."
            default:
                errorMessage = "Network error: \(error.localizedDescription)"
            }
            
            return .failure(AuthenticationError.backendError(errorMessage))
        } catch {
            print("❌ UNKNOWN ERROR: \(error)")
            return .failure(AuthenticationError.backendError("Unexpected error: \(error.localizedDescription)"))
        }
    }
    
    private func logoutFromBackend() async {
        guard let token = userDefaults.string(forKey: tokenKey),
              let url = URL(string: AppConfiguration.authURL(for: AppConfiguration.AuthEndpoints.logout)) else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            _ = try await URLSession.shared.data(for: request)
        } catch {
            print("Logout request failed: \(error)")
        }
    }
    
    // MARK: - Private Methods
    private func signInUser(_ user: User, accessToken: String? = nil) async {
        await MainActor.run {
            currentUser = user
            authenticationState = .authenticated(user)
        }
        storeUser(user)
        if let token = accessToken {
            storeToken(token)
        }
    }
    
    private func storeUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            userDefaults.set(encoded, forKey: userKey)
        }
    }
    
    private func storeToken(_ token: String) {
        userDefaults.set(token, forKey: tokenKey)
        
        // Store token expiry (7 days from now - matches backend setting)
        // 7 days * 24 hours * 60 minutes * 60 seconds = 604800 seconds
        let expiryDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        userDefaults.set(expiryDate, forKey: tokenExpiryKey)
        print("✅ Token stored with 7-day expiry: \(expiryDate)")
    }
    
    
}

// MARK: - Authentication Errors
enum AuthenticationError: LocalizedError {
    case noPresentingViewController
    case missingUserInfo
    case invalidCredential
    case networkError
    case googleConfigurationError
    case missingGoogleToken
    case backendError(String)
    
    var errorDescription: String? {
        switch self {
        case .noPresentingViewController:
            return "Unable to present sign-in interface"
        case .missingUserInfo:
            return "Missing required user information"
        case .invalidCredential:
            return "Invalid authentication credential"
        case .networkError:
            return "Network error occurred"
        case .googleConfigurationError:
            return "Google Sign In is not configured. Please try another sign-in method."
        case .missingGoogleToken:
            return "Google authentication token is missing"
        case .backendError(let message):
            return message
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .googleConfigurationError:
            return "Please try email/password authentication or contact support."
        case .networkError:
            return "Please check your internet connection and try again."
        case .backendError:
            return "Please try again or contact support if the issue persists."
        default:
            return "Please try again or contact support if the issue persists."
        }
    }
}

