//
//  SubscriptionAPI.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import Foundation
import Combine

// Import HTTPMethod from NetworkService
// Note: HTTPMethod is defined as an enum in NetworkService.swift

// MARK: - API Models
struct AccessCheckRequest: Codable {
    let mode: String // "restore" or "merge"
}

struct AccessCheckResponse: Codable {
    let hasAccess: Bool
    let remainingCredits: Int
    let freeUsesRemaining: Int
    let subscriptionTier: String
    let message: String
}

struct CreditUsageRequest: Codable {
    let mode: String
}

struct CreditUsageResponse: Codable {
    let success: Bool
    let creditsUsed: Int
    let remainingCredits: Int
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case success
        case creditsUsed = "credits_used"
        case remainingCredits = "remaining_credits"
        case message
    }
}

struct PurchaseNotificationRequest: Codable {
    let userId: String
    let productId: String
    let transactionId: String
    let purchaseType: String // "subscription" or "credit_pack"
    let revenueCatData: [String: String] // Simplified to avoid AnyCodable issues
}

// MARK: - Network Service
class SubscriptionAPIService: ObservableObject {
    static let shared = SubscriptionAPIService()
    
    @Published var isLoading = false
    @Published var lastError: String? = nil
    
    private let baseURL = AppConfiguration.API.baseURL
    private let networkService = NetworkService.shared
    
    private init() {}
    
    // MARK: - Access Control
    func checkAccess(mode: String) async throws -> AccessCheckResponse {
        let request = AccessCheckRequest(
            mode: mode
        )
        
        let response: AccessCheckResponse = try await performRequest(
            endpoint: "/api/subscriptions/check-access",
            method: "POST",
            body: request
        )
        
        return response
    }
    
    func useCredit(mode: String) async throws -> CreditUsageResponse {
        let request = CreditUsageRequest(
            mode: mode
        )
        
        let response: CreditUsageResponse = try await performRequest(
            endpoint: "/api/subscriptions/use-credit",
            method: "POST",
            body: request
        )
        
        return response
    }
    
    // MARK: - Purchase Notifications
    func notifyPurchase(userId: String, productId: String, transactionId: String, purchaseType: String, revenueCatData: [String: Any]) async throws {
        let request = PurchaseNotificationRequest(
            userId: userId,
            productId: productId,
            transactionId: transactionId,
            purchaseType: purchaseType,
            revenueCatData: revenueCatData.mapValues { String(describing: $0) }
        )
        
        // Use the correct endpoint path from the backend router
        let _: EmptyResponse = try await performRequest(
            endpoint: "/api/subscriptions/purchase-notification",
            method: "POST",
            body: request
        )
        
        print("✅ Purchase notification sent to backend for user: \(userId)")
    }
    
    // MARK: - User Credits
    func getUserCredits(userId: String) async throws -> Int {
        let response: CreditsResponse = try await performRequest(
            endpoint: "/subscription/credits/\(userId)",
            method: "GET",
            body: nil as EmptyResponse?
        )
        
        return response.credits
    }
    
    // MARK: - Generic Request Method  
    private func performRequest<T: Codable, U: Codable>(
        endpoint: String,
        method: String,
        body: T? = nil
    ) async throws -> U {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication header
        if let token = UserDefaults.standard.string(forKey: "access_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Handle non-200 status codes
        guard httpResponse.statusCode == 200 else {
            // Try to decode error response
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                print("❌ API Error (\(httpResponse.statusCode)): \(errorResponse.detail)")
                throw APIError.serverError(httpResponse.statusCode, errorResponse.detail)
            } else if let errorString = String(data: data, encoding: .utf8) {
                print("❌ API Error (\(httpResponse.statusCode)): \(errorString)")
                throw APIError.serverError(httpResponse.statusCode, errorString)
            } else {
                print("❌ API Error (\(httpResponse.statusCode)): No error message")
                throw APIError.serverError(httpResponse.statusCode, "Server returned error \(httpResponse.statusCode)")
            }
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(U.self, from: data)
    }
}

// MARK: - Supporting Types
struct EmptyResponse: Codable {}

struct CreditsResponse: Codable {
    let credits: Int
}

// ErrorResponse is already defined in AuthenticationModels.swift

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int, String)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}
