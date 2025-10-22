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
        case .draft: return .softPlum
        case .ready: return .blushPink
        case .shared: return .roseMagenta
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .draft: return .softPlum.opacity(0.1)
        case .ready: return .blushPink.opacity(0.15)
        case .shared: return .roseMagenta.opacity(0.15)
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
        case together = "together"
        
        var displayName: String {
            switch self {
            case .restore: return "Photo Restore"
            case .together: return "Memory Merge"
            }
        }
        
        var icon: String {
            switch self {
            case .restore: return "photo.badge.plus"
            case .together: return "heart.circle.fill"
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
            title: "Photo Restore",
            subtitle: "Make old photos HD again",
            description: "Upload old photos and watch them transform into HD quality",
            icon: "photo.badge.plus",
            gradient: [Color.blushPink.opacity(0.8), Color.softCream.opacity(0.6)],
            action: {
                // Navigate to Restore view
                NotificationCenter.default.post(name: .navigateToRestore, object: nil)
            }
        ),
        HeroAction(
            title: "Memory Merge",
            subtitle: "Bring old memories together",
            description: "Combine photos to create moments that never existed before",
            icon: "heart.circle",
            gradient: [Color.roseMagenta.opacity(0.8), Color.memoryViolet.opacity(0.6)],
            action: {
                // Navigate to Together view
                NotificationCenter.default.post(name: .navigateToTogether, object: nil)
            }
        )
    ]
}

// MARK: - Processed Image
struct ProcessedImage: Identifiable, Codable {
    let id: String
    let userId: String?
    let imageType: String?
    let originalImageUrl: String?
    let processedImageUrl: String?
    let thumbnailUrl: String?
    
    // Processing parameters
    let qualityTarget: String?
    let outputFormat: String?
    let aspectRatio: String?
    
    // For together images
    let subjectAUrl: String?
    let subjectBUrl: String?
    let backgroundPrompt: String?
    
    // Metadata
    let width: Int?
    let height: Int?
    let fileSize: Int?
    
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case imageType = "image_type"
        case originalImageUrl = "original_image_url"
        case processedImageUrl = "processed_image_url"
        case thumbnailUrl = "thumbnail_url"
        case qualityTarget = "quality_target"
        case outputFormat = "output_format"
        case aspectRatio = "aspect_ratio"
        case subjectAUrl = "subject_a_url"
        case subjectBUrl = "subject_b_url"
        case backgroundPrompt = "background_prompt"
        case width
        case height
        case fileSize = "file_size"
        case createdAt = "created_at"
    }
    
    // Custom initializer to handle missing fields gracefully
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Only ID is required, everything else is optional
        id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        userId = try? container.decode(String.self, forKey: .userId)
        imageType = try? container.decode(String.self, forKey: .imageType)
        originalImageUrl = try? container.decode(String.self, forKey: .originalImageUrl)
        processedImageUrl = try? container.decode(String.self, forKey: .processedImageUrl)
        thumbnailUrl = try? container.decode(String.self, forKey: .thumbnailUrl)
        qualityTarget = try? container.decode(String.self, forKey: .qualityTarget)
        outputFormat = try? container.decode(String.self, forKey: .outputFormat)
        aspectRatio = try? container.decode(String.self, forKey: .aspectRatio)
        subjectAUrl = try? container.decode(String.self, forKey: .subjectAUrl)
        subjectBUrl = try? container.decode(String.self, forKey: .subjectBUrl)
        backgroundPrompt = try? container.decode(String.self, forKey: .backgroundPrompt)
        width = try? container.decode(Int.self, forKey: .width)
        height = try? container.decode(Int.self, forKey: .height)
        fileSize = try? container.decode(Int.self, forKey: .fileSize)
        createdAt = try? container.decode(Date.self, forKey: .createdAt)
    }
    
    var displayType: String {
        guard let imageType = imageType else { return "Processed Image" }
        return imageType == "restore" ? "Photo Restore" : "Memory Merge"
    }
    
    var icon: String {
        guard let imageType = imageType else { return "photo" }
        return imageType == "restore" ? "photo.badge.plus" : "heart.circle.fill"
    }
    
    var color: Color {
        guard let imageType = imageType else { return .gray }
        return imageType == "restore" ? .blushPink : .roseMagenta
    }
}

// MARK: - Image History Response
struct ImageHistoryResponse: Codable {
    let images: [ProcessedImage]
    let total: Int
    let page: Int
    let pageSize: Int
    
    enum CodingKeys: String, CodingKey {
        case images
        case total
        case page
        case pageSize = "page_size"
    }
    
    // Custom initializer to handle missing fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        images = try container.decode([ProcessedImage].self, forKey: .images)
        total = try container.decode(Int.self, forKey: .total)
        page = try container.decode(Int.self, forKey: .page)
        // Default to 20 if page_size is missing
        pageSize = (try? container.decode(Int.self, forKey: .pageSize)) ?? 20
    }
}

// MARK: - Processed Image Create
struct ProcessedImageCreate: Codable {
    let imageType: String
    let originalImageUrl: String?
    let processedImageUrl: String
    let thumbnailUrl: String?
    let qualityTarget: String?
    let outputFormat: String?
    let aspectRatio: String?
    let subjectAUrl: String?
    let subjectBUrl: String?
    let backgroundPrompt: String?
    let width: Int?
    let height: Int?
    let fileSize: Int?
    
    enum CodingKeys: String, CodingKey {
        case imageType = "image_type"
        case originalImageUrl = "original_image_url"
        case processedImageUrl = "processed_image_url"
        case thumbnailUrl = "thumbnail_url"
        case qualityTarget = "quality_target"
        case outputFormat = "output_format"
        case aspectRatio = "aspect_ratio"
        case subjectAUrl = "subject_a_url"
        case subjectBUrl = "subject_b_url"
        case backgroundPrompt = "background_prompt"
        case width
        case height
        case fileSize = "file_size"
    }
}

// MARK: - Image Stats
struct ImageStats: Codable {
    let totalImages: Int
    let restoreCount: Int
    let togetherCount: Int
    let mostRecent: Date?
    
    enum CodingKeys: String, CodingKey {
        case totalImages = "total_images"
        case restoreCount = "restore_count"
        case togetherCount = "together_count"
        case mostRecent = "most_recent"
    }
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
            type: .together
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
