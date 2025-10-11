//
//  AppConfiguration.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import Foundation

struct AppConfiguration {
    
    // MARK: - Environment
    enum Environment: String, CaseIterable {
        case development = "Development"
        case staging = "Staging"
        case production = "Production"
        
        var displayName: String {
            return rawValue
        }
    }
    
    // MARK: - Current Environment
    static var currentEnvironment: Environment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
    
    // MARK: - API Configuration
    struct API {
        static var baseURL: String {
            switch AppConfiguration.currentEnvironment {
            case .development:
                return "http://localhost:8000"
            case .staging:
                return "https://everwith-backend-421b30a963d9.herokuapp.com"
            case .production:
                return "https://everwith-backend-421b30a963d9.herokuapp.com"
            }
        }
        
        static var timeout: TimeInterval {
            return 30.0
        }
        
        static var headers: [String: String] {
            return [
                "Content-Type": "application/json",
                "Accept": "application/json"
            ]
        }
    }
    
    // MARK: - Authentication Endpoints
    struct AuthEndpoints {
        static let register = "/api/auth/register"
        static let login = "/api/auth/login"
        static let google = "/api/auth/google"
        static let logout = "/api/auth/logout"
        static let me = "/api/auth/me"
        static let refresh = "/api/auth/refresh"
    }
    
    // MARK: - API Endpoints
    struct APIEndpoints {
        static let messages = "/api/messages"
        static let events = "/api/events"
        static let users = "/api/users"
    }
    
    // MARK: - Debug Information
    static var debugInfo: String {
        return """
        App Configuration:
        - Environment: \(currentEnvironment.displayName)
        - Base URL: \(API.baseURL)
        - Timeout: \(API.timeout)s
        """
    }
}

// MARK: - URL Extensions
extension AppConfiguration {
    static func fullURL(for endpoint: String) -> String {
        return "\(API.baseURL)\(endpoint)"
    }
    
    static func authURL(for endpoint: String) -> String {
        return fullURL(for: endpoint)
    }
    
    static func apiURL(for endpoint: String) -> String {
        return fullURL(for: endpoint)
    }
}
