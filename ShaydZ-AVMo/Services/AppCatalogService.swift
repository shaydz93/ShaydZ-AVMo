import Foundation
import Combine

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
    private let networkService = NetworkService.shared
    private let supabaseDatabase = SupabaseDatabaseService.shared
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
        return AppIconMapper.shared.iconName(for: packageName)
    }

    /// Load available apps from backend
    func fetchAvailableApps() -> AnyPublisher<[AppModel], APIError> {
        #if DEBUG
        // For demo/testing, use local data when in debug mode
        if networkService.getAuthToken()?.starts(with: "demo_token_") ?? false {
            return Just(generateLocalTestData())
                .delay(for: .seconds(1), scheduler: RunLoop.main)
                .setFailureType(to: APIError.self)
                .eraseToAnyPublisher()
        }
        #endif
        
        return supabaseDatabase.fetchApps()
            .mapSupabaseError()
            .handleEvents(receiveOutput: { [weak self] apps in
                DispatchQueue.main.async {
                    self?.availableApps = apps
                }
            })
            .eraseToAnyPublisher()
    }
    
    /// Generate local test data for development
    private func generateLocalTestData() -> [AppModel] {
        return [
            AppModel(
                id: "001",
                name: "Enterprise Security Suite",
                packageName: "com.enterprise.security",
                iconName: iconNameFromPackage("com.enterprise.security"),
                description: "Comprehensive security toolkit for enterprise environments",
                category: "Security",
                version: "2.1.0",
                isInstalled: false,
                requiresPermissions: ["Camera", "Microphone", "Location"],
                downloadSizeMB: 45,
                isEnterpriseApp: true
            ),
            AppModel(
                id: "002", 
                name: "Corporate Communication Hub",
                packageName: "com.corporate.comms",
                iconName: iconNameFromPackage("com.corporate.comms"),
                description: "Secure messaging and collaboration platform",
                category: "Communication",
                version: "1.8.3",
                isInstalled: true,
                requiresPermissions: ["Camera", "Microphone"],
                downloadSizeMB: 78,
                isEnterpriseApp: true
            ),
            AppModel(
                id: "003",
                name: "Finance Analytics Pro",
                packageName: "com.finance.analytics",
                iconName: iconNameFromPackage("com.finance.analytics"),
                description: "Advanced financial analysis and reporting tools",
                category: "Finance",
                version: "3.2.1",
                isInstalled: false,
                requiresPermissions: ["Storage"],
                downloadSizeMB: 126,
                isEnterpriseApp: true
            ),
            AppModel(
                id: "004",
                name: "Development Tools Kit",
                packageName: "com.dev.toolkit",
                iconName: iconNameFromPackage("com.dev.toolkit"),
                description: "Complete development environment for mobile applications",
                category: "Development",
                version: "4.0.2",
                isInstalled: false,
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
