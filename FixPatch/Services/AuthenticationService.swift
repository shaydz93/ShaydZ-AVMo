import Foundation
import Combine
import SwiftUI  // This will help ensure the Models folder is in the search path

class AuthenticationService {
    static let shared = AuthenticationService()
    
    private let networkService = NetworkService.shared
    private let apiConfig = APIConfig.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    
    private init() {
        // Private initialization to enforce singleton pattern
    }
    
    func login(username: String, password: String) -> AnyPublisher<Bool, APIError> {
        isLoading = true
        error = nil
        
        let endpoint = "auth-service/login"
        let parameters: [String: Any] = [
            "username": username,
            "password": password
        ]
        
        return networkService.post(endpoint: endpoint, parameters: parameters)
            .tryMap { data -> String in
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let token = json["token"] as? String else {
                    throw APIError.decodingFailed
                }
                return token
            }
            .handleEvents(
                receiveOutput: { [weak self] token in
                    self?.apiConfig.authToken = token
                    self?.isAuthenticated = true
                    self?.isLoading = false
                },
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveCancel: { [weak self] in
                    self?.isLoading = false
                }
            )
            .map { _ in true }
            .mapError { error -> APIError in
                if let apiError = error as? APIError {
                    return apiError
                } else {
                    return APIError.unknown(error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
    
    func logout() {
        apiConfig.authToken = nil
        isAuthenticated = false
    }
    
    func validateToken() -> AnyPublisher<Bool, APIError> {
        guard let token = apiConfig.authToken else {
            return Just(false)
                .setFailureType(to: APIError.self)
                .eraseToAnyPublisher()
        }
        
        let endpoint = "auth-service/validate"
        
        return networkService.get(endpoint: endpoint)
            .map { _ in true }
            .catch { error -> AnyPublisher<Bool, APIError> in
                self.apiConfig.authToken = nil
                self.isAuthenticated = false
                return Just(false).setFailureType(to: APIError.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
