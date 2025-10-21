//
//  ImportModels.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import Foundation
import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Import Mode
enum ImportMode: String, CaseIterable {
    case restore = "restore"
    case together = "together"
    
    var displayName: String {
        switch self {
        case .restore: return "Restore"
        case .together: return "Together"
        }
    }
    
    var description: String {
        switch self {
        case .restore: return "Restore and enhance a single photo"
        case .together: return "Create a together photo with two subjects"
        }
    }
    
    var maxPhotos: Int {
        switch self {
        case .restore: return 1
        case .together: return 2
        }
    }
    
    var icon: String {
        switch self {
        case .restore: return "photo.badge.plus"
        case .together: return "photo.stack"
        }
    }
}

// MARK: - Import Source
enum ImportSource: String, CaseIterable {
    case library = "library"
    case files = "files"
    
    var displayName: String {
        switch self {
        case .library: return "Library"
        case .files: return "Files"
        }
    }
    
    var icon: String {
        switch self {
        case .library: return "photo.on.rectangle"
        case .files: return "folder"
        }
    }
}

// MARK: - Import State
enum ImportState: Equatable {
    case idle
    case selecting
    case uploading
    case processing
    case completed(ProcessedPhoto?)
    case failed(Error)
    
    static func == (lhs: ImportState, rhs: ImportState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.selecting, .selecting), (.uploading, .uploading), (.processing, .processing):
            return true
        case (.completed(let lhsPhoto), .completed(let rhsPhoto)):
            return lhsPhoto?.id == rhsPhoto?.id
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

// MARK: - Import Progress
struct ImportProgress {
    let current: Int
    let total: Int
    let fileName: String?
    
    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }
    
    var isComplete: Bool {
        return current >= total
    }
}

// MARK: - Imported Photo
struct ImportedPhoto: Identifiable {
    let id = UUID()
    let image: UIImage
    let fileName: String?
    let fileSize: Int64?
    let source: ImportSource
    let importedAt: Date
}

// MARK: - Processed Photo
struct ProcessedPhoto: Identifiable {
    let id = UUID()
    let originalImage: UIImage
    let processedImage: UIImage
    let mode: ImportMode
    let processingSettings: ProcessingSettings
    let processedAt: Date
    let outputUrl: String
}

// MARK: - Processing Settings
struct ProcessingSettings {
    let qualityTarget: ImageProcessingQuality
    let outputFormat: ImageProcessingFormat
    let aspectRatio: AspectRatio
    let background: TogetherBackground?
    let lookControls: LookControls?
    let seed: Int?
    
    init(qualityTarget: ImageProcessingQuality = .standard, outputFormat: ImageProcessingFormat = .png, aspectRatio: AspectRatio = .original, background: TogetherBackground? = nil, lookControls: LookControls? = nil, seed: Int? = nil) {
        self.qualityTarget = qualityTarget
        self.outputFormat = outputFormat
        self.aspectRatio = aspectRatio
        self.background = background
        self.lookControls = lookControls
        self.seed = seed
    }
}

// MARK: - Import Configuration
struct ImportConfiguration {
    let mode: ImportMode
    let source: ImportSource
    let maxPhotos: Int
    let allowedTypes: [UTType]
    
    static func forMode(_ mode: ImportMode) -> ImportConfiguration {
        return ImportConfiguration(
            mode: mode,
            source: .library,
            maxPhotos: mode.maxPhotos,
            allowedTypes: [.image]
        )
    }
}
