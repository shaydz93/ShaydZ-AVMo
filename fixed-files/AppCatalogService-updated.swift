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

/// Service for accessing app catalog data
class AppCatalogService: ObservableObject {
    static let shared = AppCatalogService()
    
    private let networkService: NetworkService
    private let baseURL: URL?
    private var cancellables = Set<AnyCancellable>()
    
    init(networkService: NetworkService = NetworkService.shared) {
        self.networkService = networkService
        self.baseURL = URL(string: APIConfig.appsEndpoint)
    }
    
    /// Get all available applications
    func getApps() -> AnyPublisher<[AppModel], APIError> {
        guard let baseURL = baseURL else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return networkService.get([AppModel].self, from: baseURL)
    }
    
    /// Get apps by category
    func getAppsByCategory(category: String) -> AnyPublisher<[AppModel], APIError> {
        guard let baseURL = baseURL else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        let categoryURL = baseURL.appendingPathComponent("category").appendingPathComponent(category)
        return networkService.get([AppModel].self, from: categoryURL)
    }
    
    /// Get apps by popularity
    func getPopularApps(limit: Int = 10) -> AnyPublisher<[AppModel], APIError> {
        guard let baseURL = baseURL else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        let popularURL = baseURL.appendingPathComponent("popular").appendingQueryItem(name: "limit", value: "\(limit)")
        return networkService.get([AppModel].self, from: popularURL)
    }
    
    /// Get app details by ID
    func getAppDetails(appId: String) -> AnyPublisher<AppModel, APIError> {
        guard let baseURL = baseURL else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        let detailsURL = baseURL.appendingPathComponent(appId)
        return networkService.get(AppModel.self, from: detailsURL)
    }
    
    /// Search for apps with query
    func searchApps(query: String) -> AnyPublisher<[AppModel], APIError> {
        guard let baseURL = baseURL else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        let searchURL = baseURL.appendingPathComponent("search").appendingQueryItem(name: "q", value: query)
        return networkService.get([AppModel].self, from: searchURL)
    }
    
    /// Get new and updated apps
    func getNewApps(limit: Int = 10) -> AnyPublisher<[AppModel], APIError> {
        guard let baseURL = baseURL else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        let newURL = baseURL.appendingPathComponent("new").appendingQueryItem(name: "limit", value: "\(limit)")
        return networkService.get([AppModel].self, from: newURL)
    }
    
    /// Get app recommendations based on user history
    func getRecommendedApps() -> AnyPublisher<[AppModel], APIError> {
        guard let baseURL = baseURL else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        let recommendedURL = baseURL.appendingPathComponent("recommended")
        return networkService.get([AppModel].self, from: recommendedURL)
    }
}

// Extension to make URL construction easier
extension URL {
    func appendingQueryItem(name: String, value: String) -> URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        var queryItems = components?.queryItems ?? []
        queryItems.append(URLQueryItem(name: name, value: value))
        components?.queryItems = queryItems
        return components?.url ?? self
    }
}
