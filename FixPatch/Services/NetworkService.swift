import Foundation
import Combine
import SwiftUI  // This will help ensure the Models folder is in the search path

class NetworkService {
    static let shared = NetworkService()
    
    private let apiConfig = APIConfig.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Private initialization to enforce singleton pattern
    }
    
    func get(endpoint: String) -> AnyPublisher<Data, APIError> {
        guard let url = URL(string: "\(apiConfig.baseURL)/\(endpoint)") else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add authentication header if available
        if let authToken = apiConfig.authToken {
            request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.requestFailed("Invalid response")
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 401:
                    throw APIError.unauthorized
                case 404:
                    throw APIError.notFound
                case 500...599:
                    throw APIError.serverError
                default:
                    throw APIError.requestFailed("Status code: \(httpResponse.statusCode)")
                }
            }
            .mapError { error -> APIError in
                if let apiError = error as? APIError {
                    return apiError
                } else if let urlError = error as? URLError {
                    return APIError.networkError
                } else {
                    return APIError.unknown(error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
    
    func post(endpoint: String, parameters: [String: Any]) -> AnyPublisher<Data, APIError> {
        guard let url = URL(string: "\(apiConfig.baseURL)/\(endpoint)") else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication header if available
        if let authToken = apiConfig.authToken {
            request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            return Fail(error: APIError.encodingFailed).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.requestFailed("Invalid response")
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 401:
                    throw APIError.unauthorized
                case 404:
                    throw APIError.notFound
                case 500...599:
                    throw APIError.serverError
                default:
                    throw APIError.requestFailed("Status code: \(httpResponse.statusCode)")
                }
            }
            .mapError { error -> APIError in
                if let apiError = error as? APIError {
                    return apiError
                } else if let urlError = error as? URLError {
                    return APIError.networkError
                } else {
                    return APIError.unknown(error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
}
