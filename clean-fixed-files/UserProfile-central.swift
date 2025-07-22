import Foundation

/// Central user profile model for ShaydZ AVMo
/// This is the single source of truth for user profile data across all services
public struct ShaydZ_UserProfile: Identifiable, Codable {
    public let id: String
    public let username: String
    public let email: String
    public let firstName: String?
    public let lastName: String?
    public let role: String?
    public let isActive: Bool
    public let lastLogin: Date?
    public let createdAt: Date?
    public let updatedAt: Date?
    
    public init(
        id: String,
        username: String,
        email: String,
        firstName: String? = nil,
        lastName: String? = nil,
        role: String? = nil,
        isActive: Bool = true,
        lastLogin: Date? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.role = role
        self.isActive = isActive
        self.lastLogin = lastLogin
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Type alias for backward compatibility
public typealias UserProfile = ShaydZ_UserProfile
