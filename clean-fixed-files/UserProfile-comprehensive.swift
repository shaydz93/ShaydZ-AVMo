import Foundation

/// Central user profile model for ShaydZ AVMo
/// This is the single source of truth for user profile data across all services
public struct ShaydZAVMo_UserProfile: Identifiable, Codable, Hashable {
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
    public let updatedAt: Date?
    public let preferences: UserPreferences?
    
    public init(
        id: String,
        username: String,
        email: String,
        firstName: String? = nil,
        lastName: String? = nil,
        role: String? = nil,
        isActive: Bool = true,
        biometricEnabled: Bool = false,
        lastLogin: Date? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        preferences: UserPreferences? = nil
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
        self.updatedAt = updatedAt
        self.preferences = preferences
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
    
    public var initials: String {
        if let firstName = firstName, let lastName = lastName {
            return "\(firstName.prefix(1))\(lastName.prefix(1))".uppercased()
        } else if let firstName = firstName {
            return "\(firstName.prefix(1))".uppercased()
        } else {
            return "\(username.prefix(1))".uppercased()
        }
    }
}

/// User preferences structure
public struct UserPreferences: Codable, Hashable {
    public let theme: String?
    public let language: String?
    public let notifications: Bool
    public let autoSave: Bool
    public let vmSettings: VMPreferences?
    
    public init(
        theme: String? = nil,
        language: String? = nil,
        notifications: Bool = true,
        autoSave: Bool = true,
        vmSettings: VMPreferences? = nil
    ) {
        self.theme = theme
        self.language = language
        self.notifications = notifications
        self.autoSave = autoSave
        self.vmSettings = vmSettings
    }
}

/// VM-specific user preferences
public struct VMPreferences: Codable, Hashable {
    public let defaultRAM: Int?
    public let defaultStorage: Int?
    public let autoStart: Bool
    public let debugMode: Bool
    
    public init(
        defaultRAM: Int? = nil,
        defaultStorage: Int? = nil,
        autoStart: Bool = false,
        debugMode: Bool = false
    ) {
        self.defaultRAM = defaultRAM
        self.defaultStorage = defaultStorage
        self.autoStart = autoStart
        self.debugMode = debugMode
    }
}

// Type aliases for backward compatibility
public typealias UserProfile = ShaydZAVMo_UserProfile
public typealias ShaydZ_UserProfile = ShaydZAVMo_UserProfile
public typealias ShaydZUnique_UserProfile = ShaydZAVMo_UserProfile
