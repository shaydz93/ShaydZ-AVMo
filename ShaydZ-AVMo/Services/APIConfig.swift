import Foundation

/// Central place to manage API configuration
struct APIConfig {
    /// The base URL for all API requests
    #if DEBUG
    // Use GitHub Codespace URL for API Gateway
    static let baseURL = "https://shaydz-avmo-8080.app.github.dev"
    #else
    static let baseURL = "https://api.shaydz-avmo.io/v1"
    #endif
    
    /// The endpoint for authentication
    static let authEndpoint = "\(baseURL)/auth"
    
    /// The endpoint for virtual machine operations
    static let vmEndpoint = "\(baseURL)/vm"
    
    /// The endpoint for app catalog operations
    static let appsEndpoint = "\(baseURL)/catalog"
    
    /// The WebSocket endpoint for VM streaming
    #if DEBUG
    static let wsEndpoint = "wss://shaydz-avmo-8082.app.github.dev/ws"
    #else
    static let wsEndpoint = "wss://api.shaydz-avmo.io/ws"
    #endif
    
    /// API request timeout in seconds
    static let requestTimeout: TimeInterval = 30.0
    
    /// Token refresh threshold in seconds (refresh when less than this time remaining)
    static let tokenRefreshThreshold: TimeInterval = 300 // 5 minutes
}
