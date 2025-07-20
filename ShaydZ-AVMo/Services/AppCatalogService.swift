import Foundation
import Combine

// Import shared error definitions
// Define APIError here for immediate compilation
enum APIError: Error, LocalizedError {
    case networkError
    case invalidResponse
    case unauthorized
    case serverError
    case badRequest(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError: return "Network error"
        case .invalidResponse: return "Invalid response"
        case .unauthorized: return "Unauthorized"
        case .serverError: return "Server error"
        case .badRequest(let msg): return "Bad request: \(msg)"
        case .unknown(let msg): return "Unknown error: \(msg)"
        }
    }
}

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
        // Mock implementation for compilation
        let mockApps = [
            AppModel(id: UUID(), name: "Demo App", description: "Demo app", iconName: "app.fill"),
            AppModel(id: UUID(), name: "Test App", description: "Test app", iconName: "gear")
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
        let mockCategories = ["Productivity", "Games", "Utilities", "Entertainment"]
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
