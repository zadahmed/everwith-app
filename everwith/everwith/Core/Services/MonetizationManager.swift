//
//  MonetizationManager.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import SwiftUI
import UIKit
import Foundation
import Combine

// MARK: - Monetization Manager
@MainActor
class MonetizationManager: ObservableObject {
    static let shared = MonetizationManager()
    
    @Published var showPaywall = false
    @Published var currentPaywallTrigger: PaywallTrigger = .general
    @Published var pendingResultImage: UIImage?
    @Published var isProcessing = false
    @Published var creditCosts: CreditCosts?
    @Published var userCredits: Int = 0
    
    // MARK: - Testing Override
    #if DEBUG
    // Set to true to override credits to 0 for testing in simulator
    var overrideTestingCredits: Bool = true
    var testingCredits: Int = 1000000 // Set this value for testing (0 = no credits)
    #endif
    
    let revenueCatService = RevenueCatService.shared
    private let apiService = SubscriptionAPIService.shared
    private let subscriptionService = SubscriptionService.shared
    
    private init() {
        #if DEBUG
        // Set initial credits for testing
        if overrideTestingCredits {
            userCredits = testingCredits
            print("🧪 TESTING MODE: Credits set to \(testingCredits)")
        }
        #endif
        
        Task {
            await fetchCreditCosts()
        }
    }
    
    // MARK: - Credit Cost Management
    
    func fetchCreditCosts() async {
        do {
            let costs = try await subscriptionService.fetchCreditCosts()
            creditCosts = costs
        } catch {
            print("❌ Failed to fetch credit costs: \(error)")
        }
    }
    
    func getCreditCost(for mode: ProcessingMode) -> Int {
        guard let costs = creditCosts else {
            // Return defaults if not fetched yet
            switch mode {
            case .restore: return 1
            case .merge: return 2
            }
        }
        
        switch mode {
        case .restore:
            return costs.photoRestoreCost
        case .merge:
            return costs.memoryMergeCost
        }
    }
    
    func checkAccess(for mode: ProcessingMode) async -> Bool {
        #if DEBUG
        if overrideTestingCredits {
            userCredits = testingCredits
            // Return false to trigger paywall (testing scenario with 0 credits)
            return testingCredits > 0
        }
        #endif
        
        do {
            let response = try await apiService.checkAccess(mode: mode.rawValue)
            userCredits = response.remainingCredits
            return response.hasAccess
        } catch {
            print("❌ Failed to check access: \(error)")
            return false
        }
    }
    
    func requestAccess(for mode: ProcessingMode) async -> Bool {
        do {
            let response = try await apiService.useCredit(mode: mode.rawValue)
            userCredits = response.remainingCredits
            return response.success
        } catch {
            print("❌ Failed to use credit: \(error)")
            return false
        }
    }
    
    // MARK: - Emotional Upgrade Triggers
    
    /// Trigger paywall after user sees the result (most effective)
    func triggerPostResultUpsell(resultImage: UIImage) {
        currentPaywallTrigger = .postResult(resultImage: resultImage)
        pendingResultImage = resultImage
        showPaywall = true
    }
    
    /// Trigger paywall before save (quality choice)
    func triggerBeforeSaveUpsell(resultImage: UIImage) {
        currentPaywallTrigger = .beforeSave(resultImage: resultImage)
        pendingResultImage = resultImage
        showPaywall = true
    }
    
    /// Trigger paywall for queue priority
    func triggerQueuePriorityUpsell() {
        currentPaywallTrigger = .queuePriority
        showPaywall = true
    }
    
    /// Trigger paywall for cinematic filters
    func triggerCinematicFilterUpsell() {
        currentPaywallTrigger = .cinematicFilter
        showPaywall = true
    }
    
    /// Trigger paywall when credits are needed
    func triggerCreditNeededUpsell() {
        currentPaywallTrigger = .creditNeeded
        showPaywall = true
    }
    
    // MARK: - Processing Flow with Monetization
    
    func processImageWithMonetization(
        image: UIImage,
        mode: ProcessingMode,
        onResult: @escaping (UIImage?) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        Task {
            isProcessing = true
            
            // Check access first
            let hasAccess = await checkAccess(for: mode)
            
            if !hasAccess {
                // Show appropriate paywall trigger
                switch mode {
                case .restore, .merge:
                    triggerCreditNeededUpsell()
                }
                isProcessing = false
                return
            }
            
            // Use the actual image processing service
            do {
                let processedImage = try await processImageWithService(image, mode: mode)
                
                // Use the credit/access
                let accessUsed = await requestAccess(for: mode)
                
                if accessUsed {
                    // Trigger post-result upsell for free users
                    if revenueCatService.subscriptionStatus.tier == .free {
                        triggerPostResultUpsell(resultImage: processedImage)
                    }
                    
                    onResult(processedImage)
                } else {
                    onError(MonetizationError.accessDenied)
                }
            } catch {
                onError(error)
            }
            
            isProcessing = false
        }
    }
    
    // MARK: - Save Flow with Quality Choice
    
    func saveImageWithQualityChoice(
        image: UIImage,
        onSave: @escaping (UIImage, Bool) -> Void // image, isHD
    ) {
        // For free users, show quality choice
        if revenueCatService.subscriptionStatus.tier == .free {
            triggerBeforeSaveUpsell(resultImage: image)
            
            // Store the save callback for later use
            saveCallback = onSave
        } else {
            // Premium users save in HD by default
            onSave(image, true)
        }
    }
    
    private var saveCallback: ((UIImage, Bool) -> Void)?
    
    func completeSaveWithQuality(isHD: Bool) {
        guard let image = pendingResultImage,
              let callback = saveCallback else { return }
        
        if isHD {
            // User chose HD - trigger paywall
            triggerBeforeSaveUpsell(resultImage: image)
        } else {
            // User chose free version - add watermark
            let watermarkedImage = addWatermark(to: image)
            callback(watermarkedImage, false)
        }
        
        saveCallback = nil
        pendingResultImage = nil
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserId() -> String? {
        return UserDefaults.standard.string(forKey: "user_id")
    }
    
    private func processImageWithService(_ image: UIImage, mode: ProcessingMode) async throws -> UIImage {
        // Use the actual ImageProcessingService
        let imageProcessingService = ImageProcessingService.shared
        
        switch mode {
        case .restore:
            let (result, _) = try await imageProcessingService.restorePhoto(
                image: image,
                qualityTarget: .premium,
                outputFormat: .jpg,
                aspectRatio: .original
            )
            return try await imageProcessingService.downloadProcessedImage(from: result.outputUrl)
            
        case .merge:
            // For merge, we need two images - this is a simplified version
            // In practice, you'd handle this differently in your UI flow
            throw MonetizationError.accessDenied
        }
    }
    
    private func addWatermark(to image: UIImage) -> UIImage {
        // Add watermark to free version
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { context in
            image.draw(at: .zero)
            
            // Add watermark
            let watermarkText = "Made with Everwith"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.7)
            ]
            
            let textSize = watermarkText.size(withAttributes: attributes)
            let textRect = CGRect(
                x: image.size.width - textSize.width - 20,
                y: image.size.height - textSize.height - 20,
                width: textSize.width,
                height: textSize.height
            )
            
            // Add background for watermark
            UIColor.black.withAlphaComponent(0.3).setFill()
            context.fill(textRect.insetBy(dx: -8, dy: -4))
            
            watermarkText.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    // MARK: - Viral Sharing Incentives
    
    func shareForCredits() async -> Bool {
        // Implement viral sharing logic
        // This would integrate with social media APIs to verify sharing
        // For now, just simulate
        return true
    }
}

// MARK: - Monetization Error
enum MonetizationError: Error, LocalizedError {
    case accessDenied
    case insufficientCredits
    case subscriptionExpired
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Access denied. Please upgrade to continue."
        case .insufficientCredits:
            return "Insufficient credits. Please purchase more credits."
        case .subscriptionExpired:
            return "Subscription expired. Please renew to continue."
        }
    }
}

// MARK: - Processing Mode Extension
extension ProcessingMode {
    var displayName: String {
        switch self {
        case .restore:
            return "Restore"
        case .merge:
            return "Merge"
        }
    }
}
