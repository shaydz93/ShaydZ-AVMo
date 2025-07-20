import Foundation
import Combine
import WebKit

// Mock SupabaseVMSession for compilation
struct SupabaseVMSession: Codable {
    let id: String
    let userId: String
    let status: String
    let createdAt: String
}

/// Virtual machine response models
struct VMConfig: Codable {
    let androidVersion: String
    let ram: String
    let resolution: String
    let cpuCores: Int
}

struct VMConnectionInfo: Codable {
    let ip: String
    let port: Int
    let websocketUrl: String
    let rtcUrl: String
}

struct VMStatus: Codable {
    let vmId: String
    let status: String
    let config: VMConfig?
    let connectionInfo: VMConnectionInfo?
}

struct LaunchVMResponse: Codable {
    let message: String
    let vmId: String
    let status: String
}

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected(vmId: String)
    case error(String)
}

class VirtualMachineService: ObservableObject {
    static let shared = VirtualMachineService()
    private let networkService = AppCatalogNetworkService.shared
    private let supabaseDatabase = AppCatalogSupabaseService.shared
    private var activeVM: VMStatus?
    private var webSocketTask: URLSessionWebSocketTask?
    private var cancellables = Set<AnyCancellable>()
    private var latencyTimer: Timer?
    
    /// Published properties for reactive UI updates
    @Published var connectionState: ConnectionState = .disconnected
    @Published var currentVMSession: SupabaseVMSession?
    @Published var vmSessions: [SupabaseVMSession] = []
    @Published var isLoading = false
    
    // Stream for publishing connection state changes
    private let connectionStateSubject = CurrentValueSubject<ConnectionState, Never>(.disconnected)
    
    // Stream for publishing latency updates
    private let latencySubject = CurrentValueSubject<Int, Never>(0)
    
    private init() {
        // Observe connection state changes and publish them
        connectionStateSubject
            .assign(to: \.connectionState, on: self)
            .store(in: &cancellables)
        
        // Load user's VM sessions on initialization
        loadUserVMSessions()
    }
    
    /// Load user's VM sessions - new Supabase method
    private func loadUserVMSessions() {
        guard let userId = SupabaseAuthService.shared.currentUser?.id else {
            return
        }
        
        isLoading = true
        
        supabaseDatabase.fetchVMSessions(for: userId)
            .sink(
                receiveCompletion: { [weak self] completion in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                    }
                    if case .failure(let error) = completion {
                        print("Failed to load VM sessions: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] sessions in
                    DispatchQueue.main.async {
                        self?.vmSessions = sessions
                        // Set current session if there's an active one
                        self?.currentVMSession = sessions.first { $0.status == "running" }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    /// Create VM session in Supabase
    private func createVMSession(vmId: String, connectionInfo: VMConnectionInfo?) -> AnyPublisher<SupabaseVMSession, SupabaseError> {
        guard let userId = SupabaseAuthService.shared.currentUser?.id else {
            return Fail(error: SupabaseError(error: "not_authenticated", errorDescription: nil, message: "User not authenticated"))
                .eraseToAnyPublisher()
        }
        
        let session = SupabaseVMSession(
            id: UUID().uuidString,
            userId: userId,
            vmInstanceId: vmId,
            status: "starting",
            startedAt: ISO8601DateFormatter().string(from: Date()),
            endedAt: nil,
            ipAddress: connectionInfo?.ip,
            port: connectionInfo?.port,
            connectionUrl: connectionInfo?.websocketUrl,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        return supabaseDatabase.createVMSession(session)
    }
    
    /// Update VM session status
    private func updateVMSessionStatus(_ sessionId: String, status: String) {
        guard let session = vmSessions.first(where: { $0.id == sessionId }) else {
            return
        }
        
        let updatedSession = SupabaseVMSession(
            id: session.id,
            userId: session.userId,
            vmInstanceId: session.vmInstanceId,
            status: status,
            startedAt: session.startedAt,
            endedAt: status == "ended" ? ISO8601DateFormatter().string(from: Date()) : session.endedAt,
            ipAddress: session.ipAddress,
            port: session.port,
            connectionUrl: session.connectionUrl,
            createdAt: session.createdAt,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        supabaseDatabase.updateVMSession(updatedSession)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to update VM session: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] updatedSession in
                    DispatchQueue.main.async {
                        if let index = self?.vmSessions.firstIndex(where: { $0.id == sessionId }) {
                            self?.vmSessions[index] = updatedSession
                        }
                        if status == "running" {
                            self?.currentVMSession = updatedSession
                        } else if status == "ended" && self?.currentVMSession?.id == sessionId {
                            self?.currentVMSession = nil
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    /// Launch a new VM instance - now with Supabase integration
    func launchVM(androidVersion: String = "11.0", ram: String = "2048M", resolution: String = "1080x1920") -> AnyPublisher<VMStatus, APIError> {
        // Check if we already have an active VM
        if let activeVM = activeVM, activeVM.status == "running" {
            return Just(activeVM)
                .setFailureType(to: APIError.self)
                .eraseToAnyPublisher()
        }
        
        #if DEBUG
        // For demo/testing, simulate a VM launch
        if networkService.getAuthToken()?.starts(with: "demo_token_") ?? false {
            let mockConnectionInfo = VMConnectionInfo(
                ip: "10.0.0.\(Int.random(in: 1...255))",
                port: 5555,
                websocketUrl: "ws://localhost:8082/stream/demo-vm",
                rtcUrl: "wss://rtc.avmo.local/vm/demo-vm"
            )
            
            let mockConfig = VMConfig(
                androidVersion: androidVersion,
                ram: ram,
                resolution: resolution,
                cpuCores: 2
            )
            
            let mockVM = VMStatus(
                vmId: "demo-vm-\(Int(Date().timeIntervalSince1970))",
                status: "running",
                config: mockConfig,
                connectionInfo: mockConnectionInfo
            )
            
            self.activeVM = mockVM
            
            // Create VM session in Supabase for demo
            self.createVMSession(vmId: mockVM.vmId, connectionInfo: mockConnectionInfo)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("Failed to create demo VM session: \(error.localizedDescription)")
                        }
                    },
                    receiveValue: { [weak self] session in
                        DispatchQueue.main.async {
                            self?.currentVMSession = session
                            self?.vmSessions.insert(session, at: 0)
                        }
                        
                        // Update session to running after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self?.updateVMSessionStatus(session.id, status: "running")
                        }
                    }
                )
                .store(in: &self.cancellables)
            
            // Change connection state after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.connectionStateSubject.send(.connected(vmId: mockVM.vmId))
                self.startLatencySimulation()
            }
            
            self.connectionStateSubject.send(.connecting)
            
            return Just(mockVM)
                .delay(for: .seconds(2), scheduler: RunLoop.main)
                .setFailureType(to: APIError.self)
                .eraseToAnyPublisher()
        }
        #endif
        
        // Prepare VM launch request
        let launchData: [String: Any] = [
            "android_version": androidVersion,
            "ram": ram,
            "resolution": resolution,
            "cpu_cores": 2
        ]
        
        guard let body = try? JSONEncoder().encode(launchData) else {
            return Fail(error: APIError.unknown).eraseToAnyPublisher()
        }
        
        connectionStateSubject.send(.connecting)
        isLoading = true
        
        return networkService.request(
            endpoint: "\(APIConfig.vmEndpoint)/launch",
            method: "POST",
            body: body
        )
        .flatMap { (response: LaunchVMResponse) -> AnyPublisher<VMStatus, APIError> in
            // Create VM session in Supabase
            self.createVMSession(vmId: response.vmId, connectionInfo: nil)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { session in
                        DispatchQueue.main.async {
                            self.currentVMSession = session
                            self.vmSessions.insert(session, at: 0)
                        }
                    }
                )
                .store(in: &self.cancellables)
            
            // If VM is starting, poll until it's ready
            if response.status == "starting" {
                return self.pollVMStatus(vmId: response.vmId)
            } else {
                // If VM is already running, get its status
                return self.getVMStatus(vmId: response.vmId)
            }
        }
        .handleEvents(
            receiveOutput: { vmStatus in
                self.activeVM = vmStatus
                self.isLoading = false
                
                // Update VM session status to running
                if let sessionId = self.currentVMSession?.id {
                    self.updateVMSessionStatus(sessionId, status: "running")
                }
                
                if vmStatus.status == "running" {
                    self.connectionStateSubject.send(.connected(vmId: vmStatus.vmId))
                    self.startLatencySimulation()
                }
            },
            receiveCompletion: { completion in
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.connectionStateSubject.send(.error(error.localizedDescription))
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    /// Terminate VM - now with Supabase integration
    func terminateVM() -> AnyPublisher<Bool, APIError> {
        guard let activeVM = activeVM else {
            return Just(true).setFailureType(to: APIError.self).eraseToAnyPublisher()
        }
        
        #if DEBUG
        // For demo/testing, simulate VM termination
        if networkService.getAuthToken()?.starts(with: "demo_token_") ?? false {
            self.activeVM = nil
            self.connectionStateSubject.send(.disconnected)
            self.stopLatencySimulation()
            
            // End VM session in Supabase
            if let sessionId = currentVMSession?.id {
                updateVMSessionStatus(sessionId, status: "ended")
            }
            
            return Just(true)
                .delay(for: .seconds(1), scheduler: RunLoop.main)
                .setFailureType(to: APIError.self)
                .eraseToAnyPublisher()
        }
        #endif
        
        isLoading = true
        
        return networkService.request(
            endpoint: "\(APIConfig.vmEndpoint)/vm/\(activeVM.vmId)/terminate",
            method: "POST"
        )
        .map { (_: [String: String]) -> Bool in
            return true
        }
        .handleEvents(
            receiveOutput: { _ in
                self.activeVM = nil
                self.isLoading = false
                self.connectionStateSubject.send(.disconnected)
                self.stopLatencySimulation()
                
                // End VM session in Supabase
                if let sessionId = self.currentVMSession?.id {
                    self.updateVMSessionStatus(sessionId, status: "ended")
                }
            },
            receiveCompletion: { completion in
                self.isLoading = false
                if case .failure(let error) = completion {
                    print("Failed to terminate VM: \(error.localizedDescription)")
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    /// Get VM status
    func getVMStatus(vmId: String) -> AnyPublisher<VMStatus, APIError> {
        return networkService.request(
            endpoint: "\(APIConfig.vmEndpoint)/vm/\(vmId)"
        )
    }
    
    /// Poll VM status until running or error
    private func pollVMStatus(vmId: String) -> AnyPublisher<VMStatus, APIError> {
        return Timer.publish(every: 2, on: .main, in: .common)
            .autoconnect()
            .flatMap { _ in
                self.getVMStatus(vmId: vmId)
            }
            .filter { status in
                // Filter until VM is running or in error state
                return status.status == "running" || status.status == "error"
            }
            .first()
            .eraseToAnyPublisher()
    }
    
    /// Stop VM
    func stopVM(vmId: String) -> AnyPublisher<Bool, APIError> {
        #if DEBUG
        // For demo/testing, simulate VM stopping
        if vmId.starts(with: "demo-vm-") {
            self.connectionStateSubject.send(.disconnected)
            self.stopLatencySimulation()
            self.activeVM = nil
            
            return Just(true)
                .delay(for: .seconds(1), scheduler: RunLoop.main)
                .setFailureType(to: APIError.self)
                .eraseToAnyPublisher()
        }
        #endif
        
        return networkService.request(
            endpoint: "\(APIConfig.vmEndpoint)/vm/\(vmId)/stop",
            method: "POST"
        )
        .map { (_: [String: String]) -> Bool in
            self.connectionStateSubject.send(.disconnected)
            self.stopLatencySimulation()
            self.activeVM = nil
            return true
        }
        .eraseToAnyPublisher()
    }
    
    /// Get list of VMs for current user
    func listVMs(status: String? = nil) -> AnyPublisher<[VMStatus], APIError> {
        var endpoint = "\(APIConfig.vmEndpoint)/vms"
        
        if let status = status {
            endpoint += "?status=\(status)"
        }
        
        return networkService.request(
            endpoint: endpoint
        )
        .map { (response: [String: [VMStatus]]) -> [VMStatus] in
            return response["vms"] ?? []
        }
        .eraseToAnyPublisher()
    }
    
    /// Start monitoring connection via WebSocket
    private func startMonitoringConnection(vmStatus: VMStatus) {
        guard let connectionInfo = vmStatus.connectionInfo else { return }
        
        // In a real app, we would connect to the WebSocket
        // For demo purposes, we'll just simulate latency data
        startLatencySimulation()
    }
    
    /// Simulate varying latency
    private func startLatencySimulation() {
        stopLatencySimulation()
        
        latencyTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Simulate random latency between 30-120ms
            self.latencySubject.send(Int.random(in: 30...120))
        }
        
        // Initial latency
        latencySubject.send(Int.random(in: 30...120))
    }
    
    /// Stop latency simulation
    private func stopLatencySimulation() {
        latencyTimer?.invalidate()
        latencyTimer = nil
        latencySubject.send(0)
    }
    
    /// Get current connection state
    func getConnectionState() -> AnyPublisher<ConnectionState, Never> {
        return connectionStateSubject.eraseToAnyPublisher()
    }
    
    /// Monitor latency
    func monitorLatency() -> AnyPublisher<Int, Never> {
        return latencySubject.eraseToAnyPublisher()
    }
    
    /// Get current VM status if active
    func getCurrentVM() -> VMStatus? {
        return activeVM
    }
}

// Define APIError and SupabaseError here for immediate compilation
enum APIError: Error, LocalizedError {
    case networkError
    case invalidResponse
    case unauthorized
    case serverError
    case badRequest(String)
    case unknown(String)
    case invalidURL
    case decodingError
    case encodingError
    case noData
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection failed"
        case .invalidResponse:
            return "Invalid server response"
        case .unauthorized:
            return "Authentication required"
        case .serverError:
            return "Server error occurred"
        case .badRequest(let message):
            return "Bad request: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        case .invalidURL:
            return "Invalid URL"
        case .decodingError:
            return "Failed to decode response"
        case .encodingError:
            return "Failed to encode request"
        case .noData:
            return "No data received"
        }
    }
}

struct SupabaseError: Error {
    let message: String
    let error: String?
}
