import Foundation
import Combine

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
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.error = error
                }
            }, receiveValue: { [weak self] categories in
                self?.categories = categories
            })
            .store(in: &cancellables)
    }
    
    func fetchApps() {
        isLoading = true
        
        appCatalogService.fetchAvailableApps(
            category: selectedCategory,
            search: searchText.isEmpty ? nil : searchText
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { [weak self] completion in
            self?.isLoading = false
            
            if case .failure(let error) = completion {
                self?.error = error
            }
        }, receiveValue: { [weak self] apps in
            self?.apps = apps
        })
        .store(in: &cancellables)
    }
    
    func launchApp(_ app: AppModel) {
        isLoading = true
        selectedApp = app
        
        appCatalogService.launchApp(appId: app.id.uuidString)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.error = error
                    self?.selectedApp = nil
                }
            }, receiveValue: { [weak self] success in
                if !success {
                    self?.selectedApp = nil
                }
            })
            .store(in: &cancellables)
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