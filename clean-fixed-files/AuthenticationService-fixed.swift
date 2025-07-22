import Foundation
import Combine

/// Authentication service for user management
public class ShaydZ_AuthenticationService: ObservableObject {
    public static let shared = ShaydZ_AuthenticationService()
    
    @Published public var isAuthenticated: Bool = false
    @Published public var currentUser: ShaydZ_UserProfile?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    /// Sign in with email and password
    public func signIn(email: String, password: String) -> AnyPublisher<ShaydZ_UserProfile, ShaydZ_APIError> {
        // Mock implementation
        let mockUser = ShaydZ_UserProfile(
            id: "auth-user-\(UUID().uuidString)",
            username: email.components(separatedBy: "@").first ?? "user",
            email: email,
            firstName: "Demo",
            lastName: "User",
            role: "user",
            isActive: true,
            biometricEnabled: false,
            lastLogin: Date(),
            createdAt: Date()
        )
        
        return Just(mockUser)
            .setFailureType(to: ShaydZ_APIError.self)
            .delay(for: .seconds(1), scheduler: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] user in
                self?.currentUser = user
                self?.isAuthenticated = true
            })
            .eraseToAnyPublisher()
    }
    
    /// Sign up with email and password
    public func signUp(email: String, password: String, firstName: String?, lastName: String?) -> AnyPublisher<ShaydZ_UserProfile, ShaydZ_APIError> {
        // Mock implementation
        let newUser = ShaydZ_UserProfile(
            id: "new-user-\(UUID().uuidString)",
            username: email.components(separatedBy: "@").first ?? "newuser",
            email: email,
            firstName: firstName,
            lastName: lastName,
            role: "user",
            isActive: true,
            biometricEnabled: false,
            lastLogin: nil,
            createdAt: Date()
        )
        
        return Just(newUser)
            .setFailureType(to: ShaydZ_APIError.self)
            .delay(for: .seconds(2), scheduler: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] user in
                self?.currentUser = user
                self?.isAuthenticated = true
            })
            .eraseToAnyPublisher()
    }
    
    /// Sign out current user
    public func signOut() -> AnyPublisher<Bool, ShaydZ_APIError> {
        return Just(true)
            .setFailureType(to: ShaydZ_APIError.self)
            .delay(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.currentUser = nil
                self?.isAuthenticated = false
            })
            .eraseToAnyPublisher()
    }
    
    /// Reset password for email
    public func resetPassword(email: String) -> AnyPublisher<Bool, ShaydZ_APIError> {
        // Mock implementation
        if email.isEmpty {
            return Fail(error: ShaydZ_APIError.badRequest)
                .eraseToAnyPublisher()
        }
        
        return Just(true)
            .setFailureType(to: ShaydZ_APIError.self)
            .delay(for: .seconds(1), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// Update user profile
    public func updateProfile(_ profile: ShaydZ_UserProfile) -> AnyPublisher<ShaydZ_UserProfile, ShaydZ_APIError> {
        return Just(profile)
            .setFailureType(to: ShaydZ_APIError.self)
            .delay(for: .seconds(1), scheduler: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] updatedProfile in
                self?.currentUser = updatedProfile
            })
            .eraseToAnyPublisher()
    }
    
    /// Delete user account
    public func deleteAccount() -> AnyPublisher<Bool, ShaydZ_APIError> {
        return Just(true)
            .setFailureType(to: ShaydZ_APIError.self)
            .delay(for: .seconds(2), scheduler: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.currentUser = nil
                self?.isAuthenticated = false
            })
            .eraseToAnyPublisher()
    }
}

/// User profile model for authentication
public struct ShaydZ_UserProfile: Identifiable, Codable {
    public let id: String
    public let username: String
    public let email: String
    public let firstName: String?
    public let lastName: String?
    public let role: String?
    public let isActive: Bool
    public let biometricEnabled: Bool
    public let lastLogin: Date?
    public let createdAt: Date?
    
    public init(
        id: String,
        username: String,
        email: String,
        firstName: String?,
        lastName: String?,
        role: String?,
        isActive: Bool,
        biometricEnabled: Bool,
        lastLogin: Date?,
        createdAt: Date?
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.role = role
        self.isActive = isActive
        self.biometricEnabled = biometricEnabled
        self.lastLogin = lastLogin
        self.createdAt = createdAt
    }
    
    public var displayName: String {
        if let firstName = firstName, let lastName = lastName {
            return "\(firstName) \(lastName)"
        } else if let firstName = firstName {
            return firstName
        } else {
            return username
        }
    }
}

// Type alias for backward compatibility
public typealias AuthenticationService = ShaydZ_AuthenticationService
// Note: UserProfile type alias removed to avoid redeclaration conflicts
// Use ShaydZ_UserProfile directly or import from the appropriate module
