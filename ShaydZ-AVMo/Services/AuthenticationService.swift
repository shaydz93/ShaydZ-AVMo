import Foundation
import Combine

/// Authentication service response models
struct LoginResponse: Codable {
    let token: String
}

struct UserProfile: Codable {
    let id: String
    let username: String
    let email: String
    let firstName: String?
    let lastName: String?
    let role: String
    let isActive: Bool
    let biometricEnabled: Bool?
    let lastLogin: String?
    let createdAt: String
}

class AuthenticationService {
    static let shared = AuthenticationService()
    private let networkService = NetworkService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    /// Login with username and password
    func login(username: String, password: String) -> AnyPublisher<Bool, APIError> {
        // In a production environment, this would use the API
        #if DEBUG
        // For demo/testing purposes, also support the hardcoded demo account
        if username.lowercased() == "demo" && password == "password" {
            // Create a fake token
            let fakeToken = "demo_token_\(Int(Date().timeIntervalSince1970))"
            networkService.saveAuthToken(fakeToken)
            return Just(true)
                .setFailureType(to: APIError.self)
                .eraseToAnyPublisher()
        }
        #endif
        
        let credentials = ["username": username, "password": password]
        
        guard let body = try? JSONEncoder().encode(credentials) else {
            return Fail(error: APIError.unknown).eraseToAnyPublisher()
        }
        
        return networkService.request(
            endpoint: "\(APIConfig.authEndpoint)/login",
            method: "POST",
            body: body,
            requiresAuth: false
        )
        .map { (response: LoginResponse) -> Bool in
            // Store token
            self.networkService.saveAuthToken(response.token)
            return true
        }
        .eraseToAnyPublisher()
    }
    
    /// Register a new user
    func register(username: String, email: String, password: String, firstName: String?, lastName: String?) -> AnyPublisher<Bool, APIError> {
        var userData: [String: String] = [
            "username": username,
            "email": email,
            "password": password
        ]
        
        if let firstName = firstName {
            userData["firstName"] = firstName
        }
        
        if let lastName = lastName {
            userData["lastName"] = lastName
        }
        
        guard let body = try? JSONEncoder().encode(userData) else {
            return Fail(error: APIError.unknown).eraseToAnyPublisher()
        }
        
        return networkService.request(
            endpoint: "\(APIConfig.authEndpoint)/register",
            method: "POST",
            body: body,
            requiresAuth: false
        )
        .map { (_: [String: String]) -> Bool in
            return true
        }
        .eraseToAnyPublisher()
    }
    
    /// Get user profile
    func getUserProfile() -> AnyPublisher<UserProfile, APIError> {
        return networkService.request(
            endpoint: "\(APIConfig.authEndpoint)/profile",
            requiresAuth: true
        )
    }
    
    /// Update user profile
    func updateProfile(firstName: String?, lastName: String?, email: String?, biometricEnabled: Bool?) -> AnyPublisher<Bool, APIError> {
        var userData: [String: Any] = [:]
        
        if let firstName = firstName {
            userData["firstName"] = firstName
        }
        
        if let lastName = lastName {
            userData["lastName"] = lastName
        }
        
        if let email = email {
            userData["email"] = email
        }
        
        if let biometricEnabled = biometricEnabled {
            userData["biometricEnabled"] = biometricEnabled
        }
        
        guard let body = try? JSONEncoder().encode(userData) else {
            return Fail(error: APIError.unknown).eraseToAnyPublisher()
        }
        
        return networkService.request(
            endpoint: "\(APIConfig.authEndpoint)/profile",
            method: "PUT",
            body: body,
            requiresAuth: true
        )
        .map { (_: [String: String]) -> Bool in
            return true
        }
        .eraseToAnyPublisher()
    }
    
    /// Logout
    func logout() {
        networkService.clearAuthToken()
    }
    
    /// Check if user is logged in
    func isLoggedIn() -> Bool {
        return networkService.getAuthToken() != nil
    }
    
    /// Validate session token
    func validateSession() -> AnyPublisher<Bool, APIError> {
        #if DEBUG
        // For demo purposes in debug mode, always validate demo token
        if let token = networkService.getAuthToken(), token.starts(with: "demo_token_") {
            return Just(true)
                .setFailureType(to: APIError.self)
                .eraseToAnyPublisher()
        }
        #endif
        
        return getUserProfile()
            .map { _ in true }
            .catch { error in
                // If unauthorized, clear token
                if case .unauthorized = error {
                    self.networkService.clearAuthToken()
                }
                return Just(false)
                    .setFailureType(to: APIError.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
