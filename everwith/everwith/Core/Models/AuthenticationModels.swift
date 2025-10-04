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
        
        var displayName: String {
            switch self {
            case .apple: return "Apple"
            case .google: return "Google"
            case .guest: return "Guest"
            }
        }
        
        var iconName: String {
            switch self {
            case .apple: return "applelogo"
            case .google: return "globe"
            case .guest: return "person.circle"
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
