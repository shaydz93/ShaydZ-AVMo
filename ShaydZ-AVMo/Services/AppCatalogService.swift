import Foundation

import Combine

// Mock NetworkService for compilation
class AppCatalogNetworkService {
    static let shared = AppCatalogNetworkService()
    
    func get<T: Codable>(_ type: T.Type, from url: URL) -> AnyPublisher<T, APIError> {
        return Just([] as! T)
            .setFailureType(to: APIError.self)
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

// App utilities
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
}

struct AppInstallResponse: Codable {
    let success: Bool
    let installId: String?
    let message: String
    let estimatedTime: Int
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
    
    init() {
        loadInitialData()
    }
    
    /// Map package name to SF Symbol icon name
    private func iconNameFromPackage(_ packageName: String) -> String {
        return AppIconMapper.iconName(for: packageName)
    }

    /// Load available apps from backend
    func fetchAvailableApps() -> AnyPublisher<[AppModel], APIError> {
        // Mock implementation with enhanced AppModel properties
        let mockApps = [
            AppModel(
                name: "Microsoft Word",
                description: "Create, edit, and share documents with real-time collaboration",
                iconName: "doc.text.fill",
                category: "Productivity",
                version: "16.0.1",
                size: "145 MB",
                isInstalled: true,
                isRunning: false
            ),
            AppModel(
                name: "Adobe Photoshop",
                description: "Professional image editing and graphic design software",
                iconName: "photo.fill",
                category: "Design",
                version: "2024.1",
                size: "2.1 GB",
                isInstalled: false,
                isRunning: false
            ),
            AppModel(
                name: "Chrome",
                description: "Fast, secure web browser built for the modern web",
                iconName: "globe",
                category: "Internet",
                version: "118.0",
                size: "89 MB",
                isInstalled: true,
                isRunning: true
            ),
            AppModel(
                name: "Slack",
                description: "Team communication and collaboration platform",
                iconName: "message.fill",
                category: "Communication",
                version: "4.35.0",
                size: "156 MB",
                isInstalled: false,
                isRunning: false
            ),
            AppModel(
                name: "VS Code",
                description: "Lightweight but powerful code editor",
                iconName: "curlybraces",
                category: "Development",
                version: "1.84.2",
                size: "234 MB",
                isInstalled: true,
                isRunning: false
            )
        ]
        
        return Just(mockApps)
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .setFailureType(to: APIError.self)
            .handleEvents(receiveOutput: { [weak self] apps in
                DispatchQueue.main.async {
                    self?.availableApps = apps
                }
            })
            .eraseToAnyPublisher()
    }
    
    /// Get app categories
    func getCategories() -> AnyPublisher<[String], APIError> {
        let mockCategories = ["Productivity", "Design", "Internet", "Communication", "Development", "Entertainment", "Utilities"]
        return Just(mockCategories)
            .setFailureType(to: APIError.self)
            .eraseToAnyPublisher()
    }
    
    /// Install an app
    func installApp(_ app: AppModel) -> AnyPublisher<Bool, APIError> {
        return Just(true)
            .delay(for: .seconds(2), scheduler: RunLoop.main)
            .setFailureType(to: APIError.self)
            .eraseToAnyPublisher()
    }
    
    /// Search apps
    func searchApps(query: String) -> AnyPublisher<[AppModel], APIError> {
        return fetchAvailableApps()
            .map { apps in
                apps.filter { $0.name.localizedCaseInsensitiveContains(query) }
            }
            .eraseToAnyPublisher()
    }
    
    private func loadInitialData() {
        // Load initial data
        fetchAvailableApps()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] apps in
                    self?.availableApps = apps
                }
            )
            .store(in: &cancellables)
    }
}
