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

class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()
    private let networkService = AppCatalogNetworkService.shared
    private let supabaseAuth = SupabaseAuthService.shared
    private var cancellables = Set<AnyCancellable>()
    
    /// Published properties for reactive UI updates
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    
    private init() {
        // Observe Supabase authentication state
        supabaseAuth.$isAuthenticated
            .assign(to: \.isAuthenticated, on: self)
            .store(in: &cancellables)
        
        // Convert Supabase user profile to local UserProfile
        supabaseAuth.$userProfile
            .compactMap { profile in
                guard let profile = profile else { return nil }
                return UserProfile(
                    id: profile.id,
                    username: profile.username ?? profile.email ?? "Unknown",
                    email: profile.email ?? "",
                    firstName: profile.firstName,
                    lastName: profile.lastName,
                    role: profile.role,
                    isActive: profile.isActive,
                    biometricEnabled: profile.biometricEnabled,
                    lastLogin: profile.lastLogin,
                    createdAt: profile.createdAt
                )
            }
            .assign(to: \.currentUser, on: self)
            .store(in: &cancellables)
    }
    
    /// Login with username and password - now uses Supabase
    func login(username: String, password: String) -> AnyPublisher<Bool, APIError> {
        // For demo/testing purposes, support the hardcoded demo account
        #if DEBUG
        if username.lowercased() == "demo" && password == "password" {
            let fakeToken = "demo_token_\(Int(Date().timeIntervalSince1970))"
            networkService.saveAuthToken(fakeToken)
            return Just(true)
                .setFailureType(to: APIError.self)
                .eraseToAnyPublisher()
        }
        #endif
        
        // Use Supabase for authentication
        return supabaseAuth.signIn(email: username, password: password)
            .map { _ in true }
            .mapError { supabaseError in
                // Convert Supabase errors to APIError
                switch supabaseError.error {
                case "invalid_credentials":
                    return APIError.unauthorized
                case "network_error":
                    return APIError.networkError
                default:
                    return APIError.badRequest(supabaseError.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
    
    /// Sign up with email and password - new Supabase method
    func signUp(email: String, password: String, firstName: String? = nil, lastName: String? = nil) -> AnyPublisher<Bool, APIError> {
        var metadata: [String: Any] = [:]
        if let firstName = firstName {
            metadata["first_name"] = firstName
        }
        if let lastName = lastName {
            metadata["last_name"] = lastName
        }
        
        return supabaseAuth.signUp(email: email, password: password, metadata: metadata.isEmpty ? nil : metadata)
            .map { _ in true }
            .mapError { supabaseError in
                switch supabaseError.error {
                case "email_already_exists":
                    return APIError.badRequest("Email already exists")
                case "weak_password":
                    return APIError.badRequest("Password is too weak")
                case "network_error":
                    return APIError.networkError
                default:
                    return APIError.badRequest(supabaseError.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
    
    /// Register a new user (alias for signUp for backward compatibility)
    func register(username: String, email: String, password: String, firstName: String?, lastName: String?) -> AnyPublisher<Bool, APIError> {
        return signUp(email: email, password: password, firstName: firstName, lastName: lastName)
    }
    
    /// Get user profile - now uses Supabase
    func getUserProfile() -> AnyPublisher<UserProfile, APIError> {
        return supabaseAuth.fetchUserProfile()
            .map { profile in
                UserProfile(
                    id: profile.id,
                    username: profile.username ?? profile.email ?? "Unknown",
                    email: profile.email ?? "",
                    firstName: profile.firstName,
                    lastName: profile.lastName,
                    role: profile.role,
                    isActive: profile.isActive,
                    biometricEnabled: profile.biometricEnabled,
                    lastLogin: profile.lastLogin,
                    createdAt: profile.createdAt
                )
            }
            .mapError { supabaseError in
                APIError.badRequest(supabaseError.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    /// Update user profile - now uses Supabase
    func updateProfile(firstName: String?, lastName: String?, email: String?, biometricEnabled: Bool?) -> AnyPublisher<Bool, APIError> {
        guard let currentProfile = supabaseAuth.userProfile else {
            return Fail(error: APIError.unauthorized).eraseToAnyPublisher()
        }
        
        let updatedProfile = SupabaseUserProfile(
            id: currentProfile.id,
            email: email ?? currentProfile.email,
            username: currentProfile.username,
            firstName: firstName ?? currentProfile.firstName,
            lastName: lastName ?? currentProfile.lastName,
            displayName: currentProfile.displayName,
            role: currentProfile.role,
            isActive: currentProfile.isActive,
            biometricEnabled: biometricEnabled ?? currentProfile.biometricEnabled,
            lastLogin: currentProfile.lastLogin,
            createdAt: currentProfile.createdAt,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        return supabaseAuth.updateUserProfile(updatedProfile)
            .map { _ in true }
            .mapError { supabaseError in
                APIError.badRequest(supabaseError.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    /// Logout - now uses Supabase
    func logout() -> AnyPublisher<Bool, APIError> {
        return supabaseAuth.signOut()
            .map { true }
            .mapError { supabaseError in
                APIError.badRequest(supabaseError.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    /// Legacy logout method for backward compatibility
    func logoutSync() {
        _ = logout()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in }
            )
    }
    
    /// Reset password - new Supabase method
    func resetPassword(email: String) -> AnyPublisher<Bool, APIError> {
        return supabaseAuth.resetPassword(email: email)
            .map { true }
            .mapError { supabaseError in
                APIError.badRequest(supabaseError.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    /// Check if user is logged in
    func isLoggedIn() -> Bool {
        return supabaseAuth.isAuthenticated || networkService.getAuthToken() != nil
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
        
        if supabaseAuth.isAuthenticated {
            return Just(true)
                .setFailureType(to: APIError.self)
                .eraseToAnyPublisher()
        }
        
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
