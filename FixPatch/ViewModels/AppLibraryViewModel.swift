import Foundation
import Combine
import SwiftUI  // This will help ensure the Models folder is in the search path

class AppLibraryViewModel: ObservableObject {
    private let appCatalogService = AppCatalogService.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var apps: [AppModel] = []
    @Published var filteredApps: [AppModel] = []
    @Published var categories: [String] = []
    @Published var selectedCategory: String?
    @Published var isLoading = false
    @Published var error: String?
    @Published var installationInProgress = false
    @Published var searchText = "" {
        didSet {
            filterApps()
        }
    }
    
    init() {
        // Observe app catalog changes
        appCatalogService.$apps
            .sink { [weak self] apps in
                self?.apps = apps
                self?.filterApps()
            }
            .store(in: &cancellables)
        
        appCatalogService.$categories
            .sink { [weak self] categories in
                self?.categories = categories
            }
            .store(in: &cancellables)
        
        appCatalogService.$isLoading
            .sink { [weak self] isLoading in
                self?.isLoading = isLoading
            }
            .store(in: &cancellables)
        
        appCatalogService.$error
            .sink { [weak self] error in
                self?.error = error
            }
            .store(in: &cancellables)
    }
    
    func loadApps() {
        appCatalogService.loadApps()
    }
    
    func installApp(appId: String) -> AnyPublisher<Bool, APIError> {
        installationInProgress = true
        
        return appCatalogService.installApp(appId: appId)
            .handleEvents(
                receiveCompletion: { [weak self] completion in
                    self?.installationInProgress = false
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveCancel: { [weak self] in
                    self?.installationInProgress = false
                }
            )
            .eraseToAnyPublisher()
    }
    
    func uninstallApp(appId: String) -> AnyPublisher<Bool, APIError> {
        installationInProgress = true
        
        return appCatalogService.uninstallApp(appId: appId)
            .handleEvents(
                receiveCompletion: { [weak self] completion in
                    self?.installationInProgress = false
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveCancel: { [weak self] in
                    self?.installationInProgress = false
                }
            )
            .eraseToAnyPublisher()
    }
    
    private func filterApps() {
        var filtered = apps
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { app in
                app.name.lowercased().contains(searchText.lowercased()) ||
                app.description.lowercased().contains(searchText.lowercased()) ||
                app.category.lowercased().contains(searchText.lowercased())
            }
        }
        
        // Filter by category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        filteredApps = filtered
    }
    
    func selectCategory(_ category: String?) {
        selectedCategory = category
        filterApps()
    }
}
