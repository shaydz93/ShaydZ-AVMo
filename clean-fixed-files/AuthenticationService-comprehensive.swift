import Foundation
import Combine

/// Central authentication service for ShaydZ AVMo
public class ShaydZAVMo_AuthenticationService: ObservableObject {
    public static let shared = ShaydZAVMo_AuthenticationService()
    
    @Published public var isAuthenticated: Bool = false
    @Published public var currentUser: ShaydZAVMo_UserProfile?
    @Published public var authToken: String?
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let apiConfig = ShaydZAVMo_APIConfig.shared
    
    private init() {
        // Initialize authentication state
        loadStoredAuthState()
    }
    
    // MARK: - Authentication Methods
    
    /// Sign in with email and password
    public func signIn(email: String, password: String) -> AnyPublisher<ShaydZAVMo_UserProfile, ShaydZAVMo_APIError> {
        isLoading = true
        errorMessage = nil
        
        // Mock implementation for demo
        return Future<ShaydZAVMo_UserProfile, ShaydZAVMo_APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.isLoading = false
                
                // Simulate authentication
                if email.contains("@") && !password.isEmpty {
                    let user = ShaydZAVMo_UserProfile(
                        id: "user-\(UUID().uuidString)",
                        username: email.components(separatedBy: "@").first ?? "user",
                        email: email,
                        firstName: "Demo",
                        lastName: "User",
                        role: "user",
                        isActive: true,
                        biometricEnabled: false,
                        lastLogin: Date(),
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    
                    self?.currentUser = user
                    self?.isAuthenticated = true
                    self?.authToken = "demo-token-\(UUID().uuidString)"
                    self?.saveAuthState()
                    
                    promise(.success(user))
                } else {
                    let error = ShaydZAVMo_APIError.invalidCredentials
                    self?.errorMessage = error.localizedDescription
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Sign up with user details
    public func signUp(username: String, email: String, password: String, firstName: String?, lastName: String?) -> AnyPublisher<ShaydZAVMo_UserProfile, ShaydZAVMo_APIError> {
        isLoading = true
        errorMessage = nil
        
        return Future<ShaydZAVMo_UserProfile, ShaydZAVMo_APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self?.isLoading = false
                
                // Simulate registration
                if !username.isEmpty && email.contains("@") && !password.isEmpty {
                    let user = ShaydZAVMo_UserProfile(
                        id: "user-\(UUID().uuidString)",
                        username: username,
                        email: email,
                        firstName: firstName,
                        lastName: lastName,
                        role: "user",
                        isActive: true,
                        biometricEnabled: false,
                        lastLogin: nil,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    
                    self?.currentUser = user
                    self?.isAuthenticated = true
                    self?.authToken = "demo-token-\(UUID().uuidString)"
                    self?.saveAuthState()
                    
                    promise(.success(user))
                } else {
                    let error = ShaydZAVMo_APIError.registrationFailed
                    self?.errorMessage = error.localizedDescription
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Sign out current user
    public func signOut() -> AnyPublisher<Bool, ShaydZAVMo_APIError> {
        isLoading = true
        
        return Future<Bool, ShaydZAVMo_APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.isLoading = false
                self?.currentUser = nil as ShaydZAVMo_UserProfile?
                self?.isAuthenticated = false
                self?.authToken = nil as String?
                self?.clearAuthState()
                promise(.success(true))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Reset password for email
    public func resetPassword(email: String) -> AnyPublisher<Bool, ShaydZAVMo_APIError> {
        isLoading = true
        errorMessage = nil
        
        return Future<Bool, ShaydZAVMo_APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.isLoading = false
                
                if email.contains("@") {
                    promise(.success(true))
                } else {
                    let error = ShaydZAVMo_APIError.passwordResetFailed
                    self?.errorMessage = error.localizedDescription
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Update user profile
    public func updateProfile(_ profile: ShaydZAVMo_UserProfile) -> AnyPublisher<ShaydZAVMo_UserProfile, ShaydZAVMo_APIError> {
        isLoading = true
        
        return Future<ShaydZAVMo_UserProfile, ShaydZAVMo_APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self?.isLoading = false
                
                let updatedProfile = ShaydZAVMo_UserProfile(
                    id: profile.id,
                    username: profile.username,
                    email: profile.email,
                    firstName: profile.firstName,
                    lastName: profile.lastName,
                    role: profile.role,
                    isActive: profile.isActive,
                    biometricEnabled: profile.biometricEnabled,
                    lastLogin: profile.lastLogin,
                    createdAt: profile.createdAt,
                    updatedAt: Date(),
                    preferences: profile.preferences
                )
                
                self?.currentUser = updatedProfile
                self?.saveAuthState()
                promise(.success(updatedProfile))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    private func loadStoredAuthState() {
        // Load from UserDefaults or Keychain
        if let storedToken = UserDefaults.standard.string(forKey: "ShaydZAVMo_AuthToken"),
           let userData = UserDefaults.standard.data(forKey: "ShaydZAVMo_UserProfile"),
           let user = try? JSONDecoder().decode(ShaydZAVMo_UserProfile.self, from: userData) {
            
            self.authToken = storedToken
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    private func saveAuthState() {
        if let token = authToken {
            UserDefaults.standard.set(token, forKey: "ShaydZAVMo_AuthToken")
        }
        
        if let user = currentUser,
           let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "ShaydZAVMo_UserProfile")
        }
    }
    
    private func clearAuthState() {
        UserDefaults.standard.removeObject(forKey: "ShaydZAVMo_AuthToken")
        UserDefaults.standard.removeObject(forKey: "ShaydZAVMo_UserProfile")
    }
}

// Type aliases for backward compatibility
public typealias AuthenticationService = ShaydZAVMo_AuthenticationService
public typealias ShaydZ_AuthenticationService = ShaydZAVMo_AuthenticationService
