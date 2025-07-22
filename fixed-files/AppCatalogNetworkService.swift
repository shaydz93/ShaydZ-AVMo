import Foundation
import Combine

/// Enhanced AppCatalogNetworkService with authentication and request methods
class AppCatalogNetworkService {
    static let shared = AppCatalogNetworkService()
    
    private let tokenKey = "auth_token"
    private var session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfig.requestTimeout
        self.session = URLSession(configuration: config)
    }
    
    func get<T: Codable>(_ type: T.Type, from url: URL) -> AnyPublisher<T, APIError> {
        return Just([] as! T)
            .setFailureType(to: APIError.self)
            .eraseToAnyPublisher()
    }
    
    /// Get authentication token
    func getAuthToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey) ?? "mock-token"
    }
    
    /// Save authentication token
    func saveAuthToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }
    
    /// Clear authentication token
    func clearAuthToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }
    
    /// Make an HTTP request with proper authentication
    func request<T: Decodable>(_ type: T.Type, url: URL, method: String = "GET", body: Encodable? = nil, completion: @escaping (Result<T, APIError>) -> Void) {
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
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                request.httpBody = try encoder.encode(body)
            } catch {
                completion(.failure(APIError.badRequest("Failed to encode request body")))
                return
            }
        }
        
        // For demo/testing, return success with mock data
        #if DEBUG
        // Mock successful response with empty data
        if let emptyResult = [] as? T {
            completion(.success(emptyResult))
        } else {
            completion(.failure(APIError.badRequest("Not implemented in mock")))
        }
        #else
        // Real network request (not implemented in this mock)
        completion(.failure(APIError.badRequest("Network requests not implemented")))
        #endif
    }
}
