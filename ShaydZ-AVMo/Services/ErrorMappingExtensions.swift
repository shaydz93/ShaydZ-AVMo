import Foundation
import Combine

/// Extension to centralize common error mapping patterns
extension Publisher {
    /// Maps SupabaseError to APIError
    func mapSupabaseError() -> Publishers.MapError<Self, APIError> where Self.Failure == SupabaseError {
        return mapError { supabaseError in
            switch supabaseError {
            case .unauthorized:
                return APIError.unauthorized
            case .networkError:
                return APIError.networkError
            default:
                return APIError.badRequest(supabaseError.localizedDescription)
            }
        }
    }
    
    /// Generic error mapping with custom transformation
    func mapToAPIError<E: Error>(_ transform: @escaping (E) -> APIError) -> Publishers.MapError<Self, APIError> where Self.Failure == E {
        return mapError(transform)
    }
}

/// Common error handling utility
struct ErrorHandler {
    /// Standard error mapping for service responses
    static func handleServiceError<T>(_ error: Error) -> APIError {
        if let apiError = error as? APIError {
            return apiError
        } else if let supabaseError = error as? SupabaseError {
            switch supabaseError {
            case .unauthorized:
                return .unauthorized
            case .networkError:
                return .networkError
            default:
                return .badRequest(supabaseError.localizedDescription)
            }
        } else {
            return .badRequest(error.localizedDescription)
        }
    }
}
