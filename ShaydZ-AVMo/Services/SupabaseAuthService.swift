import Foundation
import Combine

struct SupabaseUserProfile: Codable {
    let id: String
    let email: String?
    let username: String?
    let firstName: String?
    let lastName: String?
    let role: String
    let isActive: Bool
    let biometricEnabled: Bool?
    let lastLogin: String?
    let createdAt: String
}

struct SupabaseError: Error {
    let error: String
    let errorDescription: String
}

class SupabaseAuthService: ObservableObject {
    static let shared = SupabaseAuthService()
    
    private let baseURL = "https://qnzskbfqqzxuikjyzqdp.supabase.co"
    private let apiKey = "your_supabase_anon_key_here"
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isAuthenticated = false
    @Published var currentUser: SupabaseUserProfile?
    @Published var authToken: String?
    @Published var refreshToken: String?
    
    var userProfile: SupabaseUserProfile? {
        return currentUser
    }
    
    private init() {
        // Check for existing auth tokens
        if let token = UserDefaults.standard.string(forKey: "supabase_auth_token"),
           let refreshToken = UserDefaults.standard.string(forKey: "supabase_refresh_token") {
            self.authToken = token
            self.refreshToken = refreshToken
            self.isAuthenticated = true
            
            // Validate token and get user profile
            fetchUserProfile()
        }
    }
    
    func signIn(email: String, password: String) -> AnyPublisher<SupabaseUserProfile, SupabaseError> {
        // For demo purposes, create a mock successful login
        let mockUser = SupabaseUserProfile(
            id: "demo-user-id",
            email: email,
            username: email,
            firstName: "Demo",
            lastName: "User",
            role: "user",
            isActive: true,
            biometricEnabled: false,
            lastLogin: ISO8601DateFormatter().string(from: Date()),
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        
        self.currentUser = mockUser
        self.isAuthenticated = true
        self.authToken = "demo-token-\(Int(Date().timeIntervalSince1970))"
        
        UserDefaults.standard.set(self.authToken, forKey: "supabase_auth_token")
        
        return Just(mockUser)
            .setFailureType(to: SupabaseError.self)
            .eraseToAnyPublisher()
    }
    
    func signUp(email: String, password: String) -> AnyPublisher<SupabaseUserProfile, SupabaseError> {
        return signIn(email: email, password: password)
    }
    
    func signOut() {
        UserDefaults.standard.removeObject(forKey: "supabase_auth_token")
        UserDefaults.standard.removeObject(forKey: "supabase_refresh_token")
        
        authToken = nil
        refreshToken = nil
        currentUser = nil
        isAuthenticated = false
    }
    
    private func fetchUserProfile() {
        // For demo purposes, return a mock user
        let mockUser = SupabaseUserProfile(
            id: "demo-user-id",
            email: "demo@example.com",
            username: "demo",
            firstName: "Demo",
            lastName: "User",
            role: "user",
            isActive: true,
            biometricEnabled: false,
            lastLogin: ISO8601DateFormatter().string(from: Date()),
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        
        self.currentUser = mockUser
    }
    
    func fetchUserProfilePublisher() -> AnyPublisher<SupabaseUserProfile, SupabaseError> {
        if let user = currentUser {
            return Just(user)
                .setFailureType(to: SupabaseError.self)
                .eraseToAnyPublisher()
        } else {
            return Fail(error: SupabaseError(error: "not_authenticated", errorDescription: "User is not authenticated"))
                .eraseToAnyPublisher()
        }
    }
}

extension SupabaseError {
    func toAPIError() -> APIError {
        switch self.error {
        case "invalid_credentials":
            return .unauthorized
        case "network_error":
            return .networkError
        default:
            return .requestFailed(self.errorDescription)
        }
    }
}
