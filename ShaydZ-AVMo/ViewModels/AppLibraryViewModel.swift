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

class AppLibraryViewModel: ObservableObject {
    @Published var apps: [AppModel] = []
    @Published var categories: [String] = []
    @Published var isLoading = false
    @Published var selectedApp: AppModel?
    @Published var error: APIError?
    @Published var searchText = ""
    @Published var selectedCategory: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let appCatalogService: AppCatalogService
    
    init(appCatalogService: AppCatalogService = .shared) {
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