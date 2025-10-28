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
    func loadOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            currentOfferings = offerings
            
            // Get available packages from the current offering
            if let currentOffering = offerings.current {
                availablePackages = currentOffering.availablePackages
                print("✅ Loaded \(availablePackages.count) packages")
                for package in availablePackages {
                    print("📦 Package: \(package.identifier) - Product: \(package.storeProduct.productIdentifier) - Price: \(package.storeProduct.localizedPriceString ?? "N/A")")
                }
            } else {
                print("⚠️ No current offering found")
                print("📦 Available offerings: \(offerings.all.keys)")
                
                // Try to get ANY offering as fallback
                if let anyOffering = offerings.all.values.first {
                    availablePackages = anyOffering.availablePackages
                    print("✅ Using fallback offering: \(anyOffering.identifier)")
                }
            }
        } catch {
            print("❌ Error loading offerings: \(error.localizedDescription)")
            print("⚠️ This usually means products haven't been approved in App Store Connect yet")
            print("ℹ️ For testing: Products must be approved before working in production")
            
            // In debug mode, try to use StoreKit configuration
            #if DEBUG
            print("📱 DEBUG MODE: Attempting to use StoreKit configuration file")
            await loadStoreKitOfferings()
            #endif
        }
    }
    
    #if DEBUG
    private func loadStoreKitOfferings() async {
        // Try to load products directly from StoreKit for testing
        print("🛠️ DEBUG: Loading from StoreKit configuration file")
        
        // Get all products from StoreKit
        let productIds = [
            "com.matrix.everwith.monthly",
            "com.matrix.everwith.yearly",
            "com.everwith.credits.5",
            "com.everwith.credits.15",
            "com.everwith.credits.50"
        ]
        
        do {
            let products = try await Product.products(for: productIds)
            print("📦 DEBUG: Loaded \(products.count) products from StoreKit")
            
            // Clear available packages
            await MainActor.run {
                availablePackages = []
            }
            
            // For each product, we need to create a mock offering
            // Since RevenueCat can't use these directly, we'll just log them
            for product in products {
                print("📦 DEBUG Product: \(product.id) - \(product.displayName) - \(product.displayPrice)")
            }
        } catch {
            print("❌ DEBUG: Failed to load StoreKit products: \(error)")
        }
    }
    #endif
    
    // MARK: - Subscription Management
    func purchaseSubscription(tier: SubscriptionTier) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let offerings = try await Purchases.shared.offerings()
            
            print("📦 REVENUECAT DEBUG:")
            print("📦 Available offerings: \(offerings.all.keys)")
            print("📦 Total offerings count: \(offerings.all.count)")
            print("📦 Current offering: \(offerings.current?.identifier ?? "none")")
            
            // Debug: Print all available offerings
            for (key, offering) in offerings.all {
                print("📦 Offering '\(key)': \(offering.identifier) with \(offering.availablePackages.count) packages")
                for package in offering.availablePackages {
                    print("   📦 Package: \(package.identifier) - Product: \(package.storeProduct.productIdentifier)")
                }
            }
            
            // Try to use the specific offering identifier first
            var offering: Offering?
            if let everwithOffering = offerings.all["everwith_offering"] {
                offering = everwithOffering
                print("✅ Using offering: everwith_offering")
            } else if let currentOffering = offerings.current {
                offering = currentOffering
                print("⚠️ Using current offering: \(currentOffering.identifier)")
            } else if let firstOffering = offerings.all.values.first {
                offering = firstOffering
                print("⚠️ Using first available offering: \(firstOffering.identifier)")
            } else {
                print("❌ No offerings available at all!")
            }
            
            // Try to use the specific offering, fallback to current, then to first available
            var chosenOffering: Offering?
            
            if let everwithOffering = offerings.all["everwith_offering"] {
                chosenOffering = everwithOffering
                print("✅ Using offering: everwith_offering")
            } else if let currentOffering = offerings.current {
                chosenOffering = currentOffering
                print("⚠️ Using current offering: \(currentOffering.identifier)")
            } else if let firstOffering = offerings.all.values.first {
                chosenOffering = firstOffering
                print("⚠️ Using first available offering: \(firstOffering.identifier)")
            }
            
            guard let selectedOffering = chosenOffering else {
                print("❌ No offerings available at all!")
                errorMessage = "Subscription service is not configured. Please contact support."
                isLoading = false
                return false
            }
            
            print("📦 Using offering: \(selectedOffering.identifier)")
            print("📦 Available packages: \(selectedOffering.availablePackages.map { $0.storeProduct.productIdentifier })")
            
            var package: Package?
            
            switch tier {
            case .premiumMonthly:
                // Try to find monthly package by product ID
                package = selectedOffering.availablePackages.first { $0.storeProduct.productIdentifier == "com.matrix.everwith.monthly" }
                if package == nil {
                    package = selectedOffering.monthly // Fallback to monthly package type
                }
            case .premiumYearly:
                // Try to find yearly package by product ID
                package = selectedOffering.availablePackages.first { $0.storeProduct.productIdentifier == "com.matrix.everwith.yearly" }
                if package == nil {
                    package = selectedOffering.annual // Fallback to annual package type
                }
            case .free:
                return false // Can't purchase free tier
            }
            
            guard let selectedPackage = package else {
                errorMessage = "Package not available"
                isLoading = false
                return false
            }
            
            let result = try await Purchases.shared.purchase(package: selectedPackage)
            
            if !result.userCancelled {
                await updateSubscriptionStatus()
                await notifyBackendOfPurchase(result.customerInfo)
                
                // Track purchase completion
                print("📊 Purchase completed: \(selectedPackage.storeProduct.productIdentifier)")
                
                isLoading = false
                return true
            } else {
                // Track purchase cancellation
                print("📊 Purchase cancelled: \(selectedPackage.storeProduct.productIdentifier)")
            }
            
            isLoading = false
            return false
            
        } catch {
            print("❌ Subscription purchase error: \(error.localizedDescription)")
            if error.localizedDescription.contains("offerings") {
                errorMessage = "Unable to load subscription options. Please check your connection and try again."
            } else {
                errorMessage = error.localizedDescription
            }
            isLoading = false
            return false
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
    func checkAccess(for mode: ProcessingMode) async -> Bool {
        await updateSubscriptionStatus()
        
        switch subscriptionStatus.tier {
        case .premiumMonthly, .premiumYearly:
            return true
        case .free:
            return subscriptionStatus.freeUsesRemaining > 0
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
    func restorePurchases() async -> Bool {
        isLoading = true
        
        do {
            _ = try await Purchases.shared.restorePurchases()
            await updateSubscriptionStatus()
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    // MARK: - User Identification & Logout
    
    /// Identify user with RevenueCat after authentication
    func identifyUser(userId: String) async {
        do {
            let (customerInfo, created) = try await Purchases.shared.logIn(userId)
            print("✅ RevenueCat: User identified as \(userId)")
            print("✅ RevenueCat: Customer ID: \(customerInfo.originalAppUserId)")
            print("✅ RevenueCat: New user: \(created)")
            
            // Update subscription status after identification
            await updateSubscriptionStatus()
        } catch {
            print("⚠️ RevenueCat: Failed to identify user: \(error)")
        }
    }
    
    /// Log out from RevenueCat (returns to anonymous user)
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
            print("⚠️ RevenueCat: Failed to log out: \(error)")
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

// MARK: - RevenueCat Delegate
extension RevenueCatService: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task {
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
            return "merge"
        }
    }
}
