//
//  ShareModels.swift
//  EverWith
//
//  Created by Zahid Ahmed on 19/11/2025.
//

import Foundation
import SwiftUI

enum SharePlatform: String, CaseIterable, Identifiable {
    case instagram
    case tiktok
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .instagram: return "Instagram"
        case .tiktok: return "TikTok"
        }
    }
    
    var systemIcon: String {
        switch self {
        case .instagram: return "camera.filters"
        case .tiktok: return "music.note"
        }
    }
    
    var accentColors: [Color] {
        switch self {
        case .instagram:
            return [Color(red: 0.98, green: 0.43, blue: 0.36), Color(red: 0.69, green: 0.13, blue: 0.78)]
        case .tiktok:
            return [Color(red: 0.16, green: 0.97, blue: 0.94), Color(red: 0.99, green: 0.18, blue: 0.42)]
        }
    }
}

enum ShareFlowType: String {
    case restore
    case merge
    case timeline
    case celebrity
    case reunite
    case family
    
    var identifier: String { rawValue }
    
    var title: String {
        switch self {
        case .restore: return "Photo Restore"
        case .merge: return "Memory Merge"
        case .timeline: return "Timeline Comparison"
        case .celebrity: return "Celebrity Glow"
        case .reunite: return "Reunite Flow"
        case .family: return "Family Flow"
        }
    }
}

struct ShareVerificationPayload: Codable {
    let platform: String
    let shareUrl: String?
    let caption: String?
    let hashtags: [String]
    let shareType: String
    
    enum CodingKeys: String, CodingKey {
        case platform
        case shareUrl = "share_url"
        case caption
        case hashtags
        case shareType = "share_type"
    }
}

struct ShareVerificationResponseModel: Codable {
    let message: String
    let creditsAwarded: Int
    let newCreditBalance: Int
    let verificationId: String
    let alreadyClaimed: Bool
    
    enum CodingKeys: String, CodingKey {
        case message
        case creditsAwarded = "credits_awarded"
        case newCreditBalance = "new_credit_balance"
        case verificationId = "verification_id"
        case alreadyClaimed = "already_claimed"
    }
}

