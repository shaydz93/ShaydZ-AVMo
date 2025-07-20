import Foundation
import Combine
import SwiftUI  // This will help ensure the Models folder is in the search path

class VirtualMachineService {
    static let shared = VirtualMachineService()
    
    private let networkService = NetworkService.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isVMRunning = false
    @Published var isLoading = false
    @Published var error: String?
    
    private init() {
        // Private initialization to enforce singleton pattern
    }
    
    func startVM() -> AnyPublisher<Bool, APIError> {
        isLoading = true
        error = nil
        
        let endpoint = "vm-orchestrator/start"
        
        return networkService.post(endpoint: endpoint, parameters: [:])
            .handleEvents(
                receiveOutput: { [weak self] _ in
                    self?.isVMRunning = true
                    self?.isLoading = false
                },
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveCancel: { [weak self] in
                    self?.isLoading = false
                }
            )
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
    
    func stopVM() -> AnyPublisher<Bool, APIError> {
        isLoading = true
        error = nil
        
        let endpoint = "vm-orchestrator/stop"
        
        return networkService.post(endpoint: endpoint, parameters: [:])
            .handleEvents(
                receiveOutput: { [weak self] _ in
                    self?.isVMRunning = false
                    self?.isLoading = false
                },
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveCancel: { [weak self] in
                    self?.isLoading = false
                }
            )
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
    
    func checkVMStatus() -> AnyPublisher<Bool, APIError> {
        isLoading = true
        error = nil
        
        let endpoint = "vm-orchestrator/status"
        
        return networkService.get(endpoint: endpoint)
            .tryMap { data -> Bool in
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let status = json["status"] as? String else {
                    throw APIError.decodingFailed
                }
                return status == "running"
            }
            .handleEvents(
                receiveOutput: { [weak self] isRunning in
                    self?.isVMRunning = isRunning
                    self?.isLoading = false
                },
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveCancel: { [weak self] in
                    self?.isLoading = false
                }
            )
            .mapError { error -> APIError in
                if let apiError = error as? APIError {
                    return apiError
                } else {
                    return APIError.unknown(error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
}
