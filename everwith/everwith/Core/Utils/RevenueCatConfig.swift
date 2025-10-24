//
//  RevenueCatConfig.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import Foundation
import RevenueCat

// MARK: - RevenueCat Configuration
class RevenueCatConfig {
    static let shared = RevenueCatConfig()
    
    // Replace with your actual RevenueCat API key
    private let apiKey = "appl_iPVTaTjNfaUbfwSQVqwiqtUUTFg"
    
    // Product IDs - Replace with your actual product IDs from App Store Connect
    struct ProductIDs {
        // Subscriptions
        static let premiumMonthly = "com.everwith.premium.month"
        static let premiumYearly = "com.everwith.premium.yearly"
        
        // Credit Packs
        static let credits5 = "com.everwith.credits.5"
        static let credits10 = "com.everwith.credits.10"
        static let credits25 = "com.everwith.credits.25"
        static let credits50 = "com.everwith.credits.50"
    }
    
    // Entitlement IDs
    struct Entitlements {
        static let premiumMonthly = "premium_monthly"
        static let premiumYearly = "premium_yearly"
    }
    
    private init() {}
    
    func configure() {
        // Configure RevenueCat
        // Note: This will be implemented when RevenueCat SDK is installed
        print("RevenueCat configuration will be implemented when SDK is installed")
        
        // TODO: Uncomment when RevenueCat SDK is installed
        /*
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: apiKey)
        
        // Set up delegate
        Purchases.shared.delegate = RevenueCatService.shared
        
        // Configure offerings
        configureOfferings()
        */
    }
    
    private func configureOfferings() {
        // This would typically be done in the RevenueCat dashboard
        // But you can also configure programmatically if needed
        
        // TODO: Implement when RevenueCat SDK is installed
        print("Offerings configuration will be implemented when SDK is installed")
    }
}

// MARK: - RevenueCat Setup Instructions
/*
 
 SETUP INSTRUCTIONS:
 
 1. Create RevenueCat Account:
    - Go to https://app.revenuecat.com
    - Create account and project
    - Get your API key from Project Settings > API Keys
 
 2. Configure App Store Connect:
    - Create in-app purchases in App Store Connect
    - Use the Product IDs defined above
    - Set up subscription groups if needed
 
 3. Configure RevenueCat Dashboard:
    - Add your app (iOS bundle ID)
    - Create products with the Product IDs above
    - Set up offerings (subscription tiers)
    - Configure entitlements
 
 4. Update Configuration:
    - Replace 'your_revenuecat_api_key_here' with your actual API key
    - Update Product IDs to match your App Store Connect products
    - Test with sandbox environment first
 
 5. Testing:
    - Use sandbox test accounts
    - Test subscription flows
    - Verify webhook notifications
    - Test restore purchases
 
 6. Production:
    - Switch to production API key
    - Submit for App Store review
    - Monitor conversion metrics
 
 */
