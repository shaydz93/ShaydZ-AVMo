import Foundation
import Combine

/// Supabase database service for data operations
class SupabaseDatabaseService {
    static let shared = SupabaseDatabaseService()
    private let networkService = SupabaseNetworkService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Virtual Machine Sessions
    
    /// Fetch user's VM sessions
    func fetchVMSessions(for userId: String) -> AnyPublisher<[SupabaseVMSession], SupabaseError> {
        return networkService.select(
            from: "vm_sessions",
            filter: "user_id=eq.\(userId)&order=created_at.desc",
            responseType: SupabaseVMSession.self
        )
    }
    
    /// Create new VM session
    func createVMSession(_ session: SupabaseVMSession) -> AnyPublisher<SupabaseVMSession, SupabaseError> {
        return networkService.insert(into: "vm_sessions", data: session)
    }
    
    /// Update VM session
    func updateVMSession(_ session: SupabaseVMSession) -> AnyPublisher<SupabaseVMSession, SupabaseError> {
        return networkService.update(
            table: "vm_sessions",
            data: session,
            filter: "id=eq.\(session.id)"
        )
    }
    
    /// End VM session
    func endVMSession(id: String) -> AnyPublisher<Void, SupabaseError> {
        let now = ISO8601DateFormatter().string(from: Date())
        let updateData = ["ended_at": now, "status": "ended"]
        
        guard let body = try? JSONSerialization.data(withJSONObject: updateData) else {
            return Fail(error: SupabaseError(error: "encoding_error", errorDescription: nil, message: "Failed to encode update"))
                .eraseToAnyPublisher()
        }
        
        let endpoint = "\(SupabaseConfig.restURL)/vm_sessions?id=eq.\(id)"
        
        return networkService.request(
            endpoint: endpoint,
            method: .PATCH,
            body: body,
            responseType: EmptyResponse.self
        )
        .map { _ in () }
        .eraseToAnyPublisher()
    }
    
    // MARK: - App Catalog
    
    /// Fetch available apps from catalog
    func fetchAppCatalog(category: String? = nil) -> AnyPublisher<[SupabaseAppCatalogItem], SupabaseError> {
        var filter = "is_active=eq.true&order=name.asc"
        
        if let category = category {
            filter += "&category=eq.\(category)"
        }
        
        return networkService.select(
            from: "app_catalog",
            filter: filter,
            responseType: SupabaseAppCatalogItem.self
        )
    }
    
    /// Fetch apps as AppModel for compatibility
    func fetchApps() -> AnyPublisher<[AppModel], SupabaseError> {
        return fetchAppCatalog()
            .map { supabaseApps in
                supabaseApps.map { supabaseApp in
                    AppModel(
                        id: supabaseApp.id,
                        name: supabaseApp.name,
                        description: supabaseApp.description ?? "No description available",
                        category: supabaseApp.category,
                        iconName: AppIconMapper.shared.iconName(for: supabaseApp.name),
                        version: supabaseApp.version,
                        isInstalled: false, // Will be updated based on user installations
                        isEnterprise: true, // Assume enterprise apps in Supabase
                        packageName: supabaseApp.name.lowercased().replacingOccurrences(of: " ", with: "."),
                        size: 50000000, // Default size
                        permissions: supabaseApp.requiredPermissions ?? [],
                        lastUpdated: supabaseApp.updatedAt
                    )
                }
            }
            .eraseToAnyPublisher()
    }
    
    /// Fetch app categories
    func fetchAppCategories() -> AnyPublisher<[String], SupabaseError> {
        return networkService.select(
            from: "app_catalog",
            columns: "category",
            filter: "is_active=eq.true",
            responseType: CategoryResponse.self
        )
        .map { responses in
            Array(Set(responses.map { $0.category })).sorted()
        }
        .eraseToAnyPublisher()
    }
    
    /// Search apps in catalog
    func searchApps(query: String) -> AnyPublisher<[SupabaseAppCatalogItem], SupabaseError> {
        let filter = "is_active=eq.true&or=(name.ilike.*\(query)*,description.ilike.*\(query)*)&order=name.asc"
        
        return networkService.select(
            from: "app_catalog",
            filter: filter,
            responseType: SupabaseAppCatalogItem.self
        )
    }
    
    // MARK: - User App Installations
    
    /// Fetch user's installed apps
    func fetchUserApps(for userId: String) -> AnyPublisher<[UserAppInstallation], SupabaseError> {
        return networkService.select(
            from: "user_app_installations",
            filter: "user_id=eq.\(userId)&order=installed_at.desc",
            responseType: UserAppInstallation.self
        )
    }
    
    /// Install app for user
    func installApp(userId: String, appId: String) -> AnyPublisher<UserAppInstallation, SupabaseError> {
        let installation = UserAppInstallation(
            id: UUID().uuidString,
            userId: userId,
            appId: appId,
            installedAt: ISO8601DateFormatter().string(from: Date()),
            isActive: true,
            settings: nil
        )
        
        return networkService.insert(into: "user_app_installations", data: installation)
    }
    
    /// Uninstall app for user
    func uninstallApp(userId: String, appId: String) -> AnyPublisher<Void, SupabaseError> {
        return networkService.delete(
            from: "user_app_installations",
            filter: "user_id=eq.\(userId)&app_id=eq.\(appId)"
        )
    }
    
    // MARK: - Analytics and Logs
    
    /// Log user activity
    func logActivity(userId: String, activity: UserActivity) -> AnyPublisher<UserActivity, SupabaseError> {
        return networkService.insert(into: "user_activities", data: activity)
    }
    
    /// Fetch user activity logs
    func fetchActivityLogs(for userId: String, limit: Int = 50) -> AnyPublisher<[UserActivity], SupabaseError> {
        return networkService.select(
            from: "user_activities",
            filter: "user_id=eq.\(userId)&order=created_at.desc&limit=\(limit)",
            responseType: UserActivity.self
        )
    }
    
    // MARK: - Real-time Subscriptions
    
    /// Subscribe to VM session updates
    func subscribeToVMSessionUpdates(userId: String) -> AnyPublisher<SupabaseVMSession, Never> {
        // This would typically use WebSocket connections to Supabase Realtime
        // For now, we'll use polling as a fallback
        return Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .flatMap { _ in
                self.fetchVMSessions(for: userId)
                    .catch { _ in Just([]) }
            }
            .compactMap { sessions in sessions.first }
            .removeDuplicates { $0.id == $1.id && $0.status == $1.status }
            .eraseToAnyPublisher()
    }
}

// MARK: - Supporting Models

struct CategoryResponse: Codable {
    let category: String
}

struct UserAppInstallation: Codable {
    let id: String
    let userId: String
    let appId: String
    let installedAt: String
    let isActive: Bool
    let settings: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case appId = "app_id"
        case installedAt = "installed_at"
        case isActive = "is_active"
        case settings
    }
    
    init(id: String, userId: String, appId: String, installedAt: String, isActive: Bool, settings: [String: Any]?) {
        self.id = id
        self.userId = userId
        self.appId = appId
        self.installedAt = installedAt
        self.isActive = isActive
        self.settings = settings
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        appId = try container.decode(String.self, forKey: .appId)
        installedAt = try container.decode(String.self, forKey: .installedAt)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        settings = try container.decodeIfPresent([String: Any].self, forKey: .settings)
    }
}

struct UserActivity: Codable {
    let id: String
    let userId: String
    let activityType: String
    let description: String
    let metadata: [String: Any]?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case activityType = "activity_type"
        case description
        case metadata
        case createdAt = "created_at"
    }
    
    init(id: String, userId: String, activityType: String, description: String, metadata: [String: Any]?, createdAt: String) {
        self.id = id
        self.userId = userId
        self.activityType = activityType
        self.description = description
        self.metadata = metadata
        self.createdAt = createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        activityType = try container.decode(String.self, forKey: .activityType)
        description = try container.decode(String.self, forKey: .description)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        metadata = try container.decodeIfPresent([String: Any].self, forKey: .metadata)
    }
}
