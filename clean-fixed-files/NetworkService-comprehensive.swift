import Foundation
import Combine

/// Central network service for ShaydZ AVMo
public class ShaydZAVMo_NetworkService: ObservableObject {
    public static let shared = ShaydZAVMo_NetworkService()
    
    private let urlSession: URLSession
    private let apiConfig = ShaydZAVMo_APIConfig.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published public var isConnected: Bool = true
    @Published public var isLoading: Bool = false
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = apiConfig.timeout
        config.timeoutIntervalForResource = apiConfig.timeout * 2
        self.urlSession = URLSession(configuration: config)
        
        startNetworkMonitoring()
    }
    
    // MARK: - Generic Network Methods
    
    /// Generic GET request
    public func get<T: Codable>(
        endpoint: String,
        responseType: T.Type,
        headers: [String: String] = [:]
    ) -> AnyPublisher<T, ShaydZAVMo_APIError> {
        guard let url = URL(string: "\(apiConfig.baseURL.absoluteString)/\(endpoint)") else {
            return Fail(error: ShaydZAVMo_APIError.badRequest)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = defaultHeaders().merging(headers) { _, new in new }
        
        return performRequest(request: request, responseType: responseType)
    }
    
    /// Generic POST request
    public func post<T: Codable, U: Codable>(
        endpoint: String,
        body: T,
        responseType: U.Type,
        headers: [String: String] = [:]
    ) -> AnyPublisher<U, ShaydZAVMo_APIError> {
        guard let url = URL(string: "\(apiConfig.baseURL.absoluteString)/\(endpoint)") else {
            return Fail(error: ShaydZAVMo_APIError.badRequest)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = defaultHeaders().merging(headers) { _, new in new }
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            return Fail(error: ShaydZAVMo_APIError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return performRequest(request: request, responseType: responseType)
    }
    
    /// Generic PUT request
    public func put<T: Codable, U: Codable>(
        endpoint: String,
        body: T,
        responseType: U.Type,
        headers: [String: String] = [:]
    ) -> AnyPublisher<U, ShaydZAVMo_APIError> {
        guard let url = URL(string: "\(apiConfig.baseURL.absoluteString)/\(endpoint)") else {
            return Fail(error: ShaydZAVMo_APIError.badRequest)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.allHTTPHeaderFields = defaultHeaders().merging(headers) { _, new in new }
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            return Fail(error: ShaydZAVMo_APIError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return performRequest(request: request, responseType: responseType)
    }
    
    /// Generic DELETE request
    public func delete(
        endpoint: String,
        headers: [String: String] = [:]
    ) -> AnyPublisher<Bool, ShaydZAVMo_APIError> {
        guard let url = URL(string: "\(apiConfig.baseURL.absoluteString)/\(endpoint)") else {
            return Fail(error: ShaydZAVMo_APIError.badRequest)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = defaultHeaders().merging(headers) { _, new in new }
        
        return urlSession.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw ShaydZAVMo_APIError.invalidResponse
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    throw self.mapHTTPError(statusCode: httpResponse.statusCode)
                }
                
                return true
            }
            .mapError { error in
                if let apiError = error as? ShaydZAVMo_APIError {
                    return apiError
                } else {
                    return ShaydZAVMo_APIError.networkUnavailable
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    private func performRequest<T: Codable>(
        request: URLRequest,
        responseType: T.Type
    ) -> AnyPublisher<T, ShaydZAVMo_APIError> {
        isLoading = true
        
        return urlSession.dataTaskPublisher(for: request)
            .tryMap { [weak self] data, response in
                self?.isLoading = false
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw ShaydZAVMo_APIError.invalidResponse
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    throw self?.mapHTTPError(statusCode: httpResponse.statusCode) ?? ShaydZAVMo_APIError.serverError
                }
                
                do {
                    return try JSONDecoder().decode(T.self, from: data)
                } catch {
                    throw ShaydZAVMo_APIError.decodingError
                }
            }
            .mapError { [weak self] error in
                self?.isLoading = false
                
                if let apiError = error as? ShaydZAVMo_APIError {
                    return apiError
                } else {
                    return ShaydZAVMo_APIError.networkUnavailable
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    private func defaultHeaders() -> [String: String] {
        var headers = [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": "ShaydZ-AVMo/\(apiConfig.apiVersion)"
        ]
        
        if let authToken = ShaydZAVMo_AuthenticationService.shared.authToken {
            headers["Authorization"] = "Bearer \(authToken)"
        }
        
        return headers
    }
    
    private func mapHTTPError(statusCode: Int) -> ShaydZAVMo_APIError {
        switch statusCode {
        case 400:
            return .badRequest
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 408:
            return .timeout
        case 429:
            return .rateLimited
        case 500...599:
            return .serverError
        default:
            return .unknown("HTTP \(statusCode)")
        }
    }
    
    private func startNetworkMonitoring() {
        // Basic network monitoring
        Timer.publish(every: 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkNetworkStatus()
            }
            .store(in: &cancellables)
    }
    
    private func checkNetworkStatus() {
        // Simple ping to check connectivity
        guard let url = URL(string: "\(apiConfig.baseURL.absoluteString)/health") else { return }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0
        
        urlSession.dataTask(with: request) { [weak self] _, response, _ in
            DispatchQueue.main.async {
                self?.isConnected = (response as? HTTPURLResponse)?.statusCode == 200
            }
        }.resume()
    }
}

// Type aliases for backward compatibility
public typealias NetworkService = ShaydZAVMo_NetworkService
public typealias ShaydZ_NetworkService = ShaydZAVMo_NetworkService
