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
        // Configure RevenueCat with error handling
        print("🚀 Configuring RevenueCat with project ID: app660b5a6b08")
        
        // Only enable debug logging in debug builds
        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .info
        #endif
        
        // Configure RevenueCat - this may show warnings if packages aren't set up yet
        // but won't crash the app
        Purchases.configure(withAPIKey: apiKey)
        
        // Set up delegate
        Purchases.shared.delegate = RevenueCatService.shared
        
        // Configure offerings (may show warnings if not configured in dashboard)
        configureOfferings()
        
        print("✅ RevenueCat configuration completed")
        print("⚠️ Note: Configure offerings with packages in RevenueCat dashboard to enable purchases")
    }
    
    private func configureOfferings() {
        // Configure offerings from RevenueCat dashboard
        // Offering ID: everwith_offering
        // RevenueCat ID: ofrng133ec87e21
        
        print("📦 Configured offering: everwith_offering (ID: ofrng133ec87e21)")
        
        // RevenueCat automatically fetches offerings from the dashboard
        // No manual configuration needed - the SDK handles this
        // Your offering "everwith_offering" will be available as offerings.all["everwith_offering"]
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
