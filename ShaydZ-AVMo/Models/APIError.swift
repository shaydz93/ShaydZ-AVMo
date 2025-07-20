//
//  APIError.swift
//  ShaydZ-AVMo
//
//  Created by ShaydZ AVMo
//

import Foundation

/// Shared API error types used across all services
enum APIError: Error, LocalizedError {
    case networkError
    case invalidResponse
    case unauthorized
    case serverError
    case badRequest(String)
    case unknown(String)
    case invalidURL
    case decodingError
    case encodingError
    case noData
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection failed"
        case .invalidResponse:
            return "Invalid server response"
        case .unauthorized:
            return "Authentication required"
        case .serverError:
            return "Server error occurred"
        case .badRequest(let message):
            return "Bad request: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        case .invalidURL:
            return "Invalid URL"
        case .decodingError:
            return "Failed to decode response"
        case .encodingError:
            return "Failed to encode request"
        case .noData:
            return "No data received"
        }
    }
}
