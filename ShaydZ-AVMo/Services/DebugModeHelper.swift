import Foundation

/// Debug mode utilities for development and testing
struct DebugModeHelper {
    
    /// Check if running in debug mode
    static var isDebugMode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    /// Generate demo token for testing purposes
    static func generateDemoToken(for username: String) -> String? {
        guard isDebugMode else { return nil }
        return "demo_token_\(username)_\(Date().timeIntervalSince1970)"
    }
    
    /// Get debug-appropriate endpoint URLs
    static func getEndpointURL(for service: String) -> String {
        #if DEBUG
        switch service {
        case "auth":
            return "http://localhost:8081"
        case "apps":
            return "http://localhost:8083"
        case "vms":
            return "http://localhost:8082"
        case "gateway":
            return "http://localhost:8080"
        default:
            return "http://localhost:8080"
        }
        #else
        return "https://api.shaydz-avmo.com"
        #endif
    }
    
    /// Debug logging utility
    static func debugLog(_ message: String, category: String = "General") {
        #if DEBUG
        print("🔧 DEBUG [\(category)]: \(message)")
        #endif
    }
}
