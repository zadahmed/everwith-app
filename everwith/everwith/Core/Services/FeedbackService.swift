//
//  FeedbackService.swift
//  EverWith
//
//  Handles user feedback, support, and analytics
//

import Foundation
import UIKit
import Combine

// MARK: - Feedback Models
struct FeedbackSubmission: Codable {
    let feedbackType: String
    let subject: String
    let message: String
    let deviceInfo: [String: String]?
    let appVersion: String
    
    enum CodingKeys: String, CodingKey {
        case subject, message
        case feedbackType = "feedback_type"
        case deviceInfo = "device_info"
        case appVersion = "app_version"
    }
}

struct FeedbackResponse: Codable {
    let id: String
    let feedbackType: String
    let subject: String
    let message: String
    let status: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, subject, message, status
        case feedbackType = "feedback_type"
        case createdAt = "created_at"
    }
}

struct UserStats: Codable {
    let totalImagesProcessed: Int
    let totalRestores: Int
    let totalMerges: Int
    let totalShares: Int
    let creditsEarnedFromShares: Int
    let favoriteFilter: String?
    let memberSince: Date
    
    enum CodingKeys: String, CodingKey {
        case favoriteFilter
        case totalImagesProcessed = "total_images_processed"
        case totalRestores = "total_restores"
        case totalMerges = "total_merges"
        case totalShares = "total_shares"
        case creditsEarnedFromShares = "credits_earned_from_shares"
        case memberSince = "member_since"
    }
}

struct FAQItem: Codable {
    let question: String
    let answer: String
    let category: String
}

// MARK: - Feedback Service
@MainActor
class FeedbackService: ObservableObject {
    static let shared = FeedbackService()
    
    @Published var userStats: UserStats?
    @Published var faqItems: [FAQItem] = []
    @Published var isLoading = false
    
    private let networkService = NetworkService.shared
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    private init() {}
    
    // MARK: - Feedback Submission
    
    func submitFeedback(
        type: FeedbackType,
        subject: String,
        message: String
    ) async throws -> String {
        isLoading = true
        defer { isLoading = false }
        
        let deviceInfo = getDeviceInfo()
        let appVersion = getAppVersion()
        
        let submission = FeedbackSubmission(
            feedbackType: type.rawValue,
            subject: subject,
            message: message,
            deviceInfo: deviceInfo,
            appVersion: appVersion
        )
        
        guard let url = URL(string: "\(AppConfiguration.API.baseURL)/api/feedback/submit") else {
            throw FeedbackError.invalidURL
        }
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let bodyData = try encoder.encode(submission)
        
        let response: FeedbackResponse = try await networkService.makeAuthenticatedRequest(
            url: url,
            method: .POST,
            body: bodyData,
            responseType: FeedbackResponse.self
        )
        
        return response.id
    }
    
    func getMyFeedback() async throws -> [FeedbackResponse] {
        guard let url = URL(string: "\(AppConfiguration.API.baseURL)/api/feedback/my-feedback") else {
            throw FeedbackError.invalidURL
        }
        
        let feedback: [FeedbackResponse] = try await networkService.makeAuthenticatedRequest(
            url: url,
            method: .GET,
            responseType: [FeedbackResponse].self
        )
        
        return feedback
    }
    
    // MARK: - Share Tracking & Rewards
    
    func trackShareAndReward(
        shareType: ShareType,
        platform: String?,
        imageId: String?
    ) async throws -> ShareRewardResponse {
        isLoading = true
        defer { isLoading = false }
        
        guard let url = URL(string: "\(AppConfiguration.API.baseURL)/api/feedback/share-reward") else {
            throw FeedbackError.invalidURL
        }
        
        var bodyData: [String: Any] = [
            "share_type": shareType.rawValue
        ]
        
        if let platform = platform {
            bodyData["platform"] = platform
        }
        
        if let imageId = imageId {
            bodyData["image_id"] = imageId
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: bodyData)
        
        let response: ShareRewardResponse = try await networkService.makeAuthenticatedRequest(
            url: url,
            method: .POST,
            body: jsonData,
            responseType: ShareRewardResponse.self
        )
        
        return response
    }
    
    // MARK: - User Stats
    
    func fetchUserStats() async throws -> UserStats {
        isLoading = true
        defer { isLoading = false }
        
        guard let url = URL(string: "\(AppConfiguration.API.baseURL)/api/feedback/stats") else {
            throw FeedbackError.invalidURL
        }
        
        let stats: UserStats = try await networkService.makeAuthenticatedRequest(
            url: url,
            method: .GET,
            responseType: UserStats.self
        )
        
        userStats = stats
        return stats
    }
    
    func trackAppRating(rating: Int) async throws {
        guard let url = URL(string: "\(AppConfiguration.API.baseURL)/api/feedback/rate-app") else {
            throw FeedbackError.invalidURL
        }
        
        let bodyData = try JSONSerialization.data(withJSONObject: ["rating": rating])
        
        _ = try await networkService.makeAuthenticatedRequest(
            url: url,
            method: .POST,
            body: bodyData,
            responseType: [String: String].self
        )
    }
    
    // MARK: - FAQ
    
    func fetchFAQ() async throws -> [FAQItem] {
        guard let url = URL(string: "\(AppConfiguration.API.baseURL)/api/feedback/faq") else {
            throw FeedbackError.invalidURL
        }
        
        let items: [FAQItem] = try await networkService.makeAuthenticatedRequest(
            url: url,
            method: .GET,
            responseType: [FAQItem].self
        )
        
        faqItems = items
        return items
    }
    
    // MARK: - Helper Methods
    
    private func getDeviceInfo() -> [String: String] {
        let device = UIDevice.current
        
        return [
            "model": device.model,
            "system_name": device.systemName,
            "system_version": device.systemVersion,
            "device_name": device.name,
            "identifier": device.identifierForVendor?.uuidString ?? "unknown"
        ]
    }
    
    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    func openEmailSupport(subject: String = "Support Request", body: String = "") {
        let email = "hello@codeai.studio"
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "mailto:\(email)?subject=\(subjectEncoded)&body=\(bodyEncoded)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
}

// MARK: - Supporting Types

enum FeedbackType: String {
    case general = "general"
    case bug = "bug"
    case feature = "feature"
    case help = "help"
}

enum ShareType: String {
    case social = "social"
    case direct = "direct"
    case link = "link"
}

struct ShareRewardResponse: Codable {
    let message: String
    let creditsEarned: Int
    let limitReached: Bool
    let totalCreditsFromShares: Int
    
    enum CodingKeys: String, CodingKey {
        case message
        case creditsEarned = "credits_earned"
        case limitReached = "limit_reached"
        case totalCreditsFromShares = "total_credits_from_shares"
    }
}

enum FeedbackError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
}

