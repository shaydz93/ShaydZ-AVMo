import Foundation
import Combine

/// Enhanced Supabase integration manager
class SupabaseIntegrationManager: ObservableObject {
    static let shared = SupabaseIntegrationManager()
    
    // Core services
    private let authService = SupabaseAuthService.shared
    private let databaseService = SupabaseDatabaseService.shared
    private let networkService = SupabaseNetworkService.shared
    
    // Integration state
    @Published var isConnected = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var lastSyncTime: Date?
    @Published var syncInProgress = false
    
    // Error handling
    @Published var lastError: SupabaseError?
    @Published var errorCount = 0
    
    private var cancellables = Set<AnyCancellable>()
    private var connectivityTimer: Timer?
    
    // MARK: - Connection Status
    
    enum ConnectionStatus {
        case disconnected
        case connecting
        case connected
        case error(String)
        
        var displayText: String {
            switch self {
            case .disconnected:
                return "Disconnected"
            case .connecting:
                return "Connecting..."
            case .connected:
                return "Connected"
            case .error(let message):
                return "Error: \(message)"
            }
        }
        
        var isHealthy: Bool {
            switch self {
            case .connected:
                return true
            default:
                return false
            }
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        setupConnectionMonitoring()
        setupErrorHandling()
        initializeConnection()
    }
    
    private func setupConnectionMonitoring() {
        // Monitor authentication state
        authService.$isAuthenticated
            .sink { [weak self] isAuth in
                self?.updateConnectionStatus(authenticated: isAuth)
            }
            .store(in: &cancellables)
        
        // Start periodic connectivity checks
        startConnectivityMonitoring()
    }
    
    private func setupErrorHandling() {
        // Monitor for network errors
        networkService.errorPublisher
            .sink { [weak self] error in
                self?.handleError(error)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Connection Management
    
    func initializeConnection() {
        connectionStatus = .connecting
        
        // Test basic connectivity
        testConnection()
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        self?.connectionStatus = .connected
                        self?.isConnected = true
                        self?.errorCount = 0
                    case .failure(let error):
                        self?.connectionStatus = .error(error.localizedDescription)
                        self?.isConnected = false
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.lastSyncTime = Date()
                }
            )
            .store(in: &cancellables)
    }
    
    private func testConnection() -> AnyPublisher<Void, SupabaseError> {
        // Test health endpoint
        let healthEndpoint = "\\(SupabaseConfig.restURL)/health"
        
        return networkService.request(
            endpoint: healthEndpoint,
            method: .GET,
            body: nil,
            authenticated: false,
            responseType: EmptyResponse.self
        )
        .map { _ in () }
        .eraseToAnyPublisher()
    }
    
    private func updateConnectionStatus(authenticated: Bool) {
        if authenticated && connectionStatus.isHealthy {
            isConnected = true
        }
    }
    
    // MARK: - Real-time Features
    
    /// Start real-time subscriptions
    func startRealtimeSubscriptions() {
        guard isConnected else { return }
        
        subscribeToVMSessions()
        subscribeToAppInstallations()
        subscribeToUserActivities()
    }
    
    private func subscribeToVMSessions() {
        // Real-time VM session updates
        // Implementation would use WebSocket connections
        print("📡 Starting VM sessions real-time subscription")
    }
    
    private func subscribeToAppInstallations() {
        // Real-time app installation updates
        print("📡 Starting app installations real-time subscription")
    }
    
    private func subscribeToUserActivities() {
        // Real-time activity updates
        print("📡 Starting user activities real-time subscription")
    }
    
    // MARK: - Data Synchronization
    
    /// Perform full data sync
    func performFullSync() -> AnyPublisher<Bool, SupabaseError> {
        guard isConnected else {
            return Fail(error: SupabaseError(error: "not_connected", errorDescription: nil, message: "Not connected to Supabase"))
                .eraseToAnyPublisher()
        }
        
        syncInProgress = true
        
        return syncUserData()
            .flatMap { _ in self.syncVMSessions() }
            .flatMap { _ in self.syncAppInstallations() }
            .flatMap { _ in self.syncActivities() }
            .handleEvents(
                receiveCompletion: { [weak self] _ in
                    self?.syncInProgress = false
                    self?.lastSyncTime = Date()
                }
            )
            .map { _ in true }
            .eraseToAnyPublisher()
    }
    
    private func syncUserData() -> AnyPublisher<Void, SupabaseError> {
        guard let userId = authService.currentUser?.id else {
            return Just(()).setFailureType(to: SupabaseError.self).eraseToAnyPublisher()
        }
        
        return authService.fetchUserProfile()
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    private func syncVMSessions() -> AnyPublisher<Void, SupabaseError> {
        guard let userId = authService.currentUser?.id else {
            return Just(()).setFailureType(to: SupabaseError.self).eraseToAnyPublisher()
        }
        
        return databaseService.fetchVMSessions(for: userId)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    private func syncAppInstallations() -> AnyPublisher<Void, SupabaseError> {
        guard let userId = authService.currentUser?.id else {
            return Just(()).setFailureType(to: SupabaseError.self).eraseToAnyPublisher()
        }
        
        return databaseService.fetchUserAppInstallations(for: userId)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    private func syncActivities() -> AnyPublisher<Void, SupabaseError> {
        guard let userId = authService.currentUser?.id else {
            return Just(()).setFailureType(to: SupabaseError.self).eraseToAnyPublisher()
        }
        
        return databaseService.fetchActivityLogs(for: userId)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: SupabaseError) {
        lastError = error
        errorCount += 1
        
        // Log error for debugging
        print("🔥 Supabase Error: \\(error.localizedDescription)")
        
        // Handle specific error types
        switch error.error {
        case "network_error":
            connectionStatus = .error("Network connectivity issue")
            isConnected = false
        case "unauthorized":
            // Token expired, try to refresh
            authService.refreshSession()
        case "rate_limit":
            // Implement exponential backoff
            scheduleRetry()
        default:
            connectionStatus = .error(error.localizedDescription)
        }
    }
    
    private func scheduleRetry() {
        // Exponential backoff retry logic
        let delay = min(pow(2.0, Double(errorCount)), 60.0) // Max 60 seconds
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.initializeConnection()
        }
    }
    
    // MARK: - Connectivity Monitoring
    
    private func startConnectivityMonitoring() {
        connectivityTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.checkConnectivity()
        }
    }
    
    private func checkConnectivity() {
        testConnection()
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(_) = completion {
                        self?.isConnected = false
                        self?.connectionStatus = .disconnected
                    }
                },
                receiveValue: { [weak self] _ in
                    if self?.connectionStatus != .connected {
                        self?.connectionStatus = .connected
                        self?.isConnected = true
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Public Interface
    
    /// Force reconnect to Supabase
    func reconnect() {
        isConnected = false
        connectionStatus = .disconnected
        errorCount = 0
        initializeConnection()
    }
    
    /// Get connection health info
    func getConnectionHealth() -> ConnectionHealth {
        ConnectionHealth(
            isConnected: isConnected,
            status: connectionStatus,
            lastSync: lastSyncTime,
            errorCount: errorCount,
            lastError: lastError
        )
    }
    
    deinit {
        connectivityTimer?.invalidate()
    }
}

// MARK: - Supporting Types

/// Connection health information
struct ConnectionHealth {
    let isConnected: Bool
    let status: SupabaseIntegrationManager.ConnectionStatus
    let lastSync: Date?
    let errorCount: Int
    let lastError: SupabaseError?
    
    var healthScore: Double {
        if !isConnected { return 0.0 }
        if errorCount == 0 { return 1.0 }
        return max(0.1, 1.0 - (Double(errorCount) * 0.1))
    }
    
    var statusEmoji: String {
        if isConnected && errorCount == 0 {
            return "🟢"
        } else if isConnected && errorCount < 3 {
            return "🟡"
        } else {
            return "🔴"
        }
    }
}

/// Empty response type for health checks
struct EmptyResponse: Codable {}

// MARK: - Network Service Extensions

extension SupabaseNetworkService {
    /// Publisher for network errors
    var errorPublisher: AnyPublisher<SupabaseError, Never> {
        // Implementation would track errors from network requests
        PassthroughSubject<SupabaseError, Never>().eraseToAnyPublisher()
    }
}
