//
//  ShareVerificationService.swift
//  EverWith
//
//  Created by Zahid Ahmed on 19/11/2025.
//

import Foundation
import Combine

@MainActor
final class ShareVerificationService: ObservableObject {
    static let shared = ShareVerificationService()
    
    @Published var isVerifying: Bool = false
    @Published var lastResponse: ShareVerificationResponseModel?
    
    private let networkService = NetworkService.shared
    
    private init() {}
    
    func verifyShare(payload: ShareVerificationPayload) async throws -> ShareVerificationResponseModel {
        guard let url = URL(string: "\(AppConfiguration.API.baseURL)/api/share/verify") else {
            throw NetworkError.invalidResponse
        }
        
        let bodyData = try JSONEncoder().encode(payload)
        
        isVerifying = true
        defer { isVerifying = false }
        
        let response: ShareVerificationResponseModel = try await networkService.makeAuthenticatedRequest(
            url: url,
            method: .POST,
            body: bodyData,
            responseType: ShareVerificationResponseModel.self
        )
        
        lastResponse = response
        return response
    }
}

