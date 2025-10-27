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
        CreditPack(credits: 5, price: "£4.99", productId: "credits_5", savings: nil),
        CreditPack(credits: 15, price: "£9.99", productId: "credits_15", savings: "Save 33%"),
        CreditPack(credits: 50, price: "£24.99", productId: "credits_50", savings: "Save 50%")
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
                    }
                }
            }
        }
    }
    
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
            
            guard let selectedOffering = offering else {
                print("❌ No offerings found. Available: \(offerings.all.keys)")
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
                package = selectedOffering.availablePackages.first { $0.storeProduct.productIdentifier == "com.everwith.premium.month" }
                if package == nil {
                    package = selectedOffering.monthly // Fallback to monthly package type
                }
            case .premiumYearly:
                // Try to find yearly package by product ID
                package = selectedOffering.availablePackages.first { $0.storeProduct.productIdentifier == "com.everwith.premium.yearly" }
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
            errorMessage = error.localizedDescription
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
            errorMessage = error.localizedDescription
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
        // Send purchase info to your backend
        // This would typically include the transaction details
        print("Purchase completed, notifying backend...")
    }
    
    private func notifyBackendOfCreditPurchase(_ pack: CreditPack, _ customerInfo: CustomerInfo) async {
        // Send credit purchase info to your backend
        print("Credit pack purchased, notifying backend...")
    }
    
    private func fetchUserCredits() async -> Int {
        // Fetch user credits from your backend
        // For now, return 0
        return 0
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
