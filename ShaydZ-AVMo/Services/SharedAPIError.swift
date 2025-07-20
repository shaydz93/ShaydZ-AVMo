import Foundation

// Shared API Error definition for the entire app
enum APIError: Error, LocalizedError {
    case networkError
    case invalidResponse
    case unauthorized
    case serverError
    case badRequest(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection error"
        case .invalidResponse:
            return "Invalid server response"
        case .unauthorized:
            return "Unauthorized access"
        case .serverError:
            return "Server error"
        case .badRequest(let message):
            return "Bad request: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}

// Type alias for compatibility with AppCatalogService
typealias AppCatalogAPIError = APIError
