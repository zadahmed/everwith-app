//
//  AuthenticationModels.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import Foundation
import AuthenticationServices

// MARK: - User Model
struct User: Codable, Identifiable, Equatable {
    let id: String
    let email: String
    let name: String
    let profileImageURL: String?
    let provider: AuthProvider
    let createdAt: Date
    
    enum AuthProvider: String, Codable, CaseIterable {
        case apple = "apple"
        case google = "google"
        case guest = "guest"
        case email = "email"
        
        var displayName: String {
            switch self {
            case .apple: return "Apple"
            case .google: return "Google"
            case .guest: return "Guest"
            case .email: return "Email"
            }
        }
        
        var iconName: String {
            switch self {
            case .apple: return "applelogo"
            case .google: return "globe"
            case .guest: return "person.circle"
            case .email: return "envelope"
            }
        }
    }
}

// MARK: - Authentication State
enum AuthenticationState: Equatable {
    case loading
    case authenticated(User)
    case unauthenticated
    case error(String)
    
    static func == (lhs: AuthenticationState, rhs: AuthenticationState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.authenticated(let user1), .authenticated(let user2)):
            return user1.id == user2.id
        case (.unauthenticated, .unauthenticated):
            return true
        case (.error(let msg1), .error(let msg2)):
            return msg1 == msg2
        default:
            return false
        }
    }
}

// MARK: - Sign In Result
enum SignInResult {
    case success(User)
    case failure(Error)
    case cancelled
}

// MARK: - Backend Request Models
struct AuthRequest: Codable {
    let email: String
    let password: String
    let name: String
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct GoogleAuthRequest: Codable {
    let id_token: String
}

// MARK: - Backend Response Models
struct AuthResponse: Codable {
    let message: String?
    let user: BackendUser
    let accessToken: String
    let tokenType: String?
}

struct BackendUser: Codable {
    let id: String
    let email: String
    let name: String
    let profileImageUrl: String?
    let isGoogleUser: Bool?
    let isActive: Bool?
    let createdAt: Date?
    let updatedAt: Date?
}

struct ErrorResponse: Codable {
    let detail: String
}

struct UserResponse: Codable {
    let id: String
    let email: String
    let name: String
    let profile_image_url: String?
    let is_google_user: Bool
    let is_active: Bool
    let created_at: Date
    let updated_at: Date
}

// MARK: - Apple Sign In Credential
struct AppleSignInCredential {
    let userID: String
    let email: String?
    let fullName: PersonNameComponents?
    let identityToken: String?
    let authorizationCode: String?
}

// MARK: - Google Sign In Credential
struct GoogleSignInCredential {
    let userID: String
    let email: String
    let fullName: String
    let profileImageURL: String?
    let idToken: String?
}
