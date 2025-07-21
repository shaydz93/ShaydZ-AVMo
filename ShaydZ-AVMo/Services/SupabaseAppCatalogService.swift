import Foundation
import Combine

class SupabaseAppCatalogService: ObservableObject {
    static let shared = SupabaseAppCatalogService()
    
    private let baseURL = "https://qnzskbfqqzxuikjyzqdp.supabase.co"
    private let apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.example"
    private let authService = SupabaseAuthService.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var apps: [AppDetailsModel] = []
    @Published var categories: [String] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private init() {
        // Listen for auth changes
        authService.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    self?.loadApps()
                    self?.loadCategories()
                } else {
                    self?.apps = []
                    self?.categories = []
                }
            }
            .store(in: &cancellables)
    }
    
    func loadApps() {
        guard let token = authService.authToken, let url = URL(string: "\(baseURL)/rest/v1/apps?select=*") else {
            error = "Not authenticated"
            return
        }
        
        isLoading = true
        error = nil
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("\(apiKey)", forHTTPHeaderField: "apiKey")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    let errorResponse = try? JSONDecoder().decode([String: String].self, from: data)
                    throw APIError.requestFailed(errorResponse?["error"] ?? "Failed to fetch apps")
                }
                
                return data
            }
            .decode(type: [AppDetailsModel].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] apps in
                    self?.apps = apps
                }
            )
            .store(in: &cancellables)
    }
    
    func loadCategories() {
        guard let token = authService.authToken, let url = URL(string: "\(baseURL)/rest/v1/app_categories?select=*") else {
            error = "Not authenticated"
            return
        }
        
        isLoading = true
        error = nil
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("\(apiKey)", forHTTPHeaderField: "apiKey")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    let errorResponse = try? JSONDecoder().decode([String: String].self, from: data)
                    throw APIError.requestFailed(errorResponse?["error"] ?? "Failed to fetch categories")
                }
                
                return data
            }
            .decode(type: [CategoryResponse].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] categoriesResponse in
                    self?.categories = categoriesResponse.map { $0.name }
                }
            )
            .store(in: &cancellables)
    }
    
    func getAppsByCategory(_ category: String) -> [AppDetailsModel] {
        return apps.filter { $0.category == category }
    }
    
    func getAppDetails(id: String) -> AppDetailsModel? {
        return apps.first(where: { $0.id == id })
    }
    
    func installApp(id: String) -> AnyPublisher<Bool, APIError> {
        guard let token = authService.authToken,
              let userId = authService.userProfile?.id,
              let url = URL(string: "\(baseURL)/rest/v1/user_apps") else {
            return Fail(error: APIError.unauthorized)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("\(apiKey)", forHTTPHeaderField: "apiKey")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "user_id": userId,
            "app_id": id,
            "status": "installed"
        ]
        
        request.httpBody = try? JSONEncoder().encode(body)
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 201 else {
                    let errorResponse = try? JSONDecoder().decode([String: String].self, from: data)
                    throw APIError.requestFailed(errorResponse?["error"] ?? "Failed to install app")
                }
                
                return true
            }
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                }
                return APIError.requestFailed(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    private struct CategoryResponse: Codable {
        let id: String
        let name: String
    }
}
