//
//  SubscriptionService.swift
//  EverWith
//
//  Handles subscription and credit management
//

import Foundation
import StoreKit
import Combine

// MARK: - Subscription Models
struct SubscriptionStatus: Codable {
    let id: String
    let userId: String
    let tier: String
    let status: String
    let startDate: Date
    let endDate: Date?
    let isActive: Bool
    let trialEndDate: Date?
    let autoRenew: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, status, tier
        case userId = "user_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case isActive = "is_active"
        case trialEndDate = "trial_end_date"
        case autoRenew = "auto_renew"
    }
}

struct UserCredits: Codable {
    let creditsRemaining: Int
    let totalPurchased: Int
    let totalUsed: Int
    let lastPurchaseDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case creditsRemaining = "credits_remaining"
        case totalPurchased = "total_purchased"
        case totalUsed = "total_used"
        case lastPurchaseDate = "last_purchase_date"
    }
}

struct PricingInfo: Codable {
    let subscriptions: [String: SubscriptionTier]
    let credits: CreditPricing
    
    struct SubscriptionTier: Codable {
        let price: Double
        let currency: String
        let trialDays: Int?
        let savings: String?
        let pricePerMonth: Double?
        let features: [String]
        
        enum CodingKeys: String, CodingKey {
            case price, currency, savings, features
            case trialDays = "trial_days"
            case pricePerMonth = "price_per_month"
        }
    }
    
    struct CreditPricing: Codable {
        let packages: [CreditPackage]
        let note: String
        
        struct CreditPackage: Codable {
            let credits: Int
            let price: Double
            let currency: String
            let badge: String?
        }
    }
}

struct CreditCosts: Codable {
    let message: String
    let serviceCosts: [String: Int]
    let descriptions: [String: String]
    let initialSignupCredits: Int
    let premiumUnlimited: Bool
    
    enum CodingKeys: String, CodingKey {
        case message
        case serviceCosts = "service_costs"
        case descriptions = "description"
        case initialSignupCredits = "initial_signup_credits"
        case premiumUnlimited = "premium_unlimited"
    }
    
    var photoRestoreCost: Int { serviceCosts["photo_restore"] ?? 1 }
    var memoryMergeCost: Int { serviceCosts["memory_merge"] ?? 2 }
    var cinematicFilterCost: Int { serviceCosts["cinematic_filter"] ?? 3 }
}

// MARK: - Response Models
struct SubscriptionResponse: Codable {
    let message: String
    let subscriptionId: String
    let tier: String
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case message
        case subscriptionId = "subscription_id"
        case tier, status
    }
}

struct CreditPurchaseResponse: Codable {
    let message: String
    let creditsAdded: Int
    let newBalance: Int
    
    enum CodingKeys: String, CodingKey {
        case message
        case creditsAdded = "credits_added"
        case newBalance = "new_balance"
    }
}

struct CreditUseResponse: Codable {
    let subscriptionActive: Bool
    let creditsRemaining: Int?
    
    enum CodingKeys: String, CodingKey {
        case subscriptionActive = "subscription_active"
        case creditsRemaining = "credits_remaining"
    }
}

struct RestoreResponse: Codable {
    let message: String
    let restoredItems: [String]
    
    enum CodingKeys: String, CodingKey {
        case message
        case restoredItems = "restored_items"
    }
}

// MARK: - Subscription Service
@MainActor
class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()
    
    @Published var currentSubscription: SubscriptionStatus?
    @Published var userCredits: UserCredits?
    @Published var pricing: PricingInfo?
    @Published var creditCosts: CreditCosts?
    @Published var isLoading = false
    
    private let networkService = NetworkService.shared
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try multiple date formats
            let formatters = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",  // 2025-10-11T23:19:17.783000
                "yyyy-MM-dd'T'HH:mm:ss.SSS",      // 2025-10-11T23:19:17.783
                "yyyy-MM-dd'T'HH:mm:ss",          // 2025-10-11T23:19:17
                "yyyy-MM-dd'T'HH:mm:ssZ",         // 2025-10-11T23:19:17Z
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ"      // 2025-10-11T23:19:17.783Z
            ]
            
            for formatter in formatters {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = formatter
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
            }
            
            // Fallback to ISO8601
            let iso8601Formatter = ISO8601DateFormatter()
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
        }
        return decoder
    }()
    
    private init() {}
    
    // MARK: - Subscription Management
    
    func fetchSubscriptionStatus() async throws -> SubscriptionStatus {
        isLoading = true
        defer { isLoading = false }
        
        guard let url = URL(string: "\(AppConfiguration.API.baseURL)/api/subscriptions/status") else {
            throw SubscriptionError.invalidURL
        }
        
        let subscription: SubscriptionStatus = try await networkService.makeAuthenticatedRequest(
            url: url,
            method: .GET,
            responseType: SubscriptionStatus.self
        )
        
        currentSubscription = subscription
        return subscription
    }
    
    func subscribe(tier: String, transactionId: String, receiptData: String) async throws -> SubscriptionResponse {
        isLoading = true
        defer { isLoading = false }
        
        guard let url = URL(string: "\(AppConfiguration.API.baseURL)/api/subscriptions/subscribe") else {
            throw SubscriptionError.invalidURL
        }
        
        let body: [String: Any] = [
            "tier": tier,
            "transaction_id": transactionId,
            "receipt_data": receiptData
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        
        let response: SubscriptionResponse = try await networkService.makeAuthenticatedRequest(
            url: url,
            method: .POST,
            body: bodyData,
            responseType: SubscriptionResponse.self
        )
        
        // Refresh subscription status
        _ = try await fetchSubscriptionStatus()
        
        return response
    }
    
    func cancelSubscription() async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let url = URL(string: "\(AppConfiguration.API.baseURL)/api/subscriptions/cancel") else {
            throw SubscriptionError.invalidURL
        }
        
        _ = try await networkService.makeAuthenticatedRequest(
            url: url,
            method: .POST,
            responseType: [String: String].self
        )
        
        // Refresh subscription status
        _ = try await fetchSubscriptionStatus()
    }
    
    func restorePurchases(receiptData: String) async throws -> RestoreResponse {
        isLoading = true
        defer { isLoading = false }
        
        guard let url = URL(string: "\(AppConfiguration.API.baseURL)/api/subscriptions/restore") else {
            throw SubscriptionError.invalidURL
        }
        
        let bodyData = try JSONSerialization.data(withJSONObject: ["receipt_data": receiptData])
        
        let response: RestoreResponse = try await networkService.makeAuthenticatedRequest(
            url: url,
            method: .POST,
            body: bodyData,
            responseType: RestoreResponse.self
        )
        
        // Refresh both subscription and credits
        async let subscription = fetchSubscriptionStatus()
        async let credits = fetchUserCredits()
        
        _ = try await (subscription, credits)
        
        return response
    }
    
    // MARK: - Credit Management
    
    func fetchUserCredits() async throws -> UserCredits {
        isLoading = true
        defer { isLoading = false }
        
        guard let url = URL(string: "\(AppConfiguration.API.baseURL)/api/subscriptions/credits") else {
            throw SubscriptionError.invalidURL
        }
        
        let credits: UserCredits = try await networkService.makeAuthenticatedRequest(
            url: url,
            method: .GET,
            responseType: UserCredits.self
        )
        
        userCredits = credits
        return credits
    }
    
    func purchaseCredits(credits: Int, price: Double, transactionId: String, receiptData: String) async throws -> CreditPurchaseResponse {
        isLoading = true
        defer { isLoading = false }
        
        guard let url = URL(string: "\(AppConfiguration.API.baseURL)/api/subscriptions/credits/purchase") else {
            throw SubscriptionError.invalidURL
        }
        
        let body: [String: Any] = [
            "credits": credits,
            "price": price,
            "currency": "GBP",
            "transaction_id": transactionId,
            "receipt_data": receiptData
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        
        let response: CreditPurchaseResponse = try await networkService.makeAuthenticatedRequest(
            url: url,
            method: .POST,
            body: bodyData,
            responseType: CreditPurchaseResponse.self
        )
        
        // Refresh credits
        _ = try await fetchUserCredits()
        
        return response
    }
    
    func useCredit(imageType: String) async throws -> Bool {
        guard let url = URL(string: "\(AppConfiguration.API.baseURL)/api/subscriptions/credits/use") else {
            throw SubscriptionError.invalidURL
        }
        
        let bodyData = try JSONSerialization.data(withJSONObject: ["image_type": imageType])
        
        let response: CreditUseResponse = try await networkService.makeAuthenticatedRequest(
            url: url,
            method: .POST,
            body: bodyData,
            responseType: CreditUseResponse.self
        )
        
        // Refresh credits if not using subscription
        if !response.subscriptionActive {
            _ = try await fetchUserCredits()
        }
        
        return response.subscriptionActive
    }
    
    func fetchPricing() async throws -> PricingInfo {
        guard let url = URL(string: "\(AppConfiguration.API.baseURL)/api/subscriptions/pricing") else {
            throw SubscriptionError.invalidURL
        }
        
        let pricingInfo: PricingInfo = try await networkService.makeAuthenticatedRequest(
            url: url,
            method: .GET,
            responseType: PricingInfo.self
        )
        
        pricing = pricingInfo
        return pricingInfo
    }
    
    func fetchCreditCosts() async throws -> CreditCosts {
        guard let url = URL(string: "\(AppConfiguration.API.baseURL)/api/subscriptions/credit-costs") else {
            throw SubscriptionError.invalidURL
        }
        
        let costs: CreditCosts = try await networkService.makeAuthenticatedRequest(
            url: url,
            method: .GET,
            responseType: CreditCosts.self
        )
        
        creditCosts = costs
        return costs
    }
    
    // MARK: - Helper Methods
    
    func hasActiveSubscription() -> Bool {
        return currentSubscription?.isActive ?? false
    }
    
    func hasCredits() -> Bool {
        return (userCredits?.creditsRemaining ?? 0) > 0
    }
    
    func canProcessImage() -> Bool {
        return hasActiveSubscription() || hasCredits()
    }
    
    func needsPayment() -> Bool {
        return !canProcessImage()
    }
}

// MARK: - StoreKit Integration Helper
extension SubscriptionService {
    
    func handleSuccessfulPurchase(_ transaction: Transaction, productId: String) async throws {
        // Get receipt data
        // Note: appStoreReceiptURL is deprecated in iOS 18.0, but we need to support older iOS versions
        // We'll migrate to AppTransaction.shared and Transaction.all when iOS 18 is the minimum version
        #warning("appStoreReceiptURL deprecated in iOS 18.0 - will migrate to AppTransaction.shared when minimum iOS version is 18.0")
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: receiptURL) else {
            throw NSError(domain: "SubscriptionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not load receipt"])
        }
        
        let receiptString = receiptData.base64EncodedString()
        let transactionId = String(transaction.id)
        
        // Determine tier from product ID
        let tier: String
        if productId.contains("monthly") {
            tier = "monthly"
        } else if productId.contains("yearly") {
            tier = "yearly"
        } else if productId.contains("credits") {
            // Handle credit purchase
            let credits = extractCreditsFromProductId(productId)
            let price = extractPriceFromTransaction(transaction)
            _ = try await purchaseCredits(credits: credits, price: price, transactionId: transactionId, receiptData: receiptString)
            return
        } else {
            throw NSError(domain: "SubscriptionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown product type"])
        }
        
        _ = try await subscribe(tier: tier, transactionId: transactionId, receiptData: receiptString)
    }
    
    private func extractCreditsFromProductId(_ productId: String) -> Int {
        // Extract credit count from product ID (e.g., "com.everwith.credits.5" -> 5)
        if let lastComponent = productId.components(separatedBy: ".").last,
           let credits = Int(lastComponent) {
            return credits
        }
        return 5 // Default
    }
    
    private func extractPriceFromTransaction(_ transaction: Transaction) -> Double {
        // This would come from StoreKit product info
        // For now, return a default
        return 4.99
    }
}

// MARK: - Error Types
enum SubscriptionError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case purchaseFailed(String)
    case receiptValidationFailed
}

