import Foundation
import Combine

/// Supabase network service for API interactions
class SupabaseNetworkService {
    static let shared = SupabaseNetworkService()
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    /// Current access token
    private var currentToken: String?
    
    private init() {}
    
    // MARK: - Token Management
    
    /// Save authentication token
    func saveAuthToken(_ token: String) {
        currentToken = token
        UserDefaults.standard.set(token, forKey: "supabase_access_token")
    }
    
    /// Get stored authentication token
    func getAuthToken() -> String? {
        if let token = currentToken {
            return token
        }
        let token = UserDefaults.standard.string(forKey: "supabase_access_token")
        currentToken = token
        return token
    }
    
    /// Clear authentication token
    func clearAuthToken() {
        currentToken = nil
        UserDefaults.standard.removeObject(forKey: "supabase_access_token")
    }
    
    // MARK: - Generic Request Method
    
    /// Generic method for making API requests to Supabase
    func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        authenticated: Bool = true,
        responseType: T.Type
    ) -> AnyPublisher<T, SupabaseError> {
        guard let url = URL(string: endpoint) else {
            return Fail(error: SupabaseError(error: "invalid_url", errorDescription: nil, message: "Invalid URL"))
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Set headers
        if authenticated, let token = getAuthToken() {
            SupabaseConfig.authHeaders(token: token).forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
        } else {
            SupabaseConfig.defaultHeaders.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Set body if provided
        if let body = body {
            request.httpBody = body
        }
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: responseType, decoder: JSONDecoder())
            .mapError { error in
                if let decodingError = error as? DecodingError {
                    print("Decoding error: \(decodingError)")
                    return SupabaseError(error: "decoding_error", errorDescription: nil, message: "Failed to decode response")
                }
                return SupabaseError(error: "network_error", errorDescription: nil, message: error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Database Operations
    
    /// Select data from a table
    func select<T: Codable>(
        from table: String,
        columns: String = "*",
        filter: String? = nil,
        responseType: T.Type
    ) -> AnyPublisher<[T], SupabaseError> {
        var endpoint = "\(SupabaseConfig.restURL)/\(table)?select=\(columns)"
        
        if let filter = filter {
            endpoint += "&\(filter)"
        }
        
        return request(endpoint: endpoint, responseType: [T].self)
    }
    
    /// Insert data into a table
    func insert<T: Codable>(
        into table: String,
        data: T
    ) -> AnyPublisher<T, SupabaseError> {
        let endpoint = "\(SupabaseConfig.restURL)/\(table)"
        
        guard let body = try? JSONEncoder().encode(data) else {
            return Fail(error: SupabaseError(error: "encoding_error", errorDescription: nil, message: "Failed to encode data"))
                .eraseToAnyPublisher()
        }
        
        return request(endpoint: endpoint, method: .POST, body: body, responseType: T.self)
    }
    
    /// Update data in a table
    func update<T: Codable>(
        table: String,
        data: T,
        filter: String
    ) -> AnyPublisher<T, SupabaseError> {
        let endpoint = "\(SupabaseConfig.restURL)/\(table)?\(filter)"
        
        guard let body = try? JSONEncoder().encode(data) else {
            return Fail(error: SupabaseError(error: "encoding_error", errorDescription: nil, message: "Failed to encode data"))
                .eraseToAnyPublisher()
        }
        
        return request(endpoint: endpoint, method: .PATCH, body: body, responseType: T.self)
    }
    
    /// Delete data from a table
    func delete(
        from table: String,
        filter: String
    ) -> AnyPublisher<Void, SupabaseError> {
        let endpoint = "\(SupabaseConfig.restURL)/\(table)?\(filter)"
        
        return request(endpoint: endpoint, method: .DELETE, responseType: EmptyResponse.self)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}

// MARK: - HTTP Methods

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
}

// MARK: - Helper Models

struct EmptyResponse: Codable {}
