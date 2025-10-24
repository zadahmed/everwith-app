//
//  SubscriptionAPI.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import Foundation
import Combine

// MARK: - API Models
struct AccessCheckRequest: Codable {
    let userId: String
    let mode: String // "restore" or "merge"
}

struct AccessCheckResponse: Codable {
    let hasAccess: Bool
    let remainingCredits: Int
    let freeUsesRemaining: Int
    let subscriptionTier: String
    let message: String?
}

struct CreditUsageRequest: Codable {
    let userId: String
    let mode: String
    let transactionId: String?
}

struct CreditUsageResponse: Codable {
    let success: Bool
    let remainingCredits: Int
    let freeUsesRemaining: Int
    let message: String?
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
    
    private let baseURL = "https://your-api-domain.com/api" // Replace with your actual API URL
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Access Control
    func checkAccess(userId: String, mode: ProcessingMode) async throws -> AccessCheckResponse {
        let request = AccessCheckRequest(
            userId: userId,
            mode: mode.rawValue
        )
        
        let response: AccessCheckResponse = try await performRequest(
            endpoint: "/subscription/check-access",
            method: "POST",
            body: request
        )
        
        return response
    }
    
    func useCredit(userId: String, mode: ProcessingMode, transactionId: String? = nil) async throws -> CreditUsageResponse {
        let request = CreditUsageRequest(
            userId: userId,
            mode: mode.rawValue,
            transactionId: transactionId
        )
        
        let response: CreditUsageResponse = try await performRequest(
            endpoint: "/subscription/use-credit",
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
        
        let _: EmptyResponse = try await performRequest(
            endpoint: "/subscription/purchase-notification",
            method: "POST",
            body: request
        )
    }
    
    // MARK: - User Credits
    func getUserCredits(userId: String) async throws -> Int {
        let response: CreditsResponse = try await performRequest(
            endpoint: "/subscription/credits/\(userId)",
            method: "GET"
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
        
        // Add authentication header if needed
        if let authToken = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
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

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError
}

// MARK: - Processing Mode Extension
extension ProcessingMode {
    var rawValue: String {
        switch self {
        case .restore:
            return "restore"
        case .merge:
            return "merge"
        }
    }
}
