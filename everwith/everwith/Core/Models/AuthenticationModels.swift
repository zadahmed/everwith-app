//
//  AuthenticationModels.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import Foundation
import AuthenticationServices

// MARK: - User Model
struct User: Codable, Identifiable {
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
enum AuthenticationState {
    case loading
    case authenticated(User)
    case unauthenticated
    case error(String)
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
    let message: String
    let user: BackendUser
    let access_token: String
    let token_type: String
}

struct BackendUser: Codable {
    let id: String
    let email: String
    let name: String
    let profile_image_url: String?
    let is_google_user: Bool
    let is_active: Bool
    let created_at: Date
    let updated_at: Date
}

struct ErrorResponse: Codable {
    let detail: String
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
