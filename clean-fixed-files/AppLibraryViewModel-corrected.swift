import Foundation
import Combine

public class AppLibraryViewModel: ObservableObject {
    @Published public var apps: [AppModel] = []
    @Published public var featuredApps: [AppModel] = []
    @Published public var recentApps: [AppModel] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    
    // Additional properties needed by the Views
    @Published public var categories: [String] = ["All", "Productivity", "Communication", "Utilities", "Security"]
    @Published public var searchText: String = ""
    @Published public var selectedApp: AppModel? = nil
    @Published public var error: ShaydZ_APIError? = nil
    
    // Use explicit ShaydZ_ prefixes to avoid ambiguity
    private var cancellables = Set<AnyCancellable>()
    private let appCatalogService: ShaydZ_AppCatalogService
    
    public init(appCatalogService: ShaydZ_AppCatalogService = ShaydZ_AppCatalogService.shared) {
        self.appCatalogService = appCatalogService
        loadAppCatalog()
    }
    
    /// Load the app catalog
    public func loadAppCatalog() {
        isLoading = true
        errorMessage = nil
        error = nil
        
        appCatalogService.fetchAppCatalog { [weak self] (result: Result<[AppModel], ShaydZ_APIError>) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let appsList):
                    self.apps = appsList
                    self.processFeaturedAndRecentApps()
                case .failure(let apiError):
                    self.errorMessage = apiError.localizedDescription
                    self.error = apiError
                }
            }
        }
    }
    
    /// Process and categorize apps
    private func processFeaturedAndRecentApps() {
        // Extract featured apps
        featuredApps = apps.filter { $0.isFeatured }
        
        // Sort by last used date to get most recently used apps
        recentApps = apps.filter { $0.lastUsed != nil }
            .sorted { ($0.lastUsed ?? Date.distantPast) > ($1.lastUsed ?? Date.distantPast) }
            .prefix(5)
            .map { $0 }
    }
    
    /// Search apps based on the search text
    public func searchApps() -> [AppModel] {
        if searchText.isEmpty {
            return apps
        } else {
            return apps.filter { app in
                app.name.localizedCaseInsensitiveContains(searchText) ||
                app.description.localizedCaseInsensitiveContains(searchText) ||
                app.categories.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    /// Launch a specific app
    public func launchApp(_ app: AppModel, completion: @escaping (Result<Bool, ShaydZ_APIError>) -> Void) {
        isLoading = true
        errorMessage = nil
        error = nil
        
        appCatalogService.launchApp(appId: app.id) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let success):
                    // Update last used date for the app
                    if let index = self.apps.firstIndex(where: { $0.id == app.id }) {
                        self.apps[index].lastUsed = Date()
                        self.processFeaturedAndRecentApps()
                    }
                    completion(.success(success))
                case .failure(let apiError):
                    self.errorMessage = apiError.localizedDescription
                    self.error = apiError
                    completion(.failure(apiError))
                }
            }
        }
    }
    
    /// Install a specific app
    public func installApp(_ app: AppModel, completion: @escaping (Result<Bool, ShaydZ_APIError>) -> Void) {
        isLoading = true
        errorMessage = nil
        error = nil
        
        appCatalogService.installApp(appId: app.id) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let success):
                    // Update installed status for the app
                    if let index = self.apps.firstIndex(where: { $0.id == app.id }) {
                        self.apps[index].isInstalled = true
                        self.processFeaturedAndRecentApps()
                    }
                    completion(.success(success))
                case .failure(let apiError):
                    self.errorMessage = apiError.localizedDescription
                    self.error = apiError
                    completion(.failure(apiError))
                }
            }
        }
    }
}

// Note: Type alias removed as it was causing recursion
// The class name is already AppLibraryViewModel, so no alias needed
