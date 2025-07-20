import Foundation
import Combine
import SwiftUI  // This will help ensure the Models folder is in the search path

class AppCatalogService {
    static let shared = AppCatalogService()
    
    private let networkService = NetworkService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Published properties
    @Published var apps: [AppModel] = []
    @Published var categories: [String] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private init() {
        // Private initialization to enforce singleton pattern
    }
    
    func loadApps() {
        isLoading = true
        error = nil
        
        let endpoint = "app-catalog/apps"
        
        networkService.get(endpoint: endpoint)
            .decode(type: [AppModel].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = "Failed to load apps: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] apps in
                self?.apps = apps
                self?.extractCategories(from: apps)
            }
            .store(in: &cancellables)
    }
    
    func getAppDetails(appId: String) -> AnyPublisher<AppModel, APIError> {
        let endpoint = "app-catalog/apps/\(appId)"
        
        return networkService.get(endpoint: endpoint)
            .decode(type: AppModel.self, decoder: JSONDecoder())
            .mapError { error -> APIError in
                if let apiError = error as? APIError {
                    return apiError
                } else {
                    return APIError.decodingFailed
                }
            }
            .eraseToAnyPublisher()
    }
    
    func installApp(appId: String) -> AnyPublisher<Bool, APIError> {
        let endpoint = "vm-orchestrator/install"
        let parameters: [String: Any] = ["appId": appId]
        
        return networkService.post(endpoint: endpoint, parameters: parameters)
            .map { _ in true }
            .mapError { error -> APIError in
                if let apiError = error as? APIError {
                    return apiError
                } else {
                    return APIError.unknown(error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
    
    func uninstallApp(appId: String) -> AnyPublisher<Bool, APIError> {
        let endpoint = "vm-orchestrator/uninstall"
        let parameters: [String: Any] = ["appId": appId]
        
        return networkService.post(endpoint: endpoint, parameters: parameters)
            .map { _ in true }
            .mapError { error -> APIError in
                if let apiError = error as? APIError {
                    return apiError
                } else {
                    return APIError.unknown(error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
    
    private func extractCategories(from apps: [AppModel]) {
        let categorySet = Set(apps.map { $0.category })
        categories = Array(categorySet).sorted()
    }
}
