import Foundation
import Combine

/// Central app catalog service for ShaydZ AVMo
public class ShaydZAVMo_AppCatalogService: ObservableObject {
    public static let shared = ShaydZAVMo_AppCatalogService()
    
    @Published public var availableApps: [ShaydZAVMo_AppModel] = []
    @Published public var installedApps: [ShaydZAVMo_AppModel] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    private let networkService = ShaydZAVMo_NetworkService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadSampleApps()
    }
    
    // MARK: - App Discovery
    
    /// Fetch available apps from catalog
    public func fetchAvailableApps() -> AnyPublisher<[ShaydZAVMo_AppModel], ShaydZAVMo_APIError> {
        isLoading = true
        errorMessage = nil
        
        return Future<[ShaydZAVMo_AppModel], ShaydZAVMo_APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self?.isLoading = false
                self?.loadSampleApps()
                promise(.success(self?.availableApps ?? []))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Search apps by name or category
    public func searchApps(query: String, category: String? = nil) -> AnyPublisher<[ShaydZAVMo_AppModel], ShaydZAVMo_APIError> {
        return Just(availableApps)
            .map { apps in
                apps.filter { app in
                    let matchesQuery = query.isEmpty || 
                                     app.name.localizedCaseInsensitiveContains(query) ||
                                     app.description.localizedCaseInsensitiveContains(query)
                    
                    let matchesCategory = category == nil || app.category == category
                    
                    return matchesQuery && matchesCategory
                }
            }
            .setFailureType(to: ShaydZAVMo_APIError.self)
            .eraseToAnyPublisher()
    }
    
    /// Get app details by ID
    public func getAppDetails(appId: UUID) -> AnyPublisher<ShaydZAVMo_AppModel, ShaydZAVMo_APIError> {
        if let app = availableApps.first(where: { $0.id == appId }) {
            return Just(app)
                .setFailureType(to: ShaydZAVMo_APIError.self)
                .eraseToAnyPublisher()
        } else {
            return Fail(error: ShaydZAVMo_APIError.notFound)
                .eraseToAnyPublisher()
        }
    }
    
    // MARK: - App Installation
    
    /// Install an app
    public func installApp(appId: UUID, vmSessionId: String) -> AnyPublisher<Bool, ShaydZAVMo_APIError> {
        isLoading = true
        
        return Future<Bool, ShaydZAVMo_APIError> { [weak self] promise in
            guard let self = self,
                  let appIndex = self.availableApps.firstIndex(where: { $0.id == appId }) else {
                promise(.failure(.notFound))
                return
            }
            
            // Simulate installation process
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.isLoading = false
                
                var app = self.availableApps[appIndex]
                app = ShaydZAVMo_AppModel(
                    id: app.id,
                    name: app.name,
                    description: app.description,
                    iconName: app.iconName,
                    version: app.version,
                    category: app.category,
                    size: app.size,
                    isInstalled: true,
                    isCompatible: app.isCompatible,
                    requiresPermissions: app.requiresPermissions,
                    metadata: app.metadata,
                    createdAt: app.createdAt,
                    updatedAt: Date()
                )
                
                self.availableApps[appIndex] = app
                
                // Add to installed apps if not already there
                if !self.installedApps.contains(where: { $0.id == app.id }) {
                    self.installedApps.append(app)
                }
                
                promise(.success(true))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Uninstall an app
    public func uninstallApp(appId: UUID, vmSessionId: String) -> AnyPublisher<Bool, ShaydZAVMo_APIError> {
        isLoading = true
        
        return Future<Bool, ShaydZAVMo_APIError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown("Service not available")))
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.isLoading = false
                
                // Update available apps
                if let appIndex = self.availableApps.firstIndex(where: { $0.id == appId }) {
                    var app = self.availableApps[appIndex]
                    app = ShaydZAVMo_AppModel(
                        id: app.id,
                        name: app.name,
                        description: app.description,
                        iconName: app.iconName,
                        version: app.version,
                        category: app.category,
                        size: app.size,
                        isInstalled: false,
                        isCompatible: app.isCompatible,
                        requiresPermissions: app.requiresPermissions,
                        metadata: app.metadata,
                        createdAt: app.createdAt,
                        updatedAt: Date()
                    )
                    self.availableApps[appIndex] = app
                }
                
                // Remove from installed apps
                self.installedApps.removeAll { $0.id == appId }
                
                promise(.success(true))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Launch an installed app
    public func launchApp(appId: UUID, vmSessionId: String) -> AnyPublisher<Bool, ShaydZAVMo_APIError> {
        guard let app = installedApps.first(where: { $0.id == appId }),
              app.canLaunch else {
            return Fail(error: ShaydZAVMo_APIError.appLaunchFailed)
                .eraseToAnyPublisher()
        }
        
        return Future<Bool, ShaydZAVMo_APIError> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // Simulate app launch
                promise(.success(true))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - App Categories
    
    public var availableCategories: [String] {
        return Array(Set(availableApps.map { $0.category })).sorted()
    }
    
    public func getAppsInCategory(_ category: String) -> [ShaydZAVMo_AppModel] {
        return availableApps.filter { $0.category == category }
    }
    
    // MARK: - Private Methods
    
    private func loadSampleApps() {
        let sampleApps = [
            ShaydZAVMo_AppModel(
                name: "Chrome Browser",
                description: "Fast, secure, and free web browser built for the modern web.",
                iconName: "globe",
                version: "91.0.4472.124",
                category: "Browsers",
                size: 120_000_000,
                metadata: AppMetadata(
                    developer: "Google LLC",
                    website: "https://www.google.com/chrome/",
                    tags: ["browser", "web", "internet"],
                    rating: 4.5,
                    downloadCount: 1_000_000
                )
            ),
            ShaydZAVMo_AppModel(
                name: "WhatsApp",
                description: "Simple. Reliable. Secure messaging and calling for everyone.",
                iconName: "message.circle",
                version: "2.21.15.1",
                category: "Communication",
                size: 85_000_000,
                metadata: AppMetadata(
                    developer: "WhatsApp Inc.",
                    website: "https://www.whatsapp.com/",
                    tags: ["messaging", "chat", "communication"],
                    rating: 4.7,
                    downloadCount: 5_000_000
                )
            ),
            ShaydZAVMo_AppModel(
                name: "Instagram",
                description: "Create and share your photos, stories, and videos with friends.",
                iconName: "camera.circle",
                version: "194.0.0.12.117",
                category: "Social",
                size: 95_000_000,
                metadata: AppMetadata(
                    developer: "Instagram, Inc.",
                    website: "https://www.instagram.com/",
                    tags: ["social", "photos", "sharing"],
                    rating: 4.3,
                    downloadCount: 3_000_000
                )
            ),
            ShaydZAVMo_AppModel(
                name: "Spotify",
                description: "Listen to music and podcasts for free or go Premium for an ad-free experience.",
                iconName: "music.note.circle",
                version: "8.6.42.1242",
                category: "Music",
                size: 110_000_000,
                metadata: AppMetadata(
                    developer: "Spotify Ltd.",
                    website: "https://www.spotify.com/",
                    tags: ["music", "audio", "streaming"],
                    rating: 4.6,
                    downloadCount: 2_500_000
                )
            ),
            ShaydZAVMo_AppModel(
                name: "Microsoft Office",
                description: "Create, edit, and share documents, spreadsheets, and presentations.",
                iconName: "doc.circle",
                version: "16.0.14131.20278",
                category: "Productivity",
                size: 450_000_000,
                metadata: AppMetadata(
                    developer: "Microsoft Corporation",
                    website: "https://www.office.com/",
                    tags: ["office", "productivity", "documents"],
                    rating: 4.2,
                    downloadCount: 800_000
                )
            )
        ]
        
        self.availableApps = sampleApps
    }
}

// Type aliases for backward compatibility
public typealias AppCatalogService = ShaydZAVMo_AppCatalogService
public typealias ShaydZ_AppCatalogService = ShaydZAVMo_AppCatalogService
