import Foundation

// MARK: - Supabase Authentication Models

/// Supabase authentication response
struct SupabaseAuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String
    let user: SupabaseUser
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case user
    }
}

/// Supabase user model
struct SupabaseUser: Codable {
    let id: String
    let email: String?
    let phone: String?
    let emailConfirmedAt: String?
    let phoneConfirmedAt: String?
    let lastSignInAt: String?
    let role: String?
    let userMetadata: [String: Any]?
    let appMetadata: [String: Any]?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case phone
        case emailConfirmedAt = "email_confirmed_at"
        case phoneConfirmedAt = "phone_confirmed_at"
        case lastSignInAt = "last_sign_in_at"
        case role
        case userMetadata = "user_metadata"
        case appMetadata = "app_metadata"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        emailConfirmedAt = try container.decodeIfPresent(String.self, forKey: .emailConfirmedAt)
        phoneConfirmedAt = try container.decodeIfPresent(String.self, forKey: .phoneConfirmedAt)
        lastSignInAt = try container.decodeIfPresent(String.self, forKey: .lastSignInAt)
        role = try container.decodeIfPresent(String.self, forKey: .role)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        
        // Handle metadata as optional dictionaries
        userMetadata = try container.decodeIfPresent([String: Any].self, forKey: .userMetadata)
        appMetadata = try container.decodeIfPresent([String: Any].self, forKey: .appMetadata)
    }
}

/// Supabase error response
struct SupabaseError: Codable, Error {
    let error: String?
    let errorDescription: String?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
        case message
    }
    
    var localizedDescription: String {
        return message ?? errorDescription ?? error ?? "Unknown error occurred"
    }
}

// MARK: - Supabase Database Models

/// User profile stored in Supabase database
struct SupabaseUserProfile: Codable {
    let id: String
    let email: String?
    let username: String?
    let firstName: String?
    let lastName: String?
    let displayName: String?
    let role: String
    let isActive: Bool
    let biometricEnabled: Bool
    let lastLogin: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case displayName = "display_name"
        case role
        case isActive = "is_active"
        case biometricEnabled = "biometric_enabled"
        case lastLogin = "last_login"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Virtual Machine session stored in Supabase
struct SupabaseVMSession: Codable {
    let id: String
    let userId: String
    let vmInstanceId: String
    let status: String
    let startedAt: String?
    let endedAt: String?
    let ipAddress: String?
    let port: Int?
    let connectionUrl: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case vmInstanceId = "vm_instance_id"
        case status
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case ipAddress = "ip_address"
        case port
        case connectionUrl = "connection_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// App catalog item stored in Supabase
struct SupabaseAppCatalogItem: Codable {
    let id: String
    let name: String
    let description: String?
    let category: String
    let iconUrl: String?
    let version: String
    let isActive: Bool
    let requiredPermissions: [String]?
    let metadata: [String: Any]?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case category
        case iconUrl = "icon_url"
        case version
        case isActive = "is_active"
        case requiredPermissions = "required_permissions"
        case metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        category = try container.decode(String.self, forKey: .category)
        iconUrl = try container.decodeIfPresent(String.self, forKey: .iconUrl)
        version = try container.decode(String.self, forKey: .version)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        requiredPermissions = try container.decodeIfPresent([String].self, forKey: .requiredPermissions)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        
        // Handle metadata as optional dictionary
        metadata = try container.decodeIfPresent([String: Any].self, forKey: .metadata)
    }
}
