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
