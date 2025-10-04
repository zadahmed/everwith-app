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

class AuthenticationService: NSObject, ObservableObject {
    @Published var authenticationState: AuthenticationState = .loading
    @Published var currentUser: User?
    
    private let userDefaults = UserDefaults.standard
    private let userKey = "current_user"
    
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
        // Simulate Google Sign In for demo purposes
        // In production, integrate with Google Sign In SDK
        
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds delay
        
        let googleUser = User(
            id: UUID().uuidString,
            email: "user@gmail.com",
            name: "Google User",
            profileImageURL: nil,
            provider: .google,
            createdAt: Date()
        )
        
        await signInUser(googleUser)
        return .success(googleUser)
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
            // In production: GIDSignIn.sharedInstance.signOut()
            print("Signing out Google user")
        }
        
        // Clear stored user data
        userDefaults.removeObject(forKey: userKey)
        
        // Update state
        DispatchQueue.main.async {
            self.currentUser = nil
            self.authenticationState = .unauthenticated
        }
    }
    
    // MARK: - Private Methods
    private func signInUser(_ user: User) async {
        await MainActor.run {
            currentUser = user
            authenticationState = .authenticated(user)
        }
        storeUser(user)
    }
    
    private func storeUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            userDefaults.set(encoded, forKey: userKey)
        }
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
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .appleIdAuthenticationFailed:
            return "Make sure you're signed in to iCloud with a valid Apple ID and that Sign In with Apple is enabled for this app."
        case .appleSignInConfigurationError:
            return "The app needs to be properly configured for Apple Sign In. Please contact support if this issue persists."
        case .networkError:
            return "Please check your internet connection and try again."
        default:
            return "Please try again or contact support if the issue persists."
        }
    }
}

