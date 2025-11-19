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
    var overrideTestingCredits: Bool = false // Disabled to use real API credits
    var testingCredits: Int = 0 // Set this value for testing (0 = no credits)
    #endif
    
    let revenueCatService = RevenueCatService.shared
    private let apiService = SubscriptionAPIService.shared
    private let subscriptionService = SubscriptionService.shared
    
    private init() {
        Task {
            await fetchCreditCosts()
            await fetchRealCredits()
        }
    }
    
    // MARK: - Fetch Real Credits from API
    
    func fetchRealCredits() async {
        #if DEBUG
        // Skip real credits fetch if testing override is enabled
        if overrideTestingCredits {
            userCredits = testingCredits
            print("🧪 TESTING MODE: Credits set to \(testingCredits)")
            return
        }
        #endif
        
        do {
            let credits = try await subscriptionService.fetchUserCredits()
            await MainActor.run {
                userCredits = credits.creditsRemaining
                print("✅ Fetched real credits from API: \(userCredits)")
            }
        } catch {
            print("❌ Failed to fetch credits: \(error)")
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
        
        // First, check local credits optimistically
        let creditCost = getCreditCost(for: mode)
        let localCredits = userCredits
        
        print("🔍 CHECK ACCESS: Mode=\(mode.rawValue), CreditCost=\(creditCost), LocalCredits=\(localCredits)")
        
        // Always try to get latest credits from API
        do {
            let response = try await apiService.checkAccess(mode: mode.rawValue)
            await MainActor.run {
                userCredits = response.remainingCredits
            }
            
            print("📡 API RESPONSE: hasAccess=\(response.hasAccess), remainingCredits=\(response.remainingCredits), message=\(response.message ?? "nil")")
            
            // Use API response if available
            if response.hasAccess {
                print("✅ Access granted by API")
                return true
            }
            
            // If API says no access, check if we have enough credits locally
            // (in case API is wrong or credits were just added)
            let hasEnoughCredits = userCredits >= creditCost
            print("⚠️ API says no access, but checking local credits: \(userCredits) >= \(creditCost) = \(hasEnoughCredits)")
            
            if hasEnoughCredits {
                print("✅ Local credits sufficient, granting access")
                return true
            } else {
                print("❌ Insufficient credits: need \(creditCost), have \(userCredits)")
                return false
            }
        } catch {
            print("❌ Failed to check access via API, using local credits: \(error)")
            // If API fails, fall back to local credits check
            let hasEnoughCredits = localCredits >= creditCost
            print("🔄 Fallback check: \(localCredits) >= \(creditCost) = \(hasEnoughCredits)")
            return hasEnoughCredits
        }
    }
    
    func requestAccess(for mode: ProcessingMode) async -> (Bool, String?) {
        do {
            let response = try await apiService.useCredit(mode: mode.rawValue)
            await MainActor.run {
                userCredits = response.remainingCredits
            }
            
            if !response.success {
                let errorMsg = response.message ?? "Failed to use credit"
                print("⚠️ Credit usage returned success=false: \(errorMsg)")
                return (false, errorMsg)
            }
            
            print("✅ Credit used successfully. Remaining credits: \(response.remainingCredits)")
            return (true, nil)
        } catch {
            print("❌ Failed to use credit: \(error)")
            
            var errorMessage: String? = nil
            
            // Provide more detailed error information
            if let apiError = error as? APIError {
                let msg = apiError.localizedDescription ?? "Unknown API error"
                print("   API Error: \(msg)")
                errorMessage = msg
            } else if let urlError = error as? URLError {
                print("   URL Error: \(urlError.localizedDescription)")
                errorMessage = "Network error: \(urlError.localizedDescription)"
            } else if let decodingError = error as? DecodingError {
                print("   Decoding Error: \(decodingError)")
                errorMessage = "Failed to process server response"
            } else {
                print("   Error: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
            
            return (false, errorMessage)
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
                
                // Use the credit/access AFTER processing completes
                let (accessUsed, errorMessage) = await requestAccess(for: mode)
                
                if accessUsed {
                    // Don't automatically trigger paywall - user can upgrade via button if they want
                    onResult(processedImage)
                } else {
                    // Credit usage failed - check if it's a credit issue
                    let errorMsg = errorMessage ?? "Failed to process payment. Please check your credits and try again."
                    
                    // Only show error if it's specifically about credits/insufficient funds
                    if errorMsg.lowercased().contains("credit") || 
                       errorMsg.lowercased().contains("insufficient") ||
                       errorMsg.lowercased().contains("payment required") {
                        // This is a credit issue - show paywall instead of error
                        triggerCreditNeededUpsell()
                    } else {
                        // Other backend error - show error message
                        onError(MonetizationError.backendError(errorMsg))
                    }
                }
            } catch let error as MonetizationError {
                // Handle monetization-specific errors
                switch error {
                case .accessDenied, .insufficientCredits:
                    // These are credit-related - show paywall, not error
                    triggerCreditNeededUpsell()
                case .subscriptionExpired:
                    // Subscription expired - show paywall
                    triggerCreditNeededUpsell()
                case .backendError(let msg):
                    // Check if it's a credit-related backend error
                    if msg.lowercased().contains("credit") || 
                       msg.lowercased().contains("insufficient") ||
                       msg.lowercased().contains("payment required") {
                        triggerCreditNeededUpsell()
                    } else {
                        onError(error)
                    }
                }
            } catch {
                // Other errors (network, processing, etc.) - show error
                onError(error)
            }
            
            isProcessing = false
        }
    }
    
    // MARK: - Centralized Export Functions
    
    /// Export and save image (applies watermark for free users)
    func exportImageToPhotos(image: UIImage, completion: ((Bool) -> Void)? = nil) {
        // Apply watermark if needed
        let imageToSave = applyWatermarkIfNeeded(to: image)
        
        UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil)
        
        // Provide haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        completion?(true)
    }
    
    /// Export and share image (applies watermark for free users)
    func exportImageToShare(image: UIImage) -> Any {
        // Apply watermark if needed
        return applyWatermarkIfNeeded(to: image)
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
        // Add professional watermark to the image
        let scale: CGFloat = image.scale
        let size = image.size
        let renderer = UIGraphicsImageRenderer(size: size, format: UIGraphicsImageRendererFormat.default())
        
        return renderer.image { context in
            // Draw the original image
            image.draw(in: CGRect(origin: .zero, size: size))
            
            // Watermark configuration
            let watermarkText = "Made with Everwith"
            
            // Calculate watermark size based on image size (responsive, but bigger now)
            let baseFontSize = max(28, min(size.width * 0.035, 32))
            let font = UIFont.systemFont(ofSize: baseFontSize, weight: .bold)
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white.withAlphaComponent(0.95)
            ]
            
            let textSize = watermarkText.size(withAttributes: attributes)
            
            // Icon size (slightly smaller than text height for balance)
            let iconSize = textSize.height * 0.85
            
            // Position in bottom right corner with more padding
            let padding: CGFloat = max(30, size.width * 0.035)
            let iconSpacing: CGFloat = max(10, size.width * 0.015)
            
            // Calculate total watermark width (icon + spacing + text)
            let totalWidth = iconSize + iconSpacing + textSize.width
            let totalHeight = max(iconSize, textSize.height)
            
            // Background rectangle for the entire watermark
            let backgroundPadding: CGFloat = padding * 0.8
            let backgroundRect = CGRect(
                x: size.width - totalWidth - backgroundPadding * 2,
                y: size.height - totalHeight - backgroundPadding * 2,
                width: totalWidth + backgroundPadding * 2,
                height: totalHeight + backgroundPadding * 2
            )
            
            let cornerRadius = backgroundRect.height / 2
            
            // Shadow
            context.cgContext.setShadow(
                offset: CGSize(width: 0, height: 4),
                blur: 12,
                color: UIColor.black.withAlphaComponent(0.4).cgColor
            )
            
            // Background pill with gradient effect
            let path = UIBezierPath(
                roundedRect: backgroundRect,
                cornerRadius: cornerRadius
            )
            
            // Semi-transparent dark background with gradient
            let colors = [
                UIColor.black.withAlphaComponent(0.75),
                UIColor.black.withAlphaComponent(0.65)
            ]
            
            context.cgContext.addPath(path.cgPath)
            context.cgContext.clip()
            
            // Draw gradient background
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors.map { $0.cgColor } as CFArray,
                locations: [0.0, 1.0]
            )
            
            context.cgContext.drawLinearGradient(
                gradient!,
                start: CGPoint(x: backgroundRect.minX, y: backgroundRect.minY),
                end: CGPoint(x: backgroundRect.maxX, y: backgroundRect.maxY),
                options: []
            )
            
            // Reset shadow for icon and text
            context.cgContext.setShadow(
                offset: CGSize.zero,
                blur: 0,
                color: nil
            )
            
            // Draw app icon
            if let iconImage = UIImage(named: "AppLogo") {
                let iconRect = CGRect(
                    x: backgroundRect.minX + backgroundPadding,
                    y: backgroundRect.minY + (backgroundRect.height - iconSize) / 2,
                    width: iconSize,
                    height: iconSize
                )
                iconImage.draw(in: iconRect)
            }
            
            // Draw the text
            let textRect = CGRect(
                x: backgroundRect.minX + backgroundPadding + iconSize + iconSpacing,
                y: backgroundRect.minY + (backgroundRect.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            watermarkText.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    // Apply watermark for free users on ALL saved images
    func applyWatermarkIfNeeded(to image: UIImage) -> UIImage {
        // Always add watermark for free users
        if revenueCatService.subscriptionStatus.tier == .free {
            return addWatermark(to: image)
        }
        return image
    }
    
    // MARK: - Viral Sharing Incentives
    
    func shareReadyImage(from image: UIImage) -> UIImage {
        // Always enforce brand watermark for viral shares
        return addWatermark(to: image)
    }
    
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
    case backendError(String)
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Access denied. Please upgrade to continue."
        case .insufficientCredits:
            return "Insufficient credits. Please purchase more credits."
        case .subscriptionExpired:
            return "Subscription expired. Please renew to continue."
        case .backendError(let message):
            return message
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
