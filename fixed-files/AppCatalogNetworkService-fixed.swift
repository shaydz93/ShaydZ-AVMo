import Foundation
import Combine

/// Enhanced AppCatalogNetworkService with authentication and request methods
/// Renamed to avoid conflict with existing class
public class ShaydZ_AppCatalogNetworkService {
    public static let shared = ShaydZ_AppCatalogNetworkService()
    
    private let tokenKey = "auth_token"
    private var session: URLSession
    
    public init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfig.requestTimeout
        self.session = URLSession(configuration: config)
    }
    
    public func get<T: Codable>(_ type: T.Type, from url: URL) -> AnyPublisher<T, APIError> {
        return Just([] as! T)
            .setFailureType(to: APIError.self)
            .eraseToAnyPublisher()
    }
    
    /// Get authentication token
    public func getAuthToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey) ?? "mock-token"
    }
    
    /// Save authentication token
    public func saveAuthToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }
    
    /// Clear authentication token
    public func clearAuthToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }
    
    /// Make an HTTP request with proper authentication
    public func request<T: Decodable>(_ type: T.Type, url: URL, method: String = "GET", body: Encodable? = nil, completion: @escaping (Result<T, APIError>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication if we have a token
        if let token = getAuthToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add body data for POST/PUT requests
        if let body = body, method != "GET" {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                completion(.failure(.encodingError(error)))
                return
            }
        }
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(.serverError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            do {
                let decodedObject = try JSONDecoder().decode(type, from: data)
                completion(.success(decodedObject))
            } catch {
                completion(.failure(.decodingError(error)))
            }
        }.resume()
    }
}

// Type alias for backward compatibility
public typealias AppCatalogNetworkService = ShaydZ_AppCatalogNetworkService

// Make sure APIConfig and APIError are defined
public struct APIConfig {
    public static let requestTimeout: TimeInterval = 30.0
    public static let baseURL = URL(string: "https://api.shaydz-avmo.io")!
}

public enum APIError: Error {
    case networkError(Error)
    case invalidResponse
    case serverError(Int)
    case decodingError(Error)
    case encodingError(Error)
    case noData
    case unauthorized
    case notFound
    
    public var localizedDescription: String {
        switch self {
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .invalidResponse: return "Invalid response from the server"
        case .serverError(let code): return "Server error with code \(code)"
        case .decodingError(let error): return "Data decoding error: \(error.localizedDescription)"
        case .encodingError(let error): return "Data encoding error: \(error.localizedDescription)"
        case .noData: return "No data received from the server"
        case .unauthorized: return "Authentication required"
        case .notFound: return "Resource not found"
        }
    }
}
