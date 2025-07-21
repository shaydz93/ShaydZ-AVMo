import Foundation
import Combine
import WebKit

class SupabaseVMService: ObservableObject {
    static let shared = SupabaseVMService()
    
    private let baseURL = "https://qnzskbfqqzxuikjyzqdp.supabase.co"
    private let apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.example"
    private let vmBackendURL = "http://localhost:8084" // VM orchestrator backend
    private let authService = SupabaseAuthService.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var activeVMs: [VMStatus] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private init() {
        // Listen for auth changes
        authService.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    self?.loadActiveVMs()
                } else {
                    self?.activeVMs = []
                }
            }
            .store(in: &cancellables)
        
        // Refresh VMs periodically
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                if self?.authService.isAuthenticated == true {
                    self?.loadActiveVMs()
                }
            }
            .store(in: &cancellables)
    }
    
    func loadActiveVMs() {
        guard let token = authService.authToken,
              let userId = authService.userProfile?.id,
              let url = URL(string: "\(baseURL)/rest/v1/vm_sessions?select=*&user_id=eq.\(userId)") else {
            error = "Not authenticated"
            return
        }
        
        isLoading = true
        error = nil
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("\(apiKey)", forHTTPHeaderField: "apiKey")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    let errorResponse = try? JSONDecoder().decode([String: String].self, from: data)
                    throw APIError.requestFailed(errorResponse?["error"] ?? "Failed to fetch VMs")
                }
                
                return data
            }
            .decode(type: [SupabaseVMSession].self, decoder: JSONDecoder())
            .flatMap { [weak self] sessions -> AnyPublisher<[VMStatus], Error> in
                guard let self = self, !sessions.isEmpty else {
                    return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
                }
                
                // Get detailed status for each VM from the VM orchestrator
                let publishers = sessions.map { session in
                    self.getVMStatus(vmId: session.id)
                }
                
                return Publishers.MergeMany(publishers)
                    .collect()
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] vms in
                    self?.activeVMs = vms
                }
            )
            .store(in: &cancellables)
    }
    
    func getVMStatus(vmId: String) -> AnyPublisher<VMStatus, Error> {
        guard let url = URL(string: "\(vmBackendURL)/vm/\(vmId)") else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        if let token = authService.authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw APIError.requestFailed("Failed to get VM status")
                }
                
                return data
            }
            .decode(type: VMStatus.self, decoder: JSONDecoder())
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                }
                return APIError.requestFailed(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    func launchVM(config: VMConfig) -> AnyPublisher<LaunchVMResponse, APIError> {
        guard let token = authService.authToken,
              let userId = authService.userProfile?.id,
              let url = URL(string: "\(vmBackendURL)/vm/launch") else {
            return Fail(error: APIError.unauthorized)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let launchRequest = LaunchVMRequest(userId: userId, config: config)
        request.httpBody = try? JSONEncoder().encode(launchRequest)
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw APIError.requestFailed("Failed to launch VM")
                }
                
                return data
            }
            .decode(type: LaunchVMResponse.self, decoder: JSONDecoder())
            .handleEvents(receiveOutput: { [weak self] _ in
                // Refresh VM list
                self?.loadActiveVMs()
            })
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                }
                return APIError.requestFailed(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    func stopVM(vmId: String) -> AnyPublisher<Bool, APIError> {
        guard let token = authService.authToken,
              let url = URL(string: "\(vmBackendURL)/vm/\(vmId)/stop") else {
            return Fail(error: APIError.unauthorized)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw APIError.requestFailed("Failed to stop VM")
                }
                
                return true
            }
            .handleEvents(receiveOutput: { [weak self] _ in
                // Refresh VM list
                self?.loadActiveVMs()
            })
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                }
                return APIError.requestFailed(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    private struct LaunchVMRequest: Codable {
        let userId: String
        let config: VMConfig
    }
}
