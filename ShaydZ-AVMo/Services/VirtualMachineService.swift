import Foundation
import Combine
import WebKit

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

class VirtualMachineService {
    static let shared = VirtualMachineService()
    private let networkService = NetworkService.shared
    private var activeVM: VMStatus?
    private var webSocketTask: URLSessionWebSocketTask?
    private var cancellables = Set<AnyCancellable>()
    private var latencyTimer: Timer?
    
    // Stream for publishing connection state changes
    private let connectionStateSubject = CurrentValueSubject<ConnectionState, Never>(.disconnected)
    
    // Stream for publishing latency updates
    private let latencySubject = CurrentValueSubject<Int, Never>(0)
    
    private init() {}
    
    /// Launch a new VM instance
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
        
        return networkService.request(
            endpoint: "\(APIConfig.vmEndpoint)/launch",
            method: "POST",
            body: body
        )
        .flatMap { (response: LaunchVMResponse) -> AnyPublisher<VMStatus, APIError> in
            // If VM is starting, poll until it's ready
            if response.status == "starting" {
                return self.pollVMStatus(vmId: response.vmId)
            } else {
                // If VM is already running, get its status
                return self.getVMStatus(vmId: response.vmId)
            }
        }
        .handleEvents(receiveOutput: { vmStatus in
            self.activeVM = vmStatus
            
            if vmStatus.status == "running" && vmStatus.connectionInfo != nil {
                self.connectionStateSubject.send(.connected(vmId: vmStatus.vmId))
                self.startMonitoringConnection(vmStatus: vmStatus)
            }
        })
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
    func connectionState() -> AnyPublisher<ConnectionState, Never> {
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
}
