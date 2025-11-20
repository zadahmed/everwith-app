//
//  RevenueCatService.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import Foundation
import RevenueCat
import SwiftUI
import Combine
import StoreKit

// MARK: - Subscription Tiers
enum SubscriptionTier: String, CaseIterable {
    case free = "free"
    case premiumMonthly = "premium_monthly"
    case premiumYearly = "premium_yearly"
    
    var displayName: String {
        switch self {
        case .free:
            return "Free"
        case .premiumMonthly:
            return "Premium Monthly"
        case .premiumYearly:
            return "Premium Yearly"
        }
    }
    
    var description: String {
        switch self {
        case .free:
            return "1 free restore/merge per day"
        case .premiumMonthly:
            return "Unlimited usage + HD + instant processing"
        case .premiumYearly:
            return "Unlimited usage + HD + instant processing (50% off)"
        }
    }
}

// MARK: - Credit Pack
struct CreditPack: Identifiable {
    let id = UUID()
    let credits: Int
    let price: String
    let productId: String
    let savings: String?
    
    static let packs = [
        CreditPack(credits: 5, price: "£4.99", productId: "com.everwith.credits.5", savings: nil),
        CreditPack(credits: 15, price: "£9.99", productId: "com.everwith.credits.15", savings: "Save 33%"),
        CreditPack(credits: 50, price: "£24.99", productId: "com.everwith.credits.50", savings: "Save 50%")
    ]
}

// MARK: - User Subscription Status
struct UserSubscriptionStatus {
    let tier: SubscriptionTier
    let credits: Int
    let hasActiveSubscription: Bool
    let subscriptionExpiryDate: Date?
    let freeUsesRemaining: Int
    let lastFreeUseDate: Date?
    
    var canUseFeature: Bool {
        switch tier {
        case .free:
            return freeUsesRemaining > 0
        case .premiumMonthly, .premiumYearly:
            return true
        }
    }
    
    var needsCredits: Bool {
        return tier == .free && freeUsesRemaining == 0
    }
}

// MARK: - RevenueCat Service
@MainActor
class RevenueCatService: NSObject, ObservableObject {
    static let shared = RevenueCatService()
    
    @Published var subscriptionStatus: UserSubscriptionStatus = UserSubscriptionStatus(
        tier: .free,
        credits: 0,
        hasActiveSubscription: false,
        subscriptionExpiryDate: nil,
        freeUsesRemaining: 1,
        lastFreeUseDate: nil
    )
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentOfferings: Offerings?
    @Published var availablePackages: [Package] = []
    
    private override init() {
        super.init()
        // RevenueCat is configured in RevenueCatConfig.shared.configure()
        // Just set up user login if needed
        setupUserLogin()
    }
    
    // MARK: - Configuration
    private func setupUserLogin() {
        // Set up user ID if available
        if let userId = UserDefaults.standard.string(forKey: "user_id") {
            Purchases.shared.logIn(userId) { customerInfo, created, error in
                if let error = error {
                    print("RevenueCat login error: \(error)")
                } else {
                    print("RevenueCat login successful")
                    Task {
                        await self.updateSubscriptionStatus()
                        await self.loadOfferings()
                    }
                }
            }
        }
    }
    
    // MARK: - Load Offerings
    // Following RevenueCat sample pattern for fetching offerings
    // Reference: https://github.com/RevenueCat/purchases-ios/blob/main/Examples/MagicWeather/MagicWeather/Sources/Controllers/WeatherViewController.swift#L38
    func loadOfferings() async {
        // Ensure user is identified first
        await ensureUserIdentified()
        
        do {
            print("🔄 Loading offerings from RevenueCat...")
            let offerings = try await Purchases.shared.offerings()
            currentOfferings = offerings
            
            print("📦 RevenueCat offerings loaded:")
            print("   - Total offerings: \(offerings.all.count)")
            print("   - Current offering: \(offerings.current?.identifier ?? "none")")
            print("   - All offering keys: \(Array(offerings.all.keys))")
            
            // Try to get offering by placement first (following sample pattern)
            // Then fallback to current offering, then specific offering ID
            var selectedOffering: Offering?
            
            // Try placement-based offering (if configured in RevenueCat dashboard)
            if let placementOffering = offerings.currentOffering(forPlacement: "everwith_offering") {
                selectedOffering = placementOffering
                print("✅ Using placement-based offering: everwith_offering")
            } else if let currentOffering = offerings.current {
                selectedOffering = currentOffering
                print("✅ Using current offering: \(currentOffering.identifier)")
            } else if let everwithOffering = offerings.all["everwith_offering"] {
                selectedOffering = everwithOffering
                print("✅ Using everwith_offering: \(everwithOffering.identifier)")
            } else if let anyOffering = offerings.all.values.first {
                selectedOffering = anyOffering
                print("✅ Using fallback offering: \(anyOffering.identifier)")
            }
            
            if let offering = selectedOffering {
                availablePackages = offering.availablePackages
                print("✅ Loaded \(availablePackages.count) packages from offering: \(offering.identifier)")
                for package in availablePackages {
                    print("📦 Package: \(package.identifier) - Product: \(package.storeProduct.productIdentifier) - Price: \(package.storeProduct.localizedPriceString ?? "N/A")")
                }
            } else {
                print("❌ No offerings available at all")
                errorMessage = "Subscription products are not available. Please try again later."
            }
        } catch {
            print("❌ Error loading offerings from RevenueCat: \(error.localizedDescription)")
            print("⚠️ Error details: \(error)")
            errorMessage = "Unable to load subscription options. Please check your connection and try again."
        }
    }
    
    // MARK: - Ensure User Identified
    private func ensureUserIdentified() async {
        // Check if user is already identified
        let currentUserId = await Purchases.shared.appUserID
        print("👤 Current RevenueCat user ID: \(currentUserId)")
        
        // If user is anonymous or not set, try to identify with backend user ID
        if currentUserId == "$RCAnonymousID:" || currentUserId.isEmpty {
            if let userId = UserDefaults.standard.string(forKey: "user_id"), !userId.isEmpty {
                print("🔄 Identifying RevenueCat user with backend ID: \(userId)")
                do {
                    let (customerInfo, created) = try await Purchases.shared.logIn(userId)
                    print("✅ RevenueCat user identified: \(userId) (created: \(created))")
                } catch {
                    print("⚠️ Failed to identify RevenueCat user: \(error)")
                }
            } else {
                print("ℹ️ No backend user ID available yet, using anonymous RevenueCat user")
            }
        } else {
            print("✅ RevenueCat user already identified: \(currentUserId)")
        }
    }
    
    
    // MARK: - Subscription Management
    // Following RevenueCat sample pattern for purchases
    // Reference: https://github.com/RevenueCat/purchases-ios/blob/main/Examples/MagicWeather/MagicWeather/Sources/Controllers/WeatherViewController.swift#L38
    func purchaseSubscription(tier: SubscriptionTier) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get offerings following sample pattern
            let offerings = try await Purchases.shared.offerings()
            
            // Try placement-based offering first, then fallback to current offering
            // Following sample pattern: https://github.com/RevenueCat/purchases-ios/blob/main/Examples/MagicWeather/MagicWeather/Sources/Controllers/WeatherViewController.swift#L38
            let selectedOffering = offerings.currentOffering(forPlacement: "everwith_offering") 
                ?? offerings.current 
                ?? offerings.all["everwith_offering"]
                ?? offerings.all.values.first
            
            guard let offering = selectedOffering else {
                errorMessage = "Subscription service is not configured. Please contact support."
                isLoading = false
                return false
            }
            
            // Find the package for the requested tier
            var package: Package?
            
            switch tier {
            case .premiumMonthly:
                // Try to find monthly package by product ID first
                package = offering.availablePackages.first { 
                    $0.storeProduct.productIdentifier == RevenueCatConfig.ProductIDs.premiumMonthly 
                }
                // Fallback to monthly package type
                if package == nil {
                    package = offering.monthly
                }
            case .premiumYearly:
                // Try to find yearly package by product ID first
                package = offering.availablePackages.first { 
                    $0.storeProduct.productIdentifier == RevenueCatConfig.ProductIDs.premiumYearly 
                }
                // Fallback to annual package type
                if package == nil {
                    package = offering.annual
                }
            case .free:
                return false // Can't purchase free tier
            }
            
            guard let selectedPackage = package else {
                errorMessage = "Package not available"
                isLoading = false
                return false
            }
            
            // Purchase the package
            let result = try await Purchases.shared.purchase(package: selectedPackage)
            
            if !result.userCancelled {
                await updateSubscriptionStatus()
                await notifyBackendOfPurchase(result.customerInfo)
                
                print("✅ Purchase completed: \(selectedPackage.storeProduct.productIdentifier)")
                isLoading = false
                return true
            } else {
                print("ℹ️ Purchase cancelled by user")
                isLoading = false
                return false
            }
            
        } catch {
            // Handle STORE_PROBLEM error with fallback
            if let purchasesError = error as? RevenueCat.ErrorCode,
               purchasesError == .storeProblemError {
                print("⚠️ RevenueCat purchase failed with STORE_PROBLEM. Trying StoreKit fallback...")
                let fallbackSuccess = await purchaseSubscriptionWithStoreKitFallback(tier: tier, productId: nil)
                isLoading = false
                return fallbackSuccess
            } else {
                print("❌ Subscription purchase error: \(error.localizedDescription)")
                errorMessage = error.localizedDescription.contains("offerings") 
                    ? "Unable to load subscription options. Please check your connection and try again."
                    : error.localizedDescription
                isLoading = false
                return false
            }
        }
    }
    
    // MARK: - Credit Pack Purchase
    func purchaseCreditPack(_ pack: CreditPack) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let offerings = try await Purchases.shared.offerings()
            
            // Try to use the specific offering identifier first, fallback to current offering
            let offering = offerings.all["everwith_offering"] ?? offerings.current
            
            guard let selectedOffering = offering,
                  let package = selectedOffering.availablePackages.first(where: { $0.storeProduct.productIdentifier == pack.productId }) else {
                errorMessage = "Credit pack not available"
                isLoading = false
                return false
            }
            
            let result = try await Purchases.shared.purchase(package: package)
            
            if !result.userCancelled {
                await updateSubscriptionStatus()
                await notifyBackendOfCreditPurchase(pack, result.customerInfo)
                isLoading = false
                return true
            }
            
            isLoading = false
            return false
            
        } catch {
            print("❌ Credit pack purchase error: \(error.localizedDescription)")
            if error.localizedDescription.contains("offerings") {
                errorMessage = "Unable to load credit packs. Please check your connection and try again."
            } else {
                errorMessage = error.localizedDescription
            }
            isLoading = false
            return false
        }
    }
    
    // MARK: - Access Control
    // Following RevenueCat sample pattern for checking entitlements
    // Reference: https://github.com/RevenueCat/purchases-ios/blob/main/Examples/MagicWeather/MagicWeather/Sources/Controllers/WeatherViewController.swift#L38
    func checkAccess(for mode: ProcessingMode) async -> Bool {
        do {
            // Get customer info directly (following sample pattern)
            let customerInfo = try await Purchases.shared.customerInfo()
            
            // Check if user has active subscription entitlement
            let hasMonthly = customerInfo.entitlements[RevenueCatConfig.Entitlements.premiumMonthly]?.isActive == true
            let hasYearly = customerInfo.entitlements[RevenueCatConfig.Entitlements.premiumYearly]?.isActive == true
            
            if hasMonthly || hasYearly {
                return true
            }
            
            // For free tier, check local free uses
            await updateSubscriptionStatus()
            return subscriptionStatus.freeUsesRemaining > 0
        } catch {
            print("❌ Error checking access: \(error)")
            // Fallback to subscription status check
            await updateSubscriptionStatus()
            return subscriptionStatus.canUseFeature
        }
    }
    
    func useFeature(for mode: ProcessingMode) async -> Bool {
        await updateSubscriptionStatus()
        
        switch subscriptionStatus.tier {
        case .premiumMonthly, .premiumYearly:
            return true
        case .free:
            if subscriptionStatus.freeUsesRemaining > 0 {
                await decrementFreeUses()
                return true
            }
            return false
        }
    }
    
    // MARK: - Status Updates
    func updateSubscriptionStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            
            // Load offerings while we're updating
            await loadOfferings()
            
            // Determine subscription tier
            let tier: SubscriptionTier
            if customerInfo.entitlements["premium_monthly"]?.isActive == true {
                tier = .premiumMonthly
            } else if customerInfo.entitlements["premium_yearly"]?.isActive == true {
                tier = .premiumYearly
            } else {
                tier = .free
            }
            
            // Get credits from backend
            let credits = await fetchUserCredits()
            
            // Get free uses from UserDefaults
            let freeUsesRemaining = UserDefaults.standard.integer(forKey: "free_uses_remaining")
            let lastFreeUseDate = UserDefaults.standard.object(forKey: "last_free_use_date") as? Date
            
            let oldTier = subscriptionStatus.tier
            
            subscriptionStatus = UserSubscriptionStatus(
                tier: tier,
                credits: credits,
                hasActiveSubscription: tier != .free,
                subscriptionExpiryDate: customerInfo.entitlements["premium_monthly"]?.expirationDate ?? customerInfo.entitlements["premium_yearly"]?.expirationDate,
                freeUsesRemaining: freeUsesRemaining,
                lastFreeUseDate: lastFreeUseDate
            )
            
            // Track subscription status change
            if oldTier != tier {
                print("📊 Subscription changed from \(oldTier) to \(tier)")
            }
            
        } catch {
            print("Error updating subscription status: \(error)")
        }
    }
    
    // MARK: - Free Tier Management
    private func decrementFreeUses() async {
        let currentUses = UserDefaults.standard.integer(forKey: "free_uses_remaining")
        let newUses = max(0, currentUses - 1)
        UserDefaults.standard.set(newUses, forKey: "free_uses_remaining")
        UserDefaults.standard.set(Date(), forKey: "last_free_use_date")
        
        // Reset daily if needed
        await resetDailyFreeUsesIfNeeded()
        
        await updateSubscriptionStatus()
    }
    
    private func resetDailyFreeUsesIfNeeded() async {
        guard let lastUseDate = UserDefaults.standard.object(forKey: "last_free_use_date") as? Date else {
            UserDefaults.standard.set(1, forKey: "free_uses_remaining")
            return
        }
        
        let calendar = Calendar.current
        if !calendar.isDate(lastUseDate, inSameDayAs: Date()) {
            UserDefaults.standard.set(1, forKey: "free_uses_remaining")
        }
    }
    
    // MARK: - Backend Communication
    private func notifyBackendOfPurchase(_ customerInfo: CustomerInfo) async {
        guard let userId = UserDefaults.standard.string(forKey: "user_id") else {
            print("⚠️ Cannot notify backend: No user ID found")
            return
        }
        
        // Determine purchase type and product ID
        var productId = ""
        var purchaseType = ""
        
        if customerInfo.entitlements["premium_monthly"]?.isActive == true {
            productId = "com.matrix.everwith.monthly"
            purchaseType = "subscription"
        } else if customerInfo.entitlements["premium_yearly"]?.isActive == true {
            productId = "com.matrix.everwith.yearly"
            purchaseType = "subscription"
        } else {
            print("⚠️ No active entitlement found")
            return
        }
        
        // Get transaction information
        let transactionId = customerInfo.entitlements.all.values
            .compactMap { entitlement -> String? in
                guard entitlement.isActive, let latestDate = entitlement.latestPurchaseDate else { return nil }
                return entitlement.productIdentifier
            }
            .first ?? UUID().uuidString
        
        // Prepare RevenueCat data
        let revenueCatData: [String: Any] = [
            "original_app_user_id": customerInfo.originalAppUserId,
            "first_seen": customerInfo.firstSeen.formatted(),
            "request_date": customerInfo.requestDate.formatted(),
            "management_url": customerInfo.managementURL?.absoluteString ?? ""
        ]
        
        print("📤 Notifying backend of purchase: \(productId)")
        
        do {
            // Use the subscription API service to notify backend
            let apiService = SubscriptionAPIService.shared
            try await apiService.notifyPurchase(
                userId: userId,
                productId: productId,
                transactionId: transactionId,
                purchaseType: purchaseType,
                revenueCatData: revenueCatData
            )
            print("✅ Backend notified successfully")
        } catch {
            print("❌ Failed to notify backend: \(error)")
        }
    }
    
    private func notifyBackendOfCreditPurchase(_ pack: CreditPack, _ customerInfo: CustomerInfo) async {
        guard let userId = UserDefaults.standard.string(forKey: "user_id") else {
            print("⚠️ Cannot notify backend: No user ID found")
            return
        }
        
        // Get transaction information
        let transactionId = UUID().uuidString // Generate transaction ID
        
        // Prepare RevenueCat data
        let revenueCatData: [String: Any] = [
            "original_app_user_id": customerInfo.originalAppUserId,
            "first_seen": customerInfo.firstSeen.formatted(),
            "request_date": customerInfo.requestDate.formatted()
        ]
        
        print("📤 Notifying backend of credit purchase: \(pack.productId)")
        
        do {
            // Use the subscription API service to notify backend
            let apiService = SubscriptionAPIService.shared
            try await apiService.notifyPurchase(
                userId: userId,
                productId: pack.productId,
                transactionId: transactionId,
                purchaseType: "credit_pack",
                revenueCatData: revenueCatData
            )
            print("✅ Backend notified of credit purchase successfully")
        } catch {
            print("❌ Failed to notify backend: \(error)")
        }
    }
    
    private func fetchUserCredits() async -> Int {
        guard let userId = UserDefaults.standard.string(forKey: "user_id") else {
            return 0
        }
        
        do {
            let subscriptionService = SubscriptionService.shared
            let creditsResponse = try await subscriptionService.fetchUserCredits()
            return creditsResponse.creditsRemaining
        } catch {
            print("❌ Failed to fetch user credits: \(error)")
            return 0
        }
    }
    
    // MARK: - Restore Purchases
    // Following RevenueCat sample pattern for restoring purchases
    // Reference: https://github.com/RevenueCat/purchases-ios/blob/main/Examples/MagicWeather/MagicWeather/Sources/Controllers/UserViewController.swift#L116
    func restorePurchases() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            print("✅ Purchases restored successfully")
            
            // Update subscription status after restore
            await updateSubscriptionStatus()
            
            isLoading = false
            return true
        } catch {
            print("❌ Error restoring purchases: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    // MARK: - User Identification & Logout
    // Following RevenueCat sample pattern for login/logout
    // Reference: https://github.com/RevenueCat/purchases-ios/blob/main/Examples/MagicWeather/MagicWeather/Sources/Controllers/UserViewController.swift#L73
    
    /// Identify user with RevenueCat after authentication
    /// Following sample pattern: https://github.com/RevenueCat/purchases-ios/blob/main/Examples/MagicWeather/MagicWeather/Sources/Controllers/UserViewController.swift#L73
    func identifyUser(userId: String) async {
        do {
            let (customerInfo, created) = try await Purchases.shared.logIn(userId)
            print("✅ RevenueCat: User identified as \(userId)")
            print("✅ RevenueCat: Customer ID: \(customerInfo.originalAppUserId)")
            print("✅ RevenueCat: New user: \(created)")
            
            // Update subscription status after identification
            await updateSubscriptionStatus()
        } catch {
            print("⚠️ RevenueCat: Failed to identify user: \(error.localizedDescription)")
        }
    }
    
    /// Log out from RevenueCat (returns to anonymous user)
    /// Following sample pattern: https://github.com/RevenueCat/purchases-ios/blob/main/Examples/MagicWeather/MagicWeather/Sources/Controllers/UserViewController.swift#L116
    /// Note: Each time you call logOut, a new installation will be logged in the RevenueCat dashboard
    /// as that metric tracks unique user ID's that are in-use.
    func logOut() async {
        do {
            let customerInfo = try await Purchases.shared.logOut()
            print("✅ RevenueCat: Logged out user")
            print("✅ RevenueCat: Back to anonymous user: \(customerInfo.originalAppUserId)")
            
            // Reset subscription status to free tier
            subscriptionStatus = UserSubscriptionStatus(
                tier: .free,
                credits: 0,
                hasActiveSubscription: false,
                subscriptionExpiryDate: nil,
                freeUsesRemaining: 1,
                lastFreeUseDate: nil
            )
        } catch {
            print("⚠️ RevenueCat: Failed to log out: \(error.localizedDescription)")
        }
    }
    
    /// Get current RevenueCat user ID
    func getCurrentUserId() async -> String? {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            return customerInfo.originalAppUserId
        } catch {
            return nil
        }
    }
}

// MARK: - StoreKit Fallback Purchasing
private extension RevenueCatService {
    func productIdentifier(for tier: SubscriptionTier) -> String? {
        switch tier {
        case .premiumMonthly:
            return RevenueCatConfig.ProductIDs.premiumMonthly
        case .premiumYearly:
            return RevenueCatConfig.ProductIDs.premiumYearly
        case .free:
            return nil
        }
    }
    
    func purchaseSubscriptionWithStoreKitFallback(tier: SubscriptionTier, productId overrideProductId: String?) async -> Bool {
        guard #available(iOS 15.0, *) else {
            errorMessage = "App Store is unavailable on this device. Please try again later."
            return false
        }
        
        let resolvedProductId = overrideProductId ?? productIdentifier(for: tier)
        
        guard let productId = resolvedProductId else {
            errorMessage = "Subscription tier not available."
            return false
        }
        
        do {
            print("🛠️ StoreKit fallback: Loading product \(productId)")
            let products = try await Product.products(for: [productId])
            guard let product = products.first else {
                errorMessage = "Subscription product is currently unavailable."
                return false
            }
            
            let result = try await product.purchase()
            
            switch result {
            case .success(let verificationResult):
                let transaction = try verifiedTransaction(from: verificationResult)
                await transaction.finish()
                
                // Sync with RevenueCat to ensure entitlements are updated
                try await Purchases.shared.syncPurchases()
                await updateSubscriptionStatus()
                
                if let customerInfo = try? await Purchases.shared.customerInfo() {
                    await notifyBackendOfPurchase(customerInfo)
                }
                
                print("✅ StoreKit fallback purchase succeeded for \(productId)")
                return true
                
            case .pending:
                errorMessage = "Purchase is pending approval. Please try again later."
                return false
                
            case .userCancelled:
                print("ℹ️ StoreKit fallback purchase cancelled by user")
                return false
                
            @unknown default:
                errorMessage = "Unknown App Store response. Please try again."
                return false
            }
        } catch {
            print("❌ StoreKit fallback purchase error: \(error)")
            errorMessage = "Unable to complete purchase: \(error.localizedDescription)"
            return false
        }
    }
    
    @available(iOS 15.0, *)
    func verifiedTransaction(from result: StoreKit.VerificationResult<StoreKit.Transaction>) throws -> StoreKit.Transaction {
        switch result {
        case .verified(let transaction):
            return transaction
        case .unverified(_, let verificationError):
            throw verificationError ?? NSError(
                domain: "com.everwith.storekit",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Unable to verify App Store transaction."]
            )
        }
    }
}

// MARK: - RevenueCat Delegate
// Following RevenueCat sample pattern for delegate implementation
// Reference: https://github.com/RevenueCat/purchases-ios/blob/main/Examples/MagicWeather/MagicWeather/Sources/Lifecycle/AppDelegate.swift
extension RevenueCatService: PurchasesDelegate {
    /// Called whenever the shared instance of Purchases updates the CustomerInfo cache
    /// Following sample pattern: https://github.com/RevenueCat/purchases-ios/blob/main/Examples/MagicWeather/MagicWeather/Sources/Lifecycle/AppDelegate.swift
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        // If necessary, refresh app UI from updated CustomerInfo
        Task { @MainActor in
            await updateSubscriptionStatus()
        }
    }
}

// MARK: - Processing Mode
enum ProcessingMode {
    case restore
    case merge
    
    var rawValue: String {
        switch self {
        case .restore:
            return "restore"
        case .merge:
            return "together"  // Backend expects "together" for memory merge
        }
    }
}
