import Foundation
import Combine

/// Service for accessing app catalog data from Supabase
class AppCatalogSupabaseService: ObservableObject {
    static let shared = AppCatalogSupabaseService()
    
    private var cancellables = Set<AnyCancellable>()
    @Published var vmSessions: [SupabaseVMSession] = []
    
    init() {
        // Initialize with any necessary dependencies
        // Create a mock VM session for demonstration
        vmSessions = [SupabaseVMSession.mockSession]
    }
    
    /// Get all available applications from Supabase
    func getApps() -> AnyPublisher<[AppModel], APIError> {
        // In a real implementation, this would fetch data from Supabase
        return Just(AppModel.mockApps)
            .setFailureType(to: APIError.self)
            .eraseToAnyPublisher()
    }
    
    /// Get apps by category from Supabase
    func getAppsByCategory(category: String) -> AnyPublisher<[AppModel], APIError> {
        return Just(AppModel.mockApps.filter { $0.categories.contains(category) })
            .setFailureType(to: APIError.self)
            .eraseToAnyPublisher()
    }
    
    /// Get app details by ID from Supabase
    func getAppDetails(appId: String) -> AnyPublisher<AppModel, APIError> {
        if let app = AppModel.mockApps.first(where: { $0.id == appId }) {
            return Just(app)
                .setFailureType(to: APIError.self)
                .eraseToAnyPublisher()
        } else {
            return Fail(error: APIError.badRequest("App not found"))
                .eraseToAnyPublisher()
        }
    }
    
    /// Search for apps with query in Supabase
    func searchApps(query: String) -> AnyPublisher<[AppModel], APIError> {
        let lowercasedQuery = query.lowercased()
        let filteredApps = AppModel.mockApps.filter {
            $0.name.lowercased().contains(lowercasedQuery) ||
            $0.description.lowercased().contains(lowercasedQuery) ||
            $0.developer.lowercased().contains(lowercasedQuery)
        }
        
        return Just(filteredApps)
            .setFailureType(to: APIError.self)
            .eraseToAnyPublisher()
    }
    
    /// Get VM sessions for an app from Supabase
    func getVMSessionsForApp(appId: String) -> AnyPublisher<[SupabaseVMSession], APIError> {
        // Mock implementation
        return Just([SupabaseVMSession.mockSession])
            .setFailureType(to: APIError.self)
            .eraseToAnyPublisher()
    }
    
    /// Fetch VM sessions
    func fetchVMSessions(userId: String, completion: @escaping (Result<[SupabaseVMSession], Error>) -> Void) {
        // Mock implementation
        let sessions = [SupabaseVMSession.mockSession]
        completion(.success(sessions))
    }
    
    /// Create a new VM session
    func createVMSession(
        userId: String,
        appId: String,
        status: String = "initializing",
        completion: @escaping (Result<SupabaseVMSession, Error>) -> Void
    ) {
        // Create a mock session
        let newSession = SupabaseVMSession(
            id: "new-session-\(UUID().uuidString)",
            userId: userId,
            status: status,
            vmInstanceId: "vm-\(UUID().uuidString)",
            appId: appId,
            startedAt: Date(),
            endedAt: nil,
            ipAddress: "192.168.1.1",
            port: 8080,
            connectionUrl: "https://vm.shaydz-avmo.io/connect/new-session",
            sessionData: ["resolution": "1920x1080", "quality": "high"]
        )
        
        // Add to local cache
        self.vmSessions.append(newSession)
        
        // Return success
        completion(.success(newSession))
    }
    
    /// Update an existing VM session
    func updateVMSession(
        session: SupabaseVMSession,
        status: String? = nil,
        completion: @escaping (Result<SupabaseVMSession, Error>) -> Void
    ) {
        // Find the session in our local cache
        if let index = self.vmSessions.firstIndex(where: { $0.id == session.id }) {
            // Create an updated copy
            var updatedSession = session
            
            // Update the status if provided
            if let newStatus = status {
                updatedSession = SupabaseVMSession(
                    id: session.id,
                    userId: session.userId,
                    status: newStatus,
                    vmInstanceId: session.vmInstanceId,
                    appId: session.appId,
                    startedAt: session.startedAt,
                    endedAt: newStatus == "terminated" ? Date() : session.endedAt,
                    ipAddress: session.ipAddress,
                    port: session.port,
                    connectionUrl: session.connectionUrl,
                    sessionData: session.sessionData
                )
            }
            
            // Update the local cache
            self.vmSessions[index] = updatedSession
            
            // Return success
            completion(.success(updatedSession))
        } else {
            // Return error if session not found
            completion(.failure(APIError.badRequest("Session not found")))
        }
    }
    
    /// Get request with authorization
    func request<T: Decodable>(_ type: T.Type, url: URL, method: String = "GET", body: Encodable? = nil, completion: @escaping (Result<T, Error>) -> Void) {
        // Mock implementation that returns a success with an empty array or object
        if let emptyResult = [] as? T {
            completion(.success(emptyResult))
        } else {
            completion(.failure(APIError.badRequest("Not implemented")))
        }
    }
}
