import Foundation
import Combine

// Define APIError here for immediate compilation
enum APIError: Error, LocalizedError {
    case networkError
    case invalidResponse
    case unauthorized
    case serverError
    case badRequest(String)
    case unknown(String)
    case invalidURL
    case decodingError
    case encodingError
    case noData
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection failed"
        case .invalidResponse:
            return "Invalid server response"
        case .unauthorized:
            return "Authentication required"
        case .serverError:
            return "Server error occurred"
        case .badRequest(let message):
            return "Bad request: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        case .invalidURL:
            return "Invalid URL"
        case .decodingError:
            return "Failed to decode response"
        case .encodingError:
            return "Failed to encode request"
        case .noData:
            return "No data received"
        }
    }
}

class AppLibraryViewModel: ObservableObject {
    @Published var apps: [AppModel] = []
    @Published var categories: [String] = []
    @Published var isLoading = false
    @Published var selectedApp: AppModel?
    @Published var error: APIError?
    @Published var searchText = ""
    @Published var selectedCategory: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let appCatalogService: SupabaseAppCatalogService
    
    init(appCatalogService: SupabaseAppCatalogService = .shared) {
        self.appCatalogService = appCatalogService
        fetchCategories()
        fetchApps()
    }
    
    func fetchCategories() {
        appCatalogService.getCategories()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] (completion: Subscribers.Completion<APIError>) in
                if case .failure(let error) = completion {
                    self?.error = error
                }
            }, receiveValue: { [weak self] (categories: [String]) in
                self?.categories = categories
            })
            .store(in: &cancellables)
    }
    
    func fetchApps() {
        isLoading = true
        
        appCatalogService.fetchAvailableApps()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] (completion: Subscribers.Completion<APIError>) in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.error = error
                }
            }, receiveValue: { [weak self] (apps: [AppModel]) in
                self?.apps = apps
            })
            .store(in: &cancellables)
    }
    
    func launchApp(_ app: AppModel) {
        isLoading = true
        selectedApp = app
        
        // Mock launch app functionality
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoading = false
            // Simulate successful launch
        }
    }
    
    func selectCategory(_ category: String?) {
        if selectedCategory == category {
            selectedCategory = nil
        } else {
            selectedCategory = category
        }
        fetchApps()
    }
    
    func searchApps() {
        fetchApps()
    }
    
    func clearSearch() {
        searchText = ""
        fetchApps()
    }
}