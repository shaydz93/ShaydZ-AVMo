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
    
    /// Install an app
    func installApp(_ app: AppModel) -> AnyPublisher<Bool, AppCatalogAPIError> {
        return Just(true)
            .delay(for: .seconds(2), scheduler: RunLoop.main)
            .setFailureType(to: AppCatalogAPIError.self)
            .eraseToAnyPublisher()
    }
    
    /// Search apps
    func searchApps(query: String) -> AnyPublisher<[AppModel], AppCatalogAPIError> {
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
