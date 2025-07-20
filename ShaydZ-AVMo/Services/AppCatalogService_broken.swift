import Foundation
import Combine

// Core API Error for the app
enum AppCatalogAPIError: Error {
    case networkError
    case invalidResponse
    case unauthorized
    case serverError
    case unknown(String)
}

// Mock NetworkService for compilation
class AppCatalogNetworkService {
    static let shared = AppCatalogNetworkService()
    
    func get<T: Codable>(_ type: T.Type, from url: URL) -> AnyPublisher<T, AppCatalogAPIError> {
        return Just([] as! T)
            .setFailureType(to: AppCatalogAPIError.self)
            .eraseToAnyPublisher()
    }
}

// Mock SupabaseDatabaseService for compilation
class AppCatalogSupabaseService {
    static let shared = AppCatalogSupabaseService()
}

// Mock SupabaseAuthService for compilation  
class AppCatalogAuthService: ObservableObject {
    static let shared = AppCatalogAuthService()
    @Published var currentUser: String? = nil
}

// App utilities from AppUtilities.swift
class AppIconMapper {
    static func iconName(for packageName: String) -> String {
        return "app.fill"
    }
}

class AppCategoryManager {
    static func filterApps(_ apps: [AppDetailsModel], by category: String) -> [AppDetailsModel] {
        return apps.filter { $0.category == category }
    }
}

/// App catalog response models
struct AppDetailsModel: Codable {
    let id: String
    let name: String
    let packageName: String
    let description: String
    let version: String
    let versionCode: Int
    let iconUrl: String?
    let category: String
    let permissions: [String]
    let size: Int64
    let isEnterprise: Bool
    let isSecure: Bool
    let minimumAndroidVersion: Int
    let targetAndroidVersion: Int
    let lastUpdated: String
    let developer: String
    let rating: Double
    let downloadCount: Int
    let requiresVPN: Bool
    let supportedArchitectures: [String]
}

struct AppUploadRequest: Codable {
    let name: String
    let packageName: String
    let version: String
    let category: String
    let description: String
    let iconData: Data?
    let apkData: Data
    let permissions: [String]
    let isEnterprise: Bool
    let developerInfo: DeveloperInfo
    
    struct DeveloperInfo: Codable {
        let name: String
        let email: String
        let organization: String?
    }
}

struct AppUploadResponse: Codable {
    let success: Bool
    let appId: String?
    let message: String
    let uploadedAt: String
    let lastUpdated: String
}

class AppCatalogService: ObservableObject {
    static let shared = AppCatalogService()
    private let networkService = AppCatalogNetworkService.shared
    private let supabaseDatabase = AppCatalogSupabaseService.shared
    private let authService = AppCatalogAuthService.shared
    private var cancellables = Set<AnyCancellable>()
    
    /// Published properties for reactive UI updates
    @Published var availableApps: [AppModel] = []
    @Published var userInstalledApps: [AppModel] = []
    @Published var categories: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    /// Map package name to SF Symbol icon name
    private func iconNameFromPackage(_ packageName: String) -> String {
        return AppIconMapper.iconName(for: packageName)
    }

    /// Load available apps from backend
    func fetchAvailableApps() -> AnyPublisher<[AppModel], AppCatalogAPIError> {
        // Mock implementation for compilation
        let mockApps = [
            AppModel(id: "1", name: "Demo App", description: "Demo app", iconName: "app.fill"),
            AppModel(id: "2", name: "Test App", description: "Test app", iconName: "gear")
        ]
        
        return Just(mockApps)
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .setFailureType(to: AppCatalogAPIError.self)
            .handleEvents(receiveOutput: { [weak self] apps in
                DispatchQueue.main.async {
                    self?.availableApps = apps
                }
            })
            .eraseToAnyPublisher()
    }
    
    /// Get app categories
    func getCategories() -> AnyPublisher<[String], AppCatalogAPIError> {
        let mockCategories = ["Productivity", "Games", "Utilities", "Entertainment"]
        return Just(mockCategories)
            .setFailureType(to: AppCatalogAPIError.self)
            .eraseToAnyPublisher()
    }
    
    /// Generate local test data for development
    private func generateLocalTestData() -> [AppModel] {
        return [
            AppModel(
                id: UUID(),
                name: "Enterprise Security Suite",
                description: "Comprehensive security toolkit for enterprise environments",
                iconName: iconNameFromPackage("com.enterprise.security")
            ),
            AppModel(
                id: UUID(), 
                name: "Corporate Communication Hub",
                description: "Secure messaging and collaboration platform",
                iconName: iconNameFromPackage("com.corporate.comms")
            ),
            AppModel(
                id: UUID(),
                name: "Business Analytics Pro",
                description: "Advanced analytics and reporting tools",
                iconName: iconNameFromPackage("com.business.analytics")
            ),
            AppModel(
                id: UUID(),
                name: "Mobile VPN Client",
                description: "Secure VPN access for remote work",
                iconName: iconNameFromPackage("com.mobile.vpn")
            ),
            AppModel(
                id: UUID(),
                name: "Document Scanner Plus",
                description: "Professional document scanning and processing",
                iconName: iconNameFromPackage("com.document.scanner")
            )
        ]
    }
                requiresPermissions: ["Storage", "Network"],
                downloadSizeMB: 203,
                isEnterpriseApp: true
            ),
            AppModel(
                id: "005",
                name: "Productivity Master",
                packageName: "com.productivity.master",
                iconName: iconNameFromPackage("com.productivity.master"),
                description: "All-in-one productivity suite for business operations",
                category: "Productivity",
                version: "2.7.4",
                isInstalled: true,
                requiresPermissions: ["Storage", "Calendar"],
                downloadSizeMB: 89,
                isEnterpriseApp: true
            )
        ]
    }
    
    /// Fetch app categories
    func getCategories() -> AnyPublisher<[String], APIError> {
        #if DEBUG
        if networkService.getAuthToken()?.starts(with: "demo_token_") ?? false {
            return Just(["Productivity", "Security", "Communication", "Development", "Finance"])
                .delay(for: .seconds(0.5), scheduler: RunLoop.main)
                .setFailureType(to: APIError.self)
                .eraseToAnyPublisher()
        }
        #endif
        
        return supabaseDatabase.fetchAppCategories()
            .mapSupabaseError()
            .handleEvents(receiveOutput: { [weak self] categories in
                DispatchQueue.main.async {
                    self?.categories = categories
                }
            })
            .eraseToAnyPublisher()
    }
    
    /// Install app for current user
    func installApp(appId: String) -> AnyPublisher<Bool, APIError> {
        guard let userId = SupabaseAuthService.shared.currentUser?.id else {
            return Fail(error: APIError.unauthorized).eraseToAnyPublisher()
        }
        
        return supabaseDatabase.installApp(userId: userId, appId: appId)
            .map { _ in true }
            .mapSupabaseError()
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.fetchUserInstalledApps()
            })
            .eraseToAnyPublisher()
    }
    
    /// Uninstall app for current user
    func uninstallApp(appId: String) -> AnyPublisher<Bool, APIError> {
        guard let userId = SupabaseAuthService.shared.currentUser?.id else {
            return Fail(error: APIError.unauthorized).eraseToAnyPublisher()
        }
        
        return supabaseDatabase.uninstallApp(userId: userId, appId: appId)
            .map { _ in true }
            .mapSupabaseError()
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.fetchUserInstalledApps()
            })
            .eraseToAnyPublisher()
    }
    
    /// Fetch user installed apps
    func fetchUserInstalledApps() {
        guard let userId = SupabaseAuthService.shared.currentUser?.id else { return }
        
        supabaseDatabase.fetchUserInstalledApps(userId: userId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to fetch user installed apps: \(error)")
                    }
                },
                receiveValue: { [weak self] apps in
                    DispatchQueue.main.async {
                        self?.userInstalledApps = apps
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    /// Search apps with filters
    func searchApps(query: String? = nil, category: String? = nil) -> [AppModel] {
        return AppCategoryManager.shared.searchApps(availableApps, query: query, category: category)
    }
}
