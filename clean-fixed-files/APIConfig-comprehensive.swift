import Foundation

/// Central API configuration for ShaydZ AVMo
public struct ShaydZAVMo_APIConfig {
    public static let shared = ShaydZAVMo_APIConfig()
    
    public let baseURL: URL
    public let timeout: TimeInterval
    public let maxRetries: Int
    public let authTokenKey: String
    public let apiVersion: String
    
    private init() {
        // Default configuration - modify based on environment
        self.baseURL = URL(string: "https://api.shaydz-avmo.com")!
        self.timeout = 30.0
        self.maxRetries = 3
        self.authTokenKey = "ShaydZAVMo-Auth-Token"
        self.apiVersion = "v1"
    }
    
    public var authURL: URL {
        return baseURL.appendingPathComponent("auth")
    }
    
    public var vmURL: URL {
        return baseURL.appendingPathComponent("vm")
    }
    
    public var appCatalogURL: URL {
        return baseURL.appendingPathComponent("apps")
    }
    
    public var userProfileURL: URL {
        return baseURL.appendingPathComponent("users")
    }
}

// Type aliases for backward compatibility
public typealias APIConfig = ShaydZAVMo_APIConfig
public typealias ShaydZ_APIConfig = ShaydZAVMo_APIConfig
