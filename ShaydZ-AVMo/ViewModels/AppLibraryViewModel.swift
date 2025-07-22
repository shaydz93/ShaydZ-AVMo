import Foundation
import Combine

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
    
    func installApp(_ app: AppModel) {
        isLoading = true
        
        // Mock install app functionality
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.isLoading = false
            // Simulate successful installation
            print("App \(app.name) installed successfully")
        }
    }
    
    func uninstallApp(_ app: AppModel) {
        isLoading = true
        
        // Mock uninstall app functionality
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoading = false
            // Simulate successful uninstallation
            print("App \(app.name) uninstalled successfully")
        }
    }
    
    // Computed property for backward compatibility
    var errorMessage: String? {
        return error?.localizedDescription
    }
}