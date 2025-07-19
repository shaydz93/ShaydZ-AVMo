//
//  APIConfig.swift
//  ShaydZ-AVMo
//
//  Auto-generated API Configuration
//

import Foundation

struct APIConfig {
    static let shared = APIConfig()
    
    // MARK: - Backend Service URLs
    
    #if DEBUG
    // Development URLs (localhost)
    static let baseURL = "http://localhost:8080"
    static let authServiceURL = "http://localhost:8081"
    static let appCatalogURL = "http://localhost:8083"
    static let vmOrchestratorURL = "http://localhost:8082"
    #else
    // Production URLs (update these for production deployment)
    static let baseURL = "https://api.shaydz-avmo.com"
    static let authServiceURL = "https://auth.shaydz-avmo.com"
    static let appCatalogURL = "https://catalog.shaydz-avmo.com"
    static let vmOrchestratorURL = "https://vm.shaydz-avmo.com"
    #endif
    
    // MARK: - API Endpoints
    
    struct Endpoints {
        // Authentication
        static let login = "/login"
        static let logout = "/logout"
        static let profile = "/profile"
        static let refreshToken = "/refresh"
        
        // App Catalog
        static let apps = "/apps"
        static let appSearch = "/apps/search"
        static let appDetails = "/apps/:id"
        static let appInstall = "/apps/:id/install"
        
        // Virtual Machines
        static let vms = "/vms"
        static let vmStart = "/vms/:id/start"
        static let vmStop = "/vms/:id/stop"
        static let vmStatus = "/vms/:id/status"
        static let vmConnect = "/vms/:id/connect"
        
        // Health Checks
        static let health = "/health"
        static let status = "/status"
    }
    
    // MARK: - Configuration
    
    struct Network {
        static let timeoutInterval: TimeInterval = 30.0
        static let retryAttempts = 3
        static let maxConcurrentRequests = 10
    }
    
    struct Authentication {
        static let tokenKey = "auth_token"
        static let userKey = "current_user"
        static let tokenExpiryKey = "token_expiry"
        static let autoRefreshThreshold: TimeInterval = 300 // 5 minutes
    }
    
    struct Features {
        static let appCatalogEnabled = true
        static let vmManagementEnabled = true
        static let offlineModeEnabled = false
        static let pushNotificationsEnabled = true
        static let analyticsEnabled = false
    }
    
    // MARK: - Demo Data
    
    struct Demo {
        static let username = "demo"
        static let password = "password"
        static let isEnabled = true
    }
}

// MARK: - URL Builder Extension

extension APIConfig {
    static func url(for endpoint: String, service: ServiceType = .gateway) -> String {
        let baseURL: String
        
        switch service {
        case .gateway:
            baseURL = APIConfig.baseURL
        case .auth:
            baseURL = APIConfig.authServiceURL
        case .appCatalog:
            baseURL = APIConfig.appCatalogURL
        case .vmOrchestrator:
            baseURL = APIConfig.vmOrchestratorURL
        }
        
        return "\(baseURL)\(endpoint)"
    }
    
    static func url(for endpoint: String, withId id: String, service: ServiceType = .gateway) -> String {
        let endpointWithId = endpoint.replacingOccurrences(of: ":id", with: id)
        return url(for: endpointWithId, service: service)
    }
}

enum ServiceType {
    case gateway
    case auth
    case appCatalog
    case vmOrchestrator
}