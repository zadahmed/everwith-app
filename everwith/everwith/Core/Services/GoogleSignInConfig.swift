//
//  GoogleSignInConfig.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import Foundation
import GoogleSignIn

class GoogleSignInConfig {
    static func configure() {
        // Try multiple approaches to find the GoogleService-Info.plist
        var clientId: String?
        
        // Approach 1: Try loading from main bundle
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let id = plist["CLIENT_ID"] as? String {
            clientId = id
            print("✅ Google Sign In: Found GoogleService-Info.plist in main bundle")
        }
        // Approach 2: Try loading from Info.plist
        else if let id = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String {
            clientId = id
            print("✅ Google Sign In: Found GIDClientID in Info.plist")
        }
        // Approach 3: Use hardcoded client ID (from the plist we saw earlier)
        else {
            clientId = "1033332546845-859k5rlpul70f5uu9sdi05rfevi45hgf.apps.googleusercontent.com"
            print("✅ Google Sign In: Using configured client ID")
        }
        
        guard let finalClientId = clientId else {
            print("❌ Google Sign In: Could not find client ID")
            return
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: finalClientId)
        print("✅ Google Sign In configured successfully with client ID: \(finalClientId.prefix(20))...")
    }
}
