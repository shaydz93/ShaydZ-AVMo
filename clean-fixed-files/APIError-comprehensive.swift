import Foundation

/// Central error handling for ShaydZ AVMo
/// This is the single source of truth for all API and application errors
public enum ShaydZAVMo_APIError: Error, Equatable, CaseIterable {
    case networkUnavailable
    case invalidCredentials
    case sessionExpired
    case serverError
    case badRequest
    case unauthorized
    case forbidden
    case notFound
    case timeout
    case invalidResponse
    case decodingError
    case encodingError
    case vmNotFound
    case vmCreationFailed
    case vmConnectionFailed
    case vmOperationFailed
    case authenticationFailed
    case registrationFailed
    case passwordResetFailed
    case appCatalogUnavailable
    case appInstallationFailed
    case appLaunchFailed
    case supabaseConnectionFailed
    case databaseError
    case configurationError
    case securityViolation
    case insufficientPermissions
    case rateLimited
    case maintenanceMode
    case featureUnavailable
    case unknown(String)
    
    public var localizedDescription: String {
        switch self {
        case .networkUnavailable:
            return "Network connection is unavailable"
        case .invalidCredentials:
            return "Invalid username or password"
        case .sessionExpired:
            return "Your session has expired. Please sign in again"
        case .serverError:
            return "Server error occurred. Please try again later"
        case .badRequest:
            return "Invalid request. Please check your input"
        case .unauthorized:
            return "You are not authorized to perform this action"
        case .forbidden:
            return "Access to this resource is forbidden"
        case .notFound:
            return "The requested resource was not found"
        case .timeout:
            return "Request timed out. Please try again"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to decode server response"
        case .encodingError:
            return "Failed to encode request data"
        case .vmNotFound:
            return "Virtual machine not found"
        case .vmCreationFailed:
            return "Failed to create virtual machine"
        case .vmConnectionFailed:
            return "Failed to connect to virtual machine"
        case .vmOperationFailed:
            return "Virtual machine operation failed"
        case .authenticationFailed:
            return "Authentication failed"
        case .registrationFailed:
            return "User registration failed"
        case .passwordResetFailed:
            return "Password reset failed"
        case .appCatalogUnavailable:
            return "App catalog is currently unavailable"
        case .appInstallationFailed:
            return "Failed to install application"
        case .appLaunchFailed:
            return "Failed to launch application"
        case .supabaseConnectionFailed:
            return "Failed to connect to Supabase"
        case .databaseError:
            return "Database operation failed"
        case .configurationError:
            return "Configuration error"
        case .securityViolation:
            return "Security violation detected"
        case .insufficientPermissions:
            return "Insufficient permissions"
        case .rateLimited:
            return "Too many requests. Please try again later"
        case .maintenanceMode:
            return "Service is under maintenance"
        case .featureUnavailable:
            return "This feature is currently unavailable"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    public var errorCode: Int {
        switch self {
        case .networkUnavailable: return 1001
        case .invalidCredentials: return 1002
        case .sessionExpired: return 1003
        case .serverError: return 1004
        case .badRequest: return 1005
        case .unauthorized: return 1006
        case .forbidden: return 1007
        case .notFound: return 1008
        case .timeout: return 1009
        case .invalidResponse: return 1010
        case .decodingError: return 1011
        case .encodingError: return 1012
        case .vmNotFound: return 2001
        case .vmCreationFailed: return 2002
        case .vmConnectionFailed: return 2003
        case .vmOperationFailed: return 2004
        case .authenticationFailed: return 3001
        case .registrationFailed: return 3002
        case .passwordResetFailed: return 3003
        case .appCatalogUnavailable: return 4001
        case .appInstallationFailed: return 4002
        case .appLaunchFailed: return 4003
        case .supabaseConnectionFailed: return 5001
        case .databaseError: return 5002
        case .configurationError: return 6001
        case .securityViolation: return 7001
        case .insufficientPermissions: return 7002
        case .rateLimited: return 8001
        case .maintenanceMode: return 8002
        case .featureUnavailable: return 8003
        case .unknown: return 9999
        }
    }
}

// Type aliases for backward compatibility
public typealias APIError = ShaydZAVMo_APIError
public typealias ShaydZ_APIError = ShaydZAVMo_APIError
