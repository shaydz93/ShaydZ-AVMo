import Foundation
import Combine

/// Centralized network service for API communications
public class ShaydZ_NetworkService: ObservableObject {
    public static let shared = ShaydZ_NetworkService()
    
    private let session: URLSession
    private let tokenKey = "authToken"
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        self.session = URLSession(configuration: config)
    }
    
    /// Save authentication token
    public func saveAuthToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }
    
    /// Get authentication token
    public func getAuthToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    /// Clear authentication token
    public func clearAuthToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }
    
    /// Generic request function
    public func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        requiresAuth: Bool = true
    ) -> AnyPublisher<T, ShaydZ_APIError> {
        guard let url = URL(string: endpoint) else {
            return Fail(error: ShaydZ_APIError.invalidResponse).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication if required
        if requiresAuth, let token = getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw ShaydZ_APIError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 400:
                    throw ShaydZ_APIError.badRequest
                case 401:
                    throw ShaydZ_APIError.unauthorized
                case 404:
                    throw ShaydZ_APIError.notFound
                default:
                    throw ShaydZ_APIError.serverError(httpResponse.statusCode)
                }
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                if let apiError = error as? ShaydZ_APIError {
                    return apiError
                } else if error is DecodingError {
                    return ShaydZ_APIError.decodingError(error.localizedDescription)
                } else {
                    return ShaydZ_APIError.networkError(error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
    
    /// GET request helper
    public func get<T: Decodable>(
        _ type: T.Type,
        from endpoint: String,
        requiresAuth: Bool = true
    ) -> AnyPublisher<T, ShaydZ_APIError> {
        return request(endpoint: endpoint, method: "GET", requiresAuth: requiresAuth)
    }
    
    /// POST request helper
    public func post<T: Decodable>(
        _ type: T.Type,
        to endpoint: String,
        body: Data? = nil,
        requiresAuth: Bool = true
    ) -> AnyPublisher<T, ShaydZ_APIError> {
        return request(endpoint: endpoint, method: "POST", body: body, requiresAuth: requiresAuth)
    }
    
    /// PUT request helper
    public func put<T: Decodable>(
        _ type: T.Type,
        to endpoint: String,
        body: Data? = nil,
        requiresAuth: Bool = true
    ) -> AnyPublisher<T, ShaydZ_APIError> {
        return request(endpoint: endpoint, method: "PUT", body: body, requiresAuth: requiresAuth)
    }
    
    /// DELETE request helper
    public func delete<T: Decodable>(
        _ type: T.Type,
        from endpoint: String,
        requiresAuth: Bool = true
    ) -> AnyPublisher<T, ShaydZ_APIError> {
        return request(endpoint: endpoint, method: "DELETE", requiresAuth: requiresAuth)
    }
}

// Type alias for backward compatibility
public typealias NetworkService = ShaydZ_NetworkService
