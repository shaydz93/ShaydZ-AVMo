import Foundation

// Single, centralized declaration of APIError
public enum ShaydZ_APIError: Error, Equatable {
    case networkError(String)
    case invalidResponse
    case serverError(Int)
    case decodingError(String)
    case encodingError(String)
    case noData
    case unauthorized
    case notFound
    case unknown(String)
    
    public static func == (lhs: ShaydZ_APIError, rhs: ShaydZ_APIError) -> Bool {
        switch (lhs, rhs) {
        case (.networkError, .networkError),
             (.invalidResponse, .invalidResponse),
             (.serverError, .serverError),
             (.decodingError, .decodingError),
             (.encodingError, .encodingError),
             (.noData, .noData),
             (.unauthorized, .unauthorized),
             (.notFound, .notFound),
             (.unknown, .unknown):
            return true
        default:
            return false
        }
    }
    
    public var localizedDescription: String {
        switch self {
        case .networkError(let error): return "Network error: \(error)"
        case .invalidResponse: return "Invalid response from the server"
        case .serverError(let code): return "Server error with code \(code)"
        case .decodingError(let error): return "Data decoding error: \(error)"
        case .encodingError(let error): return "Data encoding error: \(error)"
        case .noData: return "No data received from the server"
        case .unauthorized: return "Authentication required"
        case .notFound: return "Resource not found"
        case .unknown(let message): return "Unknown error: \(message)"
        }
    }
    
    // Helper to convert Swift Error to our APIError type
    public static func from(_ error: Error) -> ShaydZ_APIError {
        if let apiError = error as? ShaydZ_APIError {
            return apiError
        } else {
            return .networkError(error.localizedDescription)
        }
    }
}

// Type alias for backward compatibility
public typealias APIError = ShaydZ_APIError
