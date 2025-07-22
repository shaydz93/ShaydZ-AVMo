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
    
    private let appService: AppCatalogService
    private var cancellables = Set<AnyCancellable>()
    
    init(appService: AppCatalogService = AppCatalogService()) {
        self.appService = appService
        loadApps()
    }
    
    /// Load all available apps from the catalog
    func loadApps() {
        isLoading = true
        
        appService.getApps()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error
                    }
                },
                receiveValue: { [weak self] apps in
                    self?.apps = apps
                    
                    // Extract unique categories
                    let allCategories = apps.flatMap { $0.categories }
                    self?.categories = Array(Set(allCategories)).sorted()
                }
            )
            .store(in: &cancellables)
    }
    
    /// Search for apps based on current search text
    func searchApps() {
        guard !searchText.isEmpty else {
            loadApps() // Reset to show all apps if search is cleared
            return
        }
        
        isLoading = true
        
        appService.searchApps(query: searchText)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error
                    }
                },
                receiveValue: { [weak self] apps in
                    self?.apps = apps
                }
            )
            .store(in: &cancellables)
    }
    
    /// Filter apps by selected category
    func filterByCategory() {
        guard let category = selectedCategory else {
            loadApps() // Reset to show all apps if no category is selected
            return
        }
        
        appService.getAppsByCategory(category: category)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error
                    }
                },
                receiveValue: { [weak self] apps in
                    self?.apps = apps
                }
            )
            .store(in: &cancellables)
    }
}
