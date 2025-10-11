//
//  AuthenticationService.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import Foundation
import AuthenticationServices
import Combine
import UIKit
import GoogleSignIn

class AuthenticationService: NSObject, ObservableObject {
    @Published var authenticationState: AuthenticationState = .loading
    @Published var currentUser: User?
    
    private let userDefaults = UserDefaults.standard
    private let userKey = "current_user"
    private let tokenKey = "access_token"
    private let baseURL = "http://localhost:8000" // Change this to your backend URL
    
    override init() {
        super.init()
        loadStoredUser()
    }
    
    // MARK: - Apple Sign In
    func signInWithApple() async -> SignInResult {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        
        return await withCheckedContinuation { continuation in
            self.appleSignInContinuation = continuation
            authorizationController.performRequests()
        }
    }
    
    // MARK: - Google Sign In
    func signInWithGoogle() async -> SignInResult {
        guard let presentingViewController = UIApplication.shared.windows.first?.rootViewController else {
            return .failure(AuthenticationError.noPresentingViewController)
        }
        
        do {
            // Configure Google Sign-In
            guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
                  let plist = NSDictionary(contentsOfFile: path),
                  let clientId = plist["CLIENT_ID"] as? String else {
                return .failure(AuthenticationError.googleConfigurationError)
            }
            
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
            
            // Perform Google Sign-In
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            let user = result.user
            
            guard let idToken = user.idToken?.tokenString else {
                return .failure(AuthenticationError.missingGoogleToken)
            }
            
            // Send ID token to backend for verification
            return await authenticateWithBackend(idToken: idToken, provider: .google)
            
        } catch {
            return .failure(error)
        }
    }
    
    // MARK: - Email/Password Authentication
    func signUpWithEmail(email: String, password: String, name: String) async -> SignInResult {
        let request = AuthRequest(email: email, password: password, name: name)
        return await authenticateWithBackend(request: request, endpoint: "/api/auth/register")
    }
    
    func signInWithEmail(email: String, password: String) async -> SignInResult {
        let request = LoginRequest(email: email, password: password)
        return await authenticateWithBackend(request: request, endpoint: "/api/auth/login")
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
        
        // Update state
        DispatchQueue.main.async {
            self.currentUser = nil
            self.authenticationState = .unauthenticated
        }
    }
    
    // MARK: - Backend Integration
    private func authenticateWithBackend(idToken: String, provider: User.AuthProvider) async -> SignInResult {
        let request = GoogleAuthRequest(id_token: idToken)
        return await authenticateWithBackend(request: request, endpoint: "/api/auth/google")
    }
    
    private func authenticateWithBackend<T: Codable>(request: T, endpoint: String) async -> SignInResult {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            return .failure(AuthenticationError.networkError)
        }
        
        do {
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let jsonData = try JSONEncoder().encode(request)
            urlRequest.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(AuthenticationError.networkError)
            }
            
            if httpResponse.statusCode == 200 {
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                let user = User(
                    id: authResponse.user.id,
                    email: authResponse.user.email,
                    name: authResponse.user.name,
                    profileImageURL: authResponse.user.profile_image_url,
                    provider: provider,
                    createdAt: authResponse.user.created_at
                )
                
                await signInUser(user, accessToken: authResponse.access_token)
                return .success(user)
            } else {
                let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                let errorMessage = errorResponse?.detail ?? "Authentication failed"
                return .failure(AuthenticationError.backendError(errorMessage))
            }
        } catch {
            return .failure(error)
        }
    }
    
    private func logoutFromBackend() async {
        guard let token = userDefaults.string(forKey: tokenKey),
              let url = URL(string: "\(baseURL)/api/auth/logout") else {
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
    }
    
    private func loadStoredUser() {
        guard let data = userDefaults.data(forKey: userKey),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            DispatchQueue.main.async {
                self.authenticationState = .unauthenticated
            }
            return
        }
        
        DispatchQueue.main.async {
            self.currentUser = user
            self.authenticationState = .authenticated(user)
        }
    }
    
    // MARK: - Apple Sign In Continuation
    private var appleSignInContinuation: CheckedContinuation<SignInResult, Never>?
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthenticationService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            appleSignInContinuation?.resume(returning: .failure(AuthenticationError.invalidCredential))
            return
        }
        
        let userID = appleIDCredential.user
        let email = appleIDCredential.email
        let fullName = appleIDCredential.fullName
        
        // Create user name from components
        let name: String
        if let fullName = fullName {
            let formatter = PersonNameComponentsFormatter()
            name = formatter.string(from: fullName)
        } else {
            name = "User" // Fallback name
        }
        
        let user = User(
            id: userID,
            email: email ?? "no-email@privaterelay.appleid.com",
            name: name,
            profileImageURL: nil,
            provider: .apple,
            createdAt: Date()
        )
        
        Task {
            await signInUser(user)
            appleSignInContinuation?.resume(returning: .success(user))
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                appleSignInContinuation?.resume(returning: .cancelled)
            case .failed:
                let detailedError = AuthenticationError.appleSignInFailed(authError.localizedDescription)
                appleSignInContinuation?.resume(returning: .failure(detailedError))
            case .invalidResponse:
                let detailedError = AuthenticationError.invalidAppleResponse
                appleSignInContinuation?.resume(returning: .failure(detailedError))
            case .notHandled:
                let detailedError = AuthenticationError.appleSignInNotHandled
                appleSignInContinuation?.resume(returning: .failure(detailedError))
            case .unknown:
                let detailedError = AuthenticationError.appleSignInUnknown
                appleSignInContinuation?.resume(returning: .failure(detailedError))
            @unknown default:
                appleSignInContinuation?.resume(returning: .failure(error))
            }
        } else if let akError = error as? NSError {
            // Handle Apple ID authentication errors
            switch akError.code {
            case -7026:
                let detailedError = AuthenticationError.appleIdAuthenticationFailed
                appleSignInContinuation?.resume(returning: .failure(detailedError))
            case -1000:
                let detailedError = AuthenticationError.appleSignInConfigurationError
                appleSignInContinuation?.resume(returning: .failure(detailedError))
            default:
                appleSignInContinuation?.resume(returning: .failure(error))
            }
        } else {
            appleSignInContinuation?.resume(returning: .failure(error))
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AuthenticationService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first { $0.isKeyWindow }!
    }
}

// MARK: - Authentication Errors
enum AuthenticationError: LocalizedError {
    case noPresentingViewController
    case missingUserInfo
    case invalidCredential
    case networkError
    case appleSignInFailed(String)
    case invalidAppleResponse
    case appleSignInNotHandled
    case appleSignInUnknown
    case appleIdAuthenticationFailed
    case appleSignInConfigurationError
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
        case .appleSignInFailed(let message):
            return "Apple Sign In failed: \(message)"
        case .invalidAppleResponse:
            return "Invalid response from Apple Sign In"
        case .appleSignInNotHandled:
            return "Apple Sign In request was not handled"
        case .appleSignInUnknown:
            return "Unknown Apple Sign In error"
        case .appleIdAuthenticationFailed:
            return "Apple ID authentication failed. Please check your Apple ID settings and try again."
        case .appleSignInConfigurationError:
            return "Apple Sign In configuration error. Please ensure the app is properly configured for Apple Sign In."
        case .googleConfigurationError:
            return "Google Sign In configuration error. Please ensure GoogleService-Info.plist is properly configured."
        case .missingGoogleToken:
            return "Google authentication token is missing"
        case .backendError(let message):
            return message
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .appleIdAuthenticationFailed:
            return "Make sure you're signed in to iCloud with a valid Apple ID and that Sign In with Apple is enabled for this app."
        case .appleSignInConfigurationError:
            return "The app needs to be properly configured for Apple Sign In. Please contact support if this issue persists."
        case .googleConfigurationError:
            return "Please ensure GoogleService-Info.plist is properly configured in your app bundle."
        case .networkError:
            return "Please check your internet connection and try again."
        case .backendError:
            return "Please try again or contact support if the issue persists."
        default:
            return "Please try again or contact support if the issue persists."
        }
    }
}

