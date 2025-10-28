//
//  NetworkService.swift
//  EverWith
//
//  Created by Zahid Ahmed on 04/10/2025.
//

import Foundation
import Combine

class NetworkService: ObservableObject {
    static let shared = NetworkService()
    
    private let authService: AuthenticationService
    private let sessionManager: SessionManager
    
    private init() {
        self.authService = AuthenticationService()
        self.sessionManager = SessionManager.shared
    }
    
    // MARK: - Flexible Date Decoder
    private func createFlexibleDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try multiple date formats
            let formatters = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",  // 2025-10-11T23:19:17.783000
                "yyyy-MM-dd'T'HH:mm:ss.SSS",      // 2025-10-11T23:19:17.783
                "yyyy-MM-dd'T'HH:mm:ss",          // 2025-10-11T23:19:17
                "yyyy-MM-dd'T'HH:mm:ssZ",         // 2025-10-11T23:19:17Z
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ"      // 2025-10-11T23:19:17.783Z
            ]
            
            for formatter in formatters {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = formatter
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
            }
            
            // Fallback to ISO8601
            let iso8601Formatter = ISO8601DateFormatter()
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
        }
        return decoder
    }
    
    func makeAuthenticatedRequest<T: Codable>(
        url: URL,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        
        // Don't pre-validate session - let the backend handle it
        // This avoids unnecessary /api/auth/me calls before every request
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header if token exists
        if let token = UserDefaults.standard.string(forKey: "access_token") {
            print("🔑 Using token: \(token.prefix(20))...")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            print("⚠️ No access token found!")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            // Handle session expiration from server
            if httpResponse.statusCode == 401 {
                await authService.signOut()
                throw NetworkError.sessionExpired
            }
            
            // Handle error responses (400, 500, etc.)
            guard httpResponse.statusCode == 200 else {
                // Try to extract error message from response body
                var errorMessage: String?
                if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
                   let detail = errorData["detail"] {
                    errorMessage = detail
                    
                    // Check for content moderation specifically
                    if detail.contains("Content Moderated") || detail.contains("Request Moderated") || detail.contains("flagged by moderation") {
                        throw NetworkError.contentModerated(detail)
                    }
                }
                
                // Throw with extracted message if available
                if let message = errorMessage {
                    throw NetworkError.httpErrorWithMessage(statusCode: httpResponse.statusCode, message: message)
                } else {
                    throw NetworkError.httpError(httpResponse.statusCode)
                }
            }
            
            let decodedResponse = try createFlexibleDecoder().decode(responseType, from: data)
            return decodedResponse
            
        } catch {
            if error is NetworkError {
                throw error
            } else {
                throw NetworkError.networkError(error)
            }
        }
    }
    
    func makeRequest<T: Codable>(
        url: URL,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = body
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw NetworkError.httpError(httpResponse.statusCode)
            }
            
            let decodedResponse = try createFlexibleDecoder().decode(responseType, from: data)
            return decodedResponse
            
        } catch {
            if error is NetworkError {
                throw error
            } else {
                throw NetworkError.networkError(error)
            }
        }
    }
}

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

enum NetworkError: LocalizedError {
    case sessionExpired
    case invalidResponse
    case httpError(Int)
    case httpErrorWithMessage(statusCode: Int, message: String)
    case networkError(Error)
    case decodingError(Error)
    case contentModerated(String)
    
    var errorDescription: String? {
        switch self {
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .httpErrorWithMessage(let statusCode, let message):
            return message
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .contentModerated(let message):
            return message
        }
    }
}
