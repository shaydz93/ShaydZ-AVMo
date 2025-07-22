import Foundation

// Single, centralized declaration of APIConfig
public struct ShaydZ_APIConfig {
    public static let requestTimeout: TimeInterval = 30.0
    public static let baseURL = URL(string: "https://api.shaydz-avmo.io")!
    public static let appCatalogEndpoint = "/apps"
    public static let authEndpoint = "/auth"
    public static let vmEndpoint = "/vm"
    
    // Add any other configuration constants here
}

// Type alias for backward compatibility
public typealias APIConfig = ShaydZ_APIConfig
