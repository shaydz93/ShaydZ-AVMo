import Foundation
import Combine

/// Service for network operations
class NetworkService {
    static let shared = NetworkService()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let tokenKey = "auth_token"
    
    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    /// Get data from a URL
    func get<T: Decodable>(_ type: T.Type, from url: URL) -> AnyPublisher<T, APIError> {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add auth token if available
        if let token = getAuthToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 401:
                    throw APIError.unauthorized
                case 400:
                    throw APIError.badRequest("Bad request")
                case 404:
                    throw APIError.badRequest("Resource not found")
                case 500...599:
                    throw APIError.serverError
                default:
                    throw APIError.unknown("Unexpected status code: \(httpResponse.statusCode)")
                }
            }
            .decode(type: T.self, decoder: decoder)
            .mapError { error -> APIError in
                if let apiError = error as? APIError {
                    return apiError
                } else if error is DecodingError {
                    return APIError.decodingError
                } else {
                    return APIError.networkError
                }
            }
            .eraseToAnyPublisher()
    }
    
    /// Post data to a URL
    func post<T: Decodable, E: Encodable>(_ type: T.Type, to url: URL, body: E) -> AnyPublisher<T, APIError> {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token if available
        if let token = getAuthToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(body)
        } catch {
            return Fail(error: APIError.encodingError).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 401:
                    throw APIError.unauthorized
                case 400:
                    throw APIError.badRequest("Bad request")
                case 404:
                    throw APIError.badRequest("Resource not found")
                case 500...599:
                    throw APIError.serverError
                default:
                    throw APIError.unknown("Unexpected status code: \(httpResponse.statusCode)")
                }
            }
            .decode(type: T.self, decoder: decoder)
            .mapError { error -> APIError in
                if let apiError = error as? APIError {
                    return apiError
                } else if error is DecodingError {
                    return APIError.decodingError
                } else {
                    return APIError.networkError
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Auth Token Management
    
    /// Save authentication token
    func saveAuthToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }
    
    /// Get the saved authentication token
    func getAuthToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    /// Clear the saved authentication token
    func clearAuthToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }
}
