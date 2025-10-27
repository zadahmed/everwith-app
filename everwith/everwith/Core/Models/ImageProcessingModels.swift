//
//  ImageProcessingModels.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import Foundation

// MARK: - Image Processing Quality
enum ImageProcessingQuality: String, CaseIterable, Codable {
    case standard = "standard"
    case premium = "premium"
    
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .premium: return "Premium"
        }
    }
    
    var description: String {
        switch self {
        case .standard: return "Good quality, faster processing"
        case .premium: return "High quality, slower processing"
        }
    }
}

// MARK: - Image Processing Format
enum ImageProcessingFormat: String, CaseIterable, Codable {
    case png = "png"
    case webp = "webp"
    case jpg = "jpg"
    
    var displayName: String {
        switch self {
        case .png: return "PNG"
        case .webp: return "WebP"
        case .jpg: return "JPEG"
        }
    }
    
    var fileExtension: String {
        return rawValue
    }
}

// MARK: - Aspect Ratio
enum AspectRatio: String, CaseIterable, Codable {
    case original = "original"
    case fourFive = "4:5"
    case oneOne = "1:1"
    case sixteenNine = "16:9"
    
    var displayName: String {
        switch self {
        case .original: return "Original"
        case .fourFive: return "4:5"
        case .oneOne: return "1:1"
        case .sixteenNine: return "16:9"
        }
    }
    
    var description: String {
        switch self {
        case .original: return "Keep original aspect ratio"
        case .fourFive: return "Portrait (4:5)"
        case .oneOne: return "Square (1:1)"
        case .sixteenNine: return "Landscape (16:9)"
        }
    }
}

// MARK: - Background Mode
enum BackgroundMode: String, CaseIterable, Codable {
    case gallery = "gallery"
    case generate = "generate"
    
    var displayName: String {
        switch self {
        case .gallery: return "Gallery"
        case .generate: return "Generate"
        }
    }
    
    var description: String {
        switch self {
        case .gallery: return "Select from predefined backgrounds"
        case .generate: return "Generate custom background"
        }
    }
}

// MARK: - Look Controls
struct LookControls: Codable {
    let warmth: Double
    let shadows: Double
    let grain: Double
    
    init(warmth: Double = 0.0, shadows: Double = 0.0, grain: Double = 0.0) {
        self.warmth = max(-1.0, min(1.0, warmth))
        self.shadows = max(0.0, min(1.0, shadows))
        self.grain = max(0.0, min(1.0, grain))
    }
}

// MARK: - Together Background
struct TogetherBackground: Codable {
    let mode: BackgroundMode
    let sceneId: String?
    let prompt: String?
    let useUltra: Bool
    
    enum CodingKeys: String, CodingKey {
        case mode
        case sceneId = "scene_id"
        case prompt
        case useUltra = "use_ultra"
    }
    
    init(mode: BackgroundMode, sceneId: String? = nil, prompt: String? = nil, useUltra: Bool = false) {
        self.mode = mode
        self.sceneId = sceneId
        self.prompt = prompt
        self.useUltra = useUltra
    }
}

// MARK: - Restore Request
struct RestoreRequest: Codable {
    let imageUrl: String
    let qualityTarget: ImageProcessingQuality
    let outputFormat: ImageProcessingFormat
    let aspectRatio: AspectRatio
    let seed: Int?
    
    enum CodingKeys: String, CodingKey {
        case imageUrl = "image_url"
        case qualityTarget = "quality_target"
        case outputFormat = "output_format"
        case aspectRatio = "aspect_ratio"
        case seed
    }
    
    init(imageUrl: String, qualityTarget: ImageProcessingQuality = .standard, outputFormat: ImageProcessingFormat = .png, aspectRatio: AspectRatio = .original, seed: Int? = nil) {
        self.imageUrl = imageUrl
        self.qualityTarget = qualityTarget
        self.outputFormat = outputFormat
        self.aspectRatio = aspectRatio
        self.seed = seed
    }
}

// MARK: - Together Request
struct TogetherRequest: Codable {
    let subjectAUrl: String
    let subjectBUrl: String
    let subjectAMaskUrl: String?
    let subjectBMaskUrl: String?
    let background: TogetherBackground
    let aspectRatio: AspectRatio
    let seed: Int?
    let lookControls: LookControls?
    
    enum CodingKeys: String, CodingKey {
        case subjectAUrl = "subject_a_url"
        case subjectBUrl = "subject_b_url"
        case subjectAMaskUrl = "subject_a_mask_url"
        case subjectBMaskUrl = "subject_b_mask_url"
        case background
        case aspectRatio = "aspect_ratio"
        case seed
        case lookControls = "look_controls"
    }
    
    init(subjectAUrl: String, subjectBUrl: String, subjectAMaskUrl: String? = nil, subjectBMaskUrl: String? = nil, background: TogetherBackground, aspectRatio: AspectRatio = .fourFive, seed: Int? = nil, lookControls: LookControls? = nil) {
        self.subjectAUrl = subjectAUrl
        self.subjectBUrl = subjectBUrl
        self.subjectAMaskUrl = subjectAMaskUrl
        self.subjectBMaskUrl = subjectBMaskUrl
        self.background = background
        self.aspectRatio = aspectRatio
        self.seed = seed
        self.lookControls = lookControls
    }
}

// MARK: - Timeline Request
struct TimelineRequest: Codable {
    let imageUrl: String
    let targetAge: TimelineAge
    let qualityTarget: ImageProcessingQuality
    let outputFormat: ImageProcessingFormat
    let aspectRatio: AspectRatio
    let seed: Int?
    
    enum CodingKeys: String, CodingKey {
        case imageUrl = "image_url"
        case targetAge = "target_age"
        case qualityTarget = "quality_target"
        case outputFormat = "output_format"
        case aspectRatio = "aspect_ratio"
        case seed
    }
}

// MARK: - Celebrity Request
struct CelebrityRequest: Codable {
    let imageUrl: String
    let celebrityStyle: CelebrityStyle
    let qualityTarget: ImageProcessingQuality
    let outputFormat: ImageProcessingFormat
    let aspectRatio: AspectRatio
    let seed: Int?
    
    enum CodingKeys: String, CodingKey {
        case imageUrl = "image_url"
        case celebrityStyle = "celebrity_style"
        case qualityTarget = "quality_target"
        case outputFormat = "output_format"
        case aspectRatio = "aspect_ratio"
        case seed
    }
}

// MARK: - Reunite Request
struct ReuniteRequest: Codable {
    let imageAUrl: String
    let imageBUrl: String
    let backgroundPrompt: String?
    let qualityTarget: ImageProcessingQuality
    let outputFormat: ImageProcessingFormat
    let aspectRatio: AspectRatio
    let seed: Int?
    
    enum CodingKeys: String, CodingKey {
        case imageAUrl = "image_a_url"
        case imageBUrl = "image_b_url"
        case backgroundPrompt = "background_prompt"
        case qualityTarget = "quality_target"
        case outputFormat = "output_format"
        case aspectRatio = "aspect_ratio"
        case seed
    }
}

// MARK: - Family Request
struct FamilyRequest: Codable {
    let images: [String]
    let style: FamilyStyle
    let qualityTarget: ImageProcessingQuality
    let outputFormat: ImageProcessingFormat
    let aspectRatio: AspectRatio
    let seed: Int?
    
    enum CodingKeys: String, CodingKey {
        case images
        case style
        case qualityTarget = "quality_target"
        case outputFormat = "output_format"
        case aspectRatio = "aspect_ratio"
        case seed
    }
}

// MARK: - Timeline Age
enum TimelineAge: String, CaseIterable, Codable {
    case young = "young"
    case current = "current"
    case old = "old"
    
    var displayName: String {
        switch self {
        case .young: return "Young"
        case .current: return "Current"
        case .old: return "Elder"
        }
    }
}

// MARK: - Celebrity Style
enum CelebrityStyle: String, CaseIterable, Codable {
    case movieStar = "movie_star"
    case royal = "royal"
    case vintageGlamour = "vintage_glamour"
    case modernCelebrity = "modern_celebrity"
    
    var displayName: String {
        switch self {
        case .movieStar: return "Movie Star"
        case .royal: return "Royal"
        case .vintageGlamour: return "Vintage Glamour"
        case .modernCelebrity: return "Modern Celebrity"
        }
    }
}

// MARK: - Family Style
enum FamilyStyle: String, CaseIterable, Codable {
    case collage = "collage"
    case composite = "composite"
    case enhanced = "enhanced"
    
    var displayName: String {
        switch self {
        case .collage: return "Collage"
        case .composite: return "Composite"
        case .enhanced: return "Enhanced"
        }
    }
}

// MARK: - Job Result
struct JobResult: Codable {
    let outputUrl: String
    let meta: [String: String] // Simplified to avoid AnyCodable issues
    
    enum CodingKeys: String, CodingKey {
        case outputUrl = "output_url"
        case meta
    }
}


// MARK: - Image Processing State
enum ImageProcessingState: Equatable {
    case idle
    case uploading
    case processing
    case completed(JobResult)
    case failed(Error)
    
    static func == (lhs: ImageProcessingState, rhs: ImageProcessingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.uploading, .uploading), (.processing, .processing):
            return true
        case (.completed(let lhsResult), .completed(let rhsResult)):
            return lhsResult.outputUrl == rhsResult.outputUrl
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

// MARK: - Image Processing Progress
struct ImageProcessingProgress: Equatable {
    let currentStep: String
    let totalSteps: Int
    let currentStepIndex: Int
    
    var percentage: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(currentStepIndex) / Double(totalSteps)
    }
    
    var isComplete: Bool {
        return currentStepIndex >= totalSteps
    }
}
