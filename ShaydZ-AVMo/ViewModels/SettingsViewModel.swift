import Foundation
import Combine

enum ConnectionQuality: String, CaseIterable {
    case low = "Low - Save Data"
    case medium = "Medium - Balanced"
    case high = "High - Best Quality"
}

enum SessionTimeout: Int, CaseIterable {
    case fiveMinutes = 5
    case tenMinutes = 10
    case fifteenMinutes = 15
    case thirtyMinutes = 30
    case oneHour = 60
    case never = -1
    
    var displayName: String {
        switch self {
        case .fiveMinutes:
            return "5 Minutes"
        case .tenMinutes:
            return "10 Minutes"
        case .fifteenMinutes:
            return "15 Minutes"
        case .thirtyMinutes:
            return "30 Minutes"
        case .oneHour:
            return "1 Hour"
        case .never:
            return "Never"
        }
    }
}

class SettingsViewModel: ObservableObject {
    // User info
    @Published var userName = "Demo User"
    @Published var userEmail = "demo@example.com"
    
    // Connection settings
    @Published var rememberLastServer = true
    @Published var selectedConnectionQuality: ConnectionQuality = .medium
    @Published var optimizeForBattery = true
    @Published var serverAddress = "avmo.shaydz.com"
    
    // Security settings
    @Published var useBiometricAuth = true
    @Published var sessionTimeout: SessionTimeout = .fifteenMinutes
    @Published var allowCopyPasteBetweenEnvs = false
    
    // App info
    let appVersion = "1.0.0 (MVP)"
    
    func signOut() {
        // In real app, this would handle sign out logic
        print("User signed out")
    }
}
