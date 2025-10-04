//
//  HomeModels.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import Foundation
import SwiftUI

// MARK: - Project Status
enum ProjectStatus: String, CaseIterable {
    case draft = "draft"
    case ready = "ready"
    case shared = "shared"
    
    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .ready: return "Ready"
        case .shared: return "Shared"
        }
    }
    
    var color: Color {
        switch self {
        case .draft: return .charcoal.opacity(0.6)
        case .ready: return .honeyGold
        case .shared: return .fern
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .draft: return .charcoal.opacity(0.1)
        case .ready: return .honeyGold.opacity(0.15)
        case .shared: return .fern.opacity(0.15)
        }
    }
}

// MARK: - Project Model
struct Project: Identifiable {
    let id = UUID()
    let title: String
    let description: String?
    let thumbnailURL: String?
    let status: ProjectStatus
    let createdAt: Date
    let updatedAt: Date
    let type: ProjectType
    
    enum ProjectType: String, CaseIterable {
        case restore = "restore"
        case tribute = "tribute"
        
        var displayName: String {
            switch self {
            case .restore: return "Restore"
            case .tribute: return "Tribute"
            }
        }
        
        var icon: String {
            switch self {
            case .restore: return "photo.badge.plus"
            case .tribute: return "heart.circle"
            }
        }
    }
}

// MARK: - Hero Action
struct HeroAction: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let gradient: [Color]
    let action: () -> Void
    
    static let actions: [HeroAction] = [
        HeroAction(
            title: "Restore a photo",
            subtitle: "Bring memories back to life",
            description: "Upload old photos and let our AI restore them to their former glory",
            icon: "photo.badge.plus",
            gradient: [Color.honeyGold.opacity(0.8), Color.warmLinen.opacity(0.6)],
            action: {
                // Navigate to Import with restore mode
                NotificationCenter.default.post(name: .navigateToImport, object: ImportMode.restore)
            }
        ),
        HeroAction(
            title: "Together Scene",
            subtitle: "Create beautiful tributes",
            description: "Compose beautiful scenes with multiple photos and backgrounds",
            icon: "heart.circle",
            gradient: [Color.sky.opacity(0.8), Color.fern.opacity(0.6)],
            action: {
                // Navigate to Import with compose mode
                NotificationCenter.default.post(name: .navigateToImport, object: ImportMode.compose)
            }
        )
    ]
}

// MARK: - Mock Data
extension Project {
    static let mockProjects: [Project] = [
        Project(
            title: "Grandma's Wedding Photo",
            description: "Restored from 1952",
            thumbnailURL: nil,
            status: .ready,
            createdAt: Date().addingTimeInterval(-86400 * 2),
            updatedAt: Date().addingTimeInterval(-3600),
            type: .restore
        ),
        Project(
            title: "Family Reunion Tribute",
            description: "Summer 2023 memories",
            thumbnailURL: nil,
            status: .shared,
            createdAt: Date().addingTimeInterval(-86400 * 5),
            updatedAt: Date().addingTimeInterval(-7200),
            type: .tribute
        ),
        Project(
            title: "Childhood Photo",
            description: "Working on restoration",
            thumbnailURL: nil,
            status: .draft,
            createdAt: Date().addingTimeInterval(-86400 * 1),
            updatedAt: Date().addingTimeInterval(-1800),
            type: .restore
        )
    ]
}
