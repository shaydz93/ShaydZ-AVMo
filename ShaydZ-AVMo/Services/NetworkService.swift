import Foundation
import Combine

/// Base URL for API endpoints
struct APIConfig {
    #if DEBUG
    static let baseURL = "http://localhost:8080/api"
    #else
    static let baseURL = "https://api.shaydz-avmo.com/api"
    #endif
    
    static let authEndpoint = "\(baseURL)/auth"
    static let vmEndpoint = "\(baseURL)/vm"
    static let appsEndpoint = "\(baseURL)/apps"
}

/// Generic API errors
enum APIError: Error {
    case invalidURL
    case networkError
    case decodingError
    case serverError(Int)
    case unauthorized
    case unknown
    case badRequest(String)
    
    var message: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError:
            return "Network connection failed"
        case .decodingError:
            return "Failed to decode response"
        case .serverError(let code):
            return "Server error: \(code)"
        case .unauthorized:
            return "Authentication required"
        case .unknown:
            return "An unknown error occurred"
        case .badRequest(let message):
            return message
        }
    }
}

/// Base NetworkService for API requests
class NetworkService {
    static let shared = NetworkService()
    private let session = URLSession.shared
    
    private init() {}
    
    /// Get stored auth token
    func getAuthToken() -> String? {
        return UserDefaults.standard.string(forKey: "authToken")
    }
    
    /// Save auth token
    func saveAuthToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: "authToken")
    }
    
    /// Clear auth token
    func clearAuthToken() {
        UserDefaults.standard.removeObject(forKey: "authToken")
    }
    
    /// Generic request function
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        requiresAuth: Bool = true
    ) -> AnyPublisher<T, APIError> {
        guard let url = URL(string: endpoint) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header if required
        if requiresAuth, let token = getAuthToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add body if provided
        if let body = body {
            request.httpBody = body
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.unknown
                }
                
                switch httpResponse.statusCode {
                case 200..<300:
                    return data
                case 401:
                    throw APIError.unauthorized
                case 400:
                    // Try to extract error message if available
                    if let errorObj = try? JSONDecoder().decode([String: String].self, from: data),
                       let message = errorObj["message"] {
                        throw APIError.badRequest(message)
                    }
                    throw APIError.badRequest("Bad request")
                default:
                    throw APIError.serverError(httpResponse.statusCode)
                }
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else if error is DecodingError {
                    return .decodingError
                } else {
                    return .unknown
                }
            }
            .eraseToAnyPublisher()
    }
}
