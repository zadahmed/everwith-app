//
//  ImageProcessingService.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import Foundation
import UIKit
import Combine

class ImageProcessingService: ObservableObject {
    static let shared = ImageProcessingService()
    
    private let networkService: NetworkService
    private let sessionManager: SessionManager
    
    @Published var processingState: ImageProcessingState = .idle
    @Published var processingProgress: ImageProcessingProgress?
    
    private init() {
        self.networkService = NetworkService.shared
        self.sessionManager = SessionManager.shared
    }
    
    // MARK: - Image Upload
    
    func uploadImage(_ image: UIImage, fileName: String = "image.jpg") async throws -> String {
        print("📤 ImageProcessingService.uploadImage called")
        
        // Check if user is authenticated
        guard let token = UserDefaults.standard.string(forKey: "access_token") else {
            print("❌ No access token found! User needs to log in.")
            throw ImageProcessingError.networkError(NSError(domain: "Authentication", code: 401, userInfo: [NSLocalizedDescriptionKey: "Please log in to use this feature"]))
        }
        print("✅ Token found: \(token.prefix(20))...")
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to convert image to JPEG data")
            throw ImageProcessingError.invalidImage
        }
        
        print("📤 Image data size: \(imageData.count) bytes")
        
        let boundary = UUID().uuidString
        var body = Data()
        
        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Create upload request
        guard let url = URL(string: AppConfiguration.imageProcessingURL(for: AppConfiguration.ImageProcessingEndpoints.upload)) else {
            throw ImageProcessingError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header
        if let token = UserDefaults.standard.string(forKey: "access_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ImageProcessingError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw ImageProcessingError.httpError(httpResponse.statusCode)
            }
            
            let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: data)
            return uploadResponse.url
            
        } catch {
            throw ImageProcessingError.networkError(error)
        }
    }
    
    // MARK: - Restore Photo
    
    func restorePhoto(
        image: UIImage,
        qualityTarget: ImageProcessingQuality = .standard,
        outputFormat: ImageProcessingFormat = .png,
        aspectRatio: AspectRatio = .original,
        seed: Int? = nil
    ) async throws -> JobResult {
        
        print("🔄 ImageProcessingService.restorePhoto called")
        
        await MainActor.run {
            processingState = .uploading
            processingProgress = ImageProcessingProgress(
                currentStep: "Uploading image",
                totalSteps: 3,
                currentStepIndex: 0
            )
        }
        
        // Step 1: Upload image
        print("📤 Step 1: Uploading image...")
        let imageUrl = try await uploadImage(image)
        print("✅ Upload successful, got URL: \(imageUrl)")
        
        await MainActor.run {
            processingProgress = ImageProcessingProgress(
                currentStep: "Processing image",
                totalSteps: 3,
                currentStepIndex: 1
            )
        }
        
        // Step 2: Create restore request
        let restoreRequest = RestoreRequest(
            imageUrl: imageUrl,
            qualityTarget: qualityTarget,
            outputFormat: outputFormat,
            aspectRatio: aspectRatio,
            seed: seed
        )
        
        await MainActor.run {
            processingState = .processing
            processingProgress = ImageProcessingProgress(
                currentStep: "Restoring photo",
                totalSteps: 3,
                currentStepIndex: 2
            )
        }
        
        // Step 3: Call restore API
        print("🔄 Step 3: Calling restore API...")
        let result = try await callRestoreAPI(request: restoreRequest)
        print("✅ Restore API successful, got result: \(result)")
        
        await MainActor.run {
            processingState = .completed(result)
            processingProgress = ImageProcessingProgress(
                currentStep: "Complete",
                totalSteps: 3,
                currentStepIndex: 3
            )
        }
        
        return result
    }
    
    // MARK: - Together Photo
    
    func togetherPhoto(
        subjectA: UIImage,
        subjectB: UIImage,
        background: TogetherBackground,
        aspectRatio: AspectRatio = .fourFive,
        seed: Int? = nil,
        lookControls: LookControls? = nil
    ) async throws -> JobResult {
        
        await MainActor.run {
            processingState = .uploading
            processingProgress = ImageProcessingProgress(
                currentStep: "Uploading images",
                totalSteps: 4,
                currentStepIndex: 0
            )
        }
        
        // Step 1: Upload both images
        let subjectAUrl = try await uploadImage(subjectA, fileName: "subject_a.jpg")
        
        await MainActor.run {
            processingProgress = ImageProcessingProgress(
                currentStep: "Uploading second image",
                totalSteps: 4,
                currentStepIndex: 1
            )
        }
        
        let subjectBUrl = try await uploadImage(subjectB, fileName: "subject_b.jpg")
        
        await MainActor.run {
            processingState = .processing
            processingProgress = ImageProcessingProgress(
                currentStep: "Creating together photo",
                totalSteps: 4,
                currentStepIndex: 2
            )
        }
        
        // Step 2: Create together request
        let togetherRequest = TogetherRequest(
            subjectAUrl: subjectAUrl,
            subjectBUrl: subjectBUrl,
            background: background,
            aspectRatio: aspectRatio,
            seed: seed,
            lookControls: lookControls
        )
        
        await MainActor.run {
            processingProgress = ImageProcessingProgress(
                currentStep: "Processing together photo",
                totalSteps: 4,
                currentStepIndex: 3
            )
        }
        
        // Step 3: Call together API
        let result = try await callTogetherAPI(request: togetherRequest)
        
        await MainActor.run {
            processingState = .completed(result)
            processingProgress = ImageProcessingProgress(
                currentStep: "Complete",
                totalSteps: 4,
                currentStepIndex: 4
            )
        }
        
        return result
    }
    
    // MARK: - API Calls
    
    private func callRestoreAPI(request: RestoreRequest) async throws -> JobResult {
        print("🌐 callRestoreAPI called")
        
        guard let url = URL(string: AppConfiguration.imageProcessingURL(for: AppConfiguration.ImageProcessingEndpoints.restore)) else {
            print("❌ Invalid restore URL")
            throw ImageProcessingError.invalidURL
        }
        
        print("🌐 Calling restore API at: \(url)")
        let requestData = try JSONEncoder().encode(request)
        print("📤 Request data size: \(requestData.count) bytes")
        
        let result = try await networkService.makeAuthenticatedRequest(
            url: url,
            method: .POST,
            body: requestData,
            responseType: JobResult.self
        )
        
        print("✅ Restore API response received")
        return result
    }
    
    private func callTogetherAPI(request: TogetherRequest) async throws -> JobResult {
        guard let url = URL(string: AppConfiguration.imageProcessingURL(for: AppConfiguration.ImageProcessingEndpoints.together)) else {
            throw ImageProcessingError.invalidURL
        }
        
        let requestData = try JSONEncoder().encode(request)
        
        return try await networkService.makeAuthenticatedRequest(
            url: url,
            method: .POST,
            body: requestData,
            responseType: JobResult.self
        )
    }
    
    // MARK: - Download Processed Image
    
    func downloadProcessedImage(from url: String) async throws -> UIImage {
        guard let imageURL = URL(string: url) else {
            throw ImageProcessingError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: imageURL)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ImageProcessingError.downloadFailed
        }
        
        guard let image = UIImage(data: data) else {
            throw ImageProcessingError.invalidImage
        }
        
        return image
    }
    
    // MARK: - Image History
    
    func saveToHistory(
        imageType: String,
        originalImageUrl: String?,
        processedImageUrl: String,
        qualityTarget: String? = nil,
        outputFormat: String? = nil,
        aspectRatio: String? = nil,
        subjectAUrl: String? = nil,
        subjectBUrl: String? = nil,
        backgroundPrompt: String? = nil
    ) async throws -> ProcessedImage {
        print("💾 ImageProcessingService.saveToHistory called")
        
        guard let token = UserDefaults.standard.string(forKey: "access_token") else {
            throw ImageProcessingError.networkError(NSError(domain: "Authentication", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"]))
        }
        
        let imageData = ProcessedImageCreate(
            imageType: imageType,
            originalImageUrl: originalImageUrl,
            processedImageUrl: processedImageUrl,
            thumbnailUrl: nil,
            qualityTarget: qualityTarget,
            outputFormat: outputFormat,
            aspectRatio: aspectRatio,
            subjectAUrl: subjectAUrl,
            subjectBUrl: subjectBUrl,
            backgroundPrompt: backgroundPrompt,
            width: nil,
            height: nil,
            fileSize: nil
        )
        
        guard let url = URL(string: "\(AppConfiguration.API.baseURL)/images/save") else {
            throw ImageProcessingError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(imageData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ImageProcessingError.invalidResponse
        }
        
        
        let decoder = JSONDecoder()
        // Don't use .convertFromSnakeCase since we have manual CodingKeys that already handle snake_case
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let savedImage = try decoder.decode(ProcessedImage.self, from: data)
            print("✅ Image saved to history: \(savedImage.id)")
            return savedImage
        } catch {
            print("❌ Failed to decode save response: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("❌ Missing key '\(key.stringValue)' in response")
                    print("❌ Context: \(context)")
                case .typeMismatch(let type, let context):
                    print("❌ Type mismatch for type \(type)")
                    print("❌ Context: \(context)")
                case .valueNotFound(let type, let context):
                    print("❌ Value not found for type \(type)")
                    print("❌ Context: \(context)")
                case .dataCorrupted(let context):
                    print("❌ Data corrupted")
                    print("❌ Context: \(context)")
                @unknown default:
                    print("❌ Unknown decoding error: \(error)")
                }
            }
            throw error
        }
    }
    
    func fetchImageHistory(page: Int = 1, pageSize: Int = 20, imageType: String? = nil) async throws -> ImageHistoryResponse {
        print("📥 ImageProcessingService.fetchImageHistory called")
        
        guard let token = UserDefaults.standard.string(forKey: "access_token") else {
            throw ImageProcessingError.networkError(NSError(domain: "Authentication", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"]))
        }
        
        var urlString = "\(AppConfiguration.API.baseURL)/images/history?page=\(page)&page_size=\(pageSize)"
        if let type = imageType {
            urlString += "&image_type=\(type)"
        }
        
        guard let url = URL(string: urlString) else {
            throw ImageProcessingError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ImageProcessingError.invalidResponse
        }
        
        
        let decoder = JSONDecoder()
        // Don't use .convertFromSnakeCase since we have manual CodingKeys that already handle snake_case
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let history = try decoder.decode(ImageHistoryResponse.self, from: data)
            print("✅ Fetched \(history.images.count) images from history (page \(history.page) of total \(history.total))")
            
            // Debug: Check if images have valid data
            for (index, image) in history.images.enumerated() {
                print("🖼️ Image \(index + 1): Type=\(image.imageType ?? "nil"), URL=\(image.processedImageUrl != nil ? "valid" : "nil")")
            }
            
            return history
        } catch {
            print("❌ Failed to decode history response: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("❌ Missing key '\(key.stringValue)' in response")
                    print("❌ Context: \(context)")
                case .typeMismatch(let type, let context):
                    print("❌ Type mismatch for type \(type)")
                    print("❌ Context: \(context)")
                case .valueNotFound(let type, let context):
                    print("❌ Value not found for type \(type)")
                    print("❌ Context: \(context)")
                case .dataCorrupted(let context):
                    print("❌ Data corrupted")
                    print("❌ Context: \(context)")
                @unknown default:
                    print("❌ Unknown decoding error: \(error)")
                }
            }
            throw error
        }
    }
    
    func fetchImageStats() async throws -> ImageStats {
        print("📊 ImageProcessingService.fetchImageStats called")
        
        guard let token = UserDefaults.standard.string(forKey: "access_token") else {
            throw ImageProcessingError.networkError(NSError(domain: "Authentication", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"]))
        }
        
        guard let url = URL(string: "\(AppConfiguration.API.baseURL)/images/stats") else {
            throw ImageProcessingError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ImageProcessingError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        // Don't use .convertFromSnakeCase since we have manual CodingKeys that already handle snake_case
        decoder.dateDecodingStrategy = .iso8601
        let stats = try decoder.decode(ImageStats.self, from: data)
        
        print("✅ Fetched image stats: \(stats.totalImages) total")
        return stats
    }
    
    // MARK: - Reset State
    
    func resetState() {
        processingState = .idle
        processingProgress = nil
    }
}

// MARK: - Upload Response
struct UploadResponse: Codable {
    let url: String
}

// MARK: - Image Processing Error
enum ImageProcessingError: LocalizedError {
    case invalidImage
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case networkError(Error)
    case downloadFailed
    case processingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image data"
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .downloadFailed:
            return "Failed to download processed image"
        case .processingFailed(let message):
            return "Processing failed: \(message)"
        }
    }
}
