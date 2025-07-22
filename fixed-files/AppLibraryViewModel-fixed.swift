import Foundation
import Combine

class AppLibraryViewModel: ObservableObject {
    @Published var apps: [AppModel] = []
    @Published var featuredApps: [AppModel] = []
    @Published var recentApps: [AppModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Use explicit ShaydZ_ prefixes to avoid ambiguity
    private var cancellables = Set<AnyCancellable>()
    private let appCatalogService: ShaydZ_AppCatalogService
    
    init(appCatalogService: ShaydZ_AppCatalogService = ShaydZ_AppCatalogService.shared) {
        self.appCatalogService = appCatalogService
        loadAppCatalog()
    }
    
    /// Load the app catalog
    func loadAppCatalog() {
        isLoading = true
        errorMessage = nil
        
        appCatalogService.fetchAppCatalog { [weak self] (result: Result<[AppModel], ShaydZ_APIError>) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let appsList):
                    self.apps = appsList
                    self.processFeaturedAndRecentApps()
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
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
    
    /// Launch a specific app
    func launchApp(_ app: AppModel, completion: @escaping (Result<Bool, ShaydZ_APIError>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        // Simulated app launch process for compilation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isLoading = false
            
            // Update last used date for the app
            if let index = self.apps.firstIndex(where: { $0.id == app.id }) {
                self.apps[index].lastUsed = Date()
                self.processFeaturedAndRecentApps()
            }
            
            completion(.success(true))
        }
    }
    
    /// Install a specific app
    func installApp(_ app: AppModel, completion: @escaping (Result<Bool, ShaydZ_APIError>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        // Simulated app installation process for compilation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.isLoading = false
            
            // Update installed status for the app
            if let index = self.apps.firstIndex(where: { $0.id == app.id }) {
                self.apps[index].isInstalled = true
                self.processFeaturedAndRecentApps()
            }
            
            completion(.success(true))
        }
    }
}
