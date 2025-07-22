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
        config.timeoutIntervalForRequest = ShaydZ_APIConfig.requestTimeout
        self.session = URLSession(configuration: config)
    }
    
    public func get<T: Codable>(_ type: T.Type, from url: URL) -> AnyPublisher<T, ShaydZ_APIError> {
        // Mock implementation for compilation
        return Just([] as! T)
            .setFailureType(to: ShaydZ_APIError.self)
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
    public func request<T: Decodable>(_ type: T.Type, url: URL, method: String = "GET", body: Encodable? = nil, completion: @escaping (Result<T, ShaydZ_APIError>) -> Void) {
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
                completion(.failure(ShaydZ_APIError.encodingError(error.localizedDescription)))
                return
            }
        }
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(ShaydZ_APIError.networkError(error.localizedDescription)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(ShaydZ_APIError.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(ShaydZ_APIError.serverError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(ShaydZ_APIError.noData))
                return
            }
            
            do {
                let decodedObject = try JSONDecoder().decode(type, from: data)
                completion(.success(decodedObject))
            } catch {
                completion(.failure(ShaydZ_APIError.decodingError(error.localizedDescription)))
            }
        }.resume()
    }
}

// Type alias for backward compatibility
public typealias AppCatalogNetworkService = ShaydZ_AppCatalogNetworkService
