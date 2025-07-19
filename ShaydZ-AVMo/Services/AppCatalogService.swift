import Foundation
import Combine

/// App catalog response models
struct AppDetailsModel: Codable {
    let id: String
    let name: String
    let packageName: String
    let description: String
    let version: String
    let versionCode: Int
    let iconUrl: String?        )
    }
    
    /// Map package name to SF Symbol icon name
    private func iconNameFromPackage(_ packageName: String) -> String {
        let lowercaseName = packageName.lowercased()
        
        if lowercaseName.contains("secure") || lowercaseName.contains("security") {
            return "shield.fill"
        } else if lowercaseName.contains("communication") || lowercaseName.contains("chat") || lowercaseName.contains("message") {
            return "message.fill"
        } else if lowercaseName.contains("finance") || lowercaseName.contains("banking") || lowercaseName.contains("money") {
            return "creditcard.fill"
        } else if lowercaseName.contains("development") || lowercaseName.contains("code") || lowercaseName.contains("developer") {
            return "hammer.fill"
        } else if lowercaseName.contains("productivity") || lowercaseName.contains("office") {
            return "doc.text.fill"
        } else if lowercaseName.contains("media") || lowercaseName.contains("video") || lowercaseName.contains("photo") {
            return "play.rectangle.fill"
        } else if lowercaseName.contains("game") {
            return "gamecontroller.fill"
        } else if lowercaseName.contains("social") {
            return "person.2.fill"
        } else if lowercaseName.contains("travel") {
            return "airplane"
        } else if lowercaseName.contains("health") || lowercaseName.contains("fitness") {
            return "heart.fill"
        } else if lowercaseName.contains("education") || lowercaseName.contains("learning") {
            return "book.fill"
        } else if lowercaseName.contains("news") {
            return "newspaper.fill"
        } else if lowercaseName.contains("weather") {
            return "cloud.sun.fill"
        } else if lowercaseName.contains("music") || lowercaseName.contains("audio") {
            return "music.note"
        } else if lowercaseName.contains("shopping") || lowercaseName.contains("store") {
            return "bag.fill"
        } else {
            return "app.fill"
        }
    }
    
    // MARK: - Mock Data for Development
    
    private func mockApps(search: String? = nil, category: String? = nil) -> [AppModel] {
        let allApps = [
            AppModel(
                id: UUID(),
                name: "Secure Notes",
                description: "Encrypted note-taking application with zero-knowledge architecture",
                iconName: "lock.doc.fill"
            ),
            AppModel(
                id: UUID(),
                name: "Enterprise Email",
                description: "Secure email client with advanced encryption and compliance features",
                iconName: "envelope.fill"
            ),
            AppModel(
                id: UUID(),
                name: "Code Editor Pro",
                description: "Professional code editor with syntax highlighting and debugging tools",
                iconName: "curlybraces"
            ),
            AppModel(
                id: UUID(),
                name: "Financial Dashboard",
                description: "Real-time financial data and analytics platform",
                iconName: "chart.line.uptrend.xyaxis"
            ),
            AppModel(
                id: UUID(),
                name: "Team Chat",
                description: "Secure team communication with file sharing and video calls",
                iconName: "message.badge.filled.fill"
            ),
            AppModel(
                id: UUID(),
                name: "Document Vault",
                description: "Secure document storage with advanced sharing controls",
                iconName: "folder.fill.badge.plus"
            ),
            AppModel(
                id: UUID(),
                name: "Remote Desktop",
                description: "Secure remote access to desktop environments",
                iconName: "desktopcomputer"
            ),
            AppModel(
                id: UUID(),
                name: "VPN Manager",
                description: "Enterprise VPN management and monitoring tool",
                iconName: "network.badge.shield.half.filled"
            )
        ]
        
        var filteredApps = allApps
        
        // Apply search filter
        if let search = search, !search.isEmpty {
            filteredApps = filteredApps.filter { app in
                app.name.localizedCaseInsensitiveContains(search) ||
                app.description.localizedCaseInsensitiveContains(search)
            }
        }
        
        // Apply category filter (basic implementation)
        if let category = category {
            filteredApps = filteredApps.filter { app in
                switch category.lowercased() {
                case "security":
                    return app.name.localizedCaseInsensitiveContains("secure") ||
                           app.name.localizedCaseInsensitiveContains("vpn")
                case "productivity":
                    return app.name.localizedCaseInsensitiveContains("notes") ||
                           app.name.localizedCaseInsensitiveContains("document") ||
                           app.name.localizedCaseInsensitiveContains("code")
                case "communication":
                    return app.name.localizedCaseInsensitiveContains("email") ||
                           app.name.localizedCaseInsensitiveContains("chat")
                case "finance":
                    return app.name.localizedCaseInsensitiveContains("financial")
                default:
                    return true
                }
            }
        }
        
        return filteredApps
    }
}tegory: String?
    let developer: String?
    let size: Int?
    let isSystem: Bool
    let isApproved: Bool
    let uploadedAt: String
    let lastUpdated: String
}

class AppCatalogService: ObservableObject {
    static let shared = AppCatalogService()
    private let networkService = NetworkService.shared
    private let supabaseDatabase = SupabaseDatabaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    /// Published properties for reactive UI updates
    @Published var availableApps: [AppModel] = []
    @Published var userInstalledApps: [AppModel] = []
    @Published var categories: [String] = []
    @Published var isLoading = false
    
    private init() {}
    
    /// Fetch available apps, optionally filtered - now uses Supabase
    func fetchAvailableApps(category: String? = nil, search: String? = nil) -> AnyPublisher<[AppModel], APIError> {
        #if DEBUG
        // For demo/testing, use mock data
        if networkService.getAuthToken()?.starts(with: "demo_token_") ?? false {
            // Artificial delay
            return Just(mockApps(search: search, category: category))
                .delay(for: .seconds(1), scheduler: RunLoop.main)
                .setFailureType(to: APIError.self)
                .eraseToAnyPublisher()
        }
        #endif
        
        isLoading = true
        
        let publisher: AnyPublisher<[SupabaseAppCatalogItem], SupabaseError>
        
        if let search = search, !search.isEmpty {
            // Search apps
            publisher = supabaseDatabase.searchApps(query: search)
        } else if let category = category {
            // Filter by category
            publisher = supabaseDatabase.fetchAppCatalog(category: category)
        } else {
            // Fetch all apps
            publisher = supabaseDatabase.fetchAppCatalog()
        }
        
        return publisher
            .map { supabaseApps in
                supabaseApps.map { self.convertSupabaseAppToAppModel($0) }
            }
            .mapError { supabaseError in
                APIError.badRequest(supabaseError.localizedDescription)
            }
            .handleEvents(
                receiveOutput: { [weak self] apps in
                    DispatchQueue.main.async {
                        self?.availableApps = apps
                        self?.isLoading = false
                    }
                },
                receiveCompletion: { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                    }
                }
            )
    }
    
    /// Fetch app categories - now uses Supabase
    func getCategories() -> AnyPublisher<[String], APIError> {
        #if DEBUG
        // For demo/testing, use mock data
        if networkService.getAuthToken()?.starts(with: "demo_token_") ?? false {
            return Just(["Productivity", "Security", "Communication", "Development", "Finance"])
                .delay(for: .seconds(0.5), scheduler: RunLoop.main)
                .setFailureType(to: APIError.self)
                .eraseToAnyPublisher()
        }
        #endif
        
        return supabaseDatabase.fetchAppCategories()
            .mapError { supabaseError in
                APIError.badRequest(supabaseError.localizedDescription)
            }
            .handleEvents(receiveOutput: { [weak self] categories in
                DispatchQueue.main.async {
                    self?.categories = categories
                }
            })
            .eraseToAnyPublisher()
    }
    
    /// Get app details - now uses Supabase
    func getAppDetails(appId: String) -> AnyPublisher<AppDetailsModel, APIError> {
        #if DEBUG
        // For demo/testing, use mock data
        if networkService.getAuthToken()?.starts(with: "demo_token_") ?? false {
            // Find matching mock app
            guard let mockApp = mockApps().first(where: { $0.id.uuidString == appId }) else {
                return Fail(error: APIError.badRequest("App not found"))
                    .eraseToAnyPublisher()
            }
            
            // Create mock details
            let details = AppDetailsModel(
                id: mockApp.id.uuidString,
                name: mockApp.name,
                packageName: "com.shaydz.avmo.\(mockApp.name.lowercased().replacingOccurrences(of: " ", with: ""))",
                description: mockApp.description,
                version: "1.0.0",
                versionCode: 1,
                iconUrl: nil,
                category: mockApp.name.contains("Secure") ? "Security" : "Productivity",
                developer: "ShaydZ Inc.",
                size: Int.random(in: 5000000...50000000),
                isSystem: false,
                isApproved: true,
                uploadedAt: "2025-06-01T00:00:00Z",
                lastUpdated: "2025-07-01T00:00:00Z"
            )
            
            return Just(details)
                .delay(for: .seconds(0.5), scheduler: RunLoop.main)
                .setFailureType(to: APIError.self)
                .eraseToAnyPublisher()
        }
        #endif
        
        return supabaseDatabase.fetchAppCatalog()
            .map { apps in
                apps.first { $0.id == appId }
            }
            .tryMap { app in
                guard let app = app else {
                    throw SupabaseError(error: "app_not_found", errorDescription: nil, message: "App not found")
                }
                return self.convertSupabaseAppToAppDetailsModel(app)
            }
            .mapError { error in
                if let supabaseError = error as? SupabaseError {
                    return APIError.badRequest(supabaseError.localizedDescription)
                }
                return APIError.badRequest(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    /// Install app for current user - new Supabase method
    func installApp(appId: String) -> AnyPublisher<Bool, APIError> {
        guard let userId = SupabaseAuthService.shared.currentUser?.id else {
            return Fail(error: APIError.unauthorized).eraseToAnyPublisher()
        }
        
        return supabaseDatabase.installApp(userId: userId, appId: appId)
            .map { _ in true }
            .mapError { supabaseError in
                APIError.badRequest(supabaseError.localizedDescription)
            }
            .handleEvents(receiveOutput: { [weak self] _ in
                // Refresh user installed apps
                self?.fetchUserInstalledApps()
            })
            .eraseToAnyPublisher()
    }
    
    /// Uninstall app for current user - new Supabase method
    func uninstallApp(appId: String) -> AnyPublisher<Bool, APIError> {
        guard let userId = SupabaseAuthService.shared.currentUser?.id else {
            return Fail(error: APIError.unauthorized).eraseToAnyPublisher()
        }
        
        return supabaseDatabase.uninstallApp(userId: userId, appId: appId)
            .map { true }
            .mapError { supabaseError in
                APIError.badRequest(supabaseError.localizedDescription)
            }
            .handleEvents(receiveOutput: { [weak self] _ in
                // Refresh user installed apps
                self?.fetchUserInstalledApps()
            })
            .eraseToAnyPublisher()
    }
    
    /// Fetch user's installed apps - new Supabase method
    func fetchUserInstalledApps() {
        guard let userId = SupabaseAuthService.shared.currentUser?.id else {
            return
        }
        
        supabaseDatabase.fetchUserApps(for: userId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to fetch user apps: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] installations in
                    // Convert installations to AppModels
                    let appIds = installations.map { $0.appId }
                    
                    // Fetch app details for installed apps
                    self?.supabaseDatabase.fetchAppCatalog()
                        .map { apps in
                            apps.filter { appIds.contains($0.id) }
                                .map { self?.convertSupabaseAppToAppModel($0) }
                                .compactMap { $0 }
                        }
                        .sink(
                            receiveCompletion: { _ in },
                            receiveValue: { apps in
                                DispatchQueue.main.async {
                                    self?.userInstalledApps = apps
                                }
                            }
                        )
                        .store(in: &self?.cancellables ?? Set<AnyCancellable>())
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Helper Methods
    
    /// Convert Supabase app to AppModel
    private func convertSupabaseAppToAppModel(_ supabaseApp: SupabaseAppCatalogItem) -> AppModel {
        return AppModel(
            id: UUID(uuidString: supabaseApp.id) ?? UUID(),
            name: supabaseApp.name,
            description: supabaseApp.description ?? "No description available",
            iconName: iconNameFromPackage(supabaseApp.name)
        )
    }
    
    /// Convert Supabase app to AppDetailsModel
    private func convertSupabaseAppToAppDetailsModel(_ supabaseApp: SupabaseAppCatalogItem) -> AppDetailsModel {
        return AppDetailsModel(
            id: supabaseApp.id,
            name: supabaseApp.name,
            packageName: "com.shaydz.avmo.\(supabaseApp.name.lowercased().replacingOccurrences(of: " ", with: ""))",
            description: supabaseApp.description ?? "No description available",
            version: supabaseApp.version,
            versionCode: 1,
            iconUrl: supabaseApp.iconUrl,
            category: supabaseApp.category,
            developer: "ShaydZ Inc.",
            size: nil,
            isSystem: false,
            isApproved: supabaseApp.isActive,
            uploadedAt: supabaseApp.createdAt,
            lastUpdated: supabaseApp.updatedAt
        )
    }
        if networkService.getAuthToken()?.starts(with: "demo_token_") ?? false {
            return Just(["Productivity", "Security", "Communication", "Finance", "Human Resources"])
                .delay(for: .seconds(0.5), scheduler: RunLoop.main)
                .setFailureType(to: APIError.self)
                .eraseToAnyPublisher()
        }
        #endif
        
        return networkService.request(
            endpoint: "\(APIConfig.appsEndpoint)/categories"
        )
    }
    
    /// Launch an app
    func launchApp(appId: String) -> AnyPublisher<Bool, APIError> {
        // In a real implementation, this would interact with the VM service
        // to launch the app in the virtual environment
        return Just(true)
            .delay(for: .seconds(0.5), scheduler: RunLoop.main)
            .setFailureType(to: APIError.self)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Helper methods
    
    /// Map package name to SF Symbol icon name
    private func iconNameFromPackage(_ packageName: String) -> String {
        if packageName.contains("mail") {
            return "envelope.fill"
        } else if packageName.contains("docs") || packageName.contains("document") {
            return "doc.fill"
        } else if packageName.contains("files") || packageName.contains("folder") {
            return "folder.fill"
        } else if packageName.contains("browser") || packageName.contains("web") {
            return "safari.fill"
        } else if packageName.contains("chat") || packageName.contains("message") {
            return "message.fill"
        } else if packageName.contains("hr") || packageName.contains("human") {
            return "person.2.fill"
        } else if packageName.contains("expense") || packageName.contains("finance") {
            return "creditcard.fill"
        } else if packageName.contains("vpn") || packageName.contains("security") {
            return "lock.shield.fill"
        } else if packageName.contains("calendar") {
            return "calendar"
        } else if packageName.contains("crm") || packageName.contains("customer") {
            return "person.crop.circle.fill.badge.checkmark"
        } else if packageName.contains("analytics") || packageName.contains("dashboard") {
            return "chart.bar.fill"
        } else if packageName.contains("project") || packageName.contains("task") {
            return "list.bullet.clipboard"
        } else {
            return "app.fill"
        }
    }
    
    // MARK: - Mock data for demo/testing
    
    /// Generate mock apps with optional filtering
    private func mockApps(search: String? = nil, category: String? = nil) -> [AppModel] {
        var apps = [
            AppModel(id: UUID(), name: "Secure Mail", description: "Enterprise email client with encryption", iconName: "envelope.fill"),
            AppModel(id: UUID(), name: "SecureDocs", description: "Document editor with DRM protection", iconName: "doc.fill"),
            AppModel(id: UUID(), name: "Cloud Files", description: "Access corporate files securely", iconName: "folder.fill"),
            AppModel(id: UUID(), name: "Secure Browser", description: "Protected web browsing with policy enforcement", iconName: "safari.fill"),
            AppModel(id: UUID(), name: "Work Chat", description: "Encrypted team messaging platform", iconName: "message.fill"),
            AppModel(id: UUID(), name: "HR Portal", description: "Access company HR resources", iconName: "person.2.fill"),
            AppModel(id: UUID(), name: "Expense Report", description: "Submit and track expenses", iconName: "creditcard.fill"),
            AppModel(id: UUID(), name: "VPN Client", description: "Connect to corporate network", iconName: "lock.shield.fill"),
            AppModel(id: UUID(), name: "Calendar", description: "Secure scheduling application", iconName: "calendar"),
            AppModel(id: UUID(), name: "CRM", description: "Customer relationship management", iconName: "person.crop.circle.fill.badge.checkmark"),
            AppModel(id: UUID(), name: "Analytics Dashboard", description: "Business intelligence reports", iconName: "chart.bar.fill"),
            AppModel(id: UUID(), name: "Project Management", description: "Track projects and tasks", iconName: "list.bullet.clipboard")
        ]
        
        // Apply search filter if provided
        if let search = search, !search.isEmpty {
            apps = apps.filter { 
                $0.name.lowercased().contains(search.lowercased()) || 
                $0.description.lowercased().contains(search.lowercased())
            }
        }
        
        // Apply category filter if provided
        if let category = category {
            // Map apps to categories based on name
            if category == "Security" {
                apps = apps.filter { $0.name.contains("Secure") || $0.name == "VPN Client" }
            } else if category == "Productivity" {
                apps = apps.filter { 
                    $0.name.contains("Docs") || 
                    $0.name.contains("Files") ||
                    $0.name.contains("Project") ||
                    $0.name == "Calendar"
                }
            } else if category == "Communication" {
                apps = apps.filter { 
                    $0.name.contains("Mail") || 
                    $0.name.contains("Chat") ||
                    $0.name.contains("Browser")
                }
            } else if category == "Human Resources" {
                apps = apps.filter { $0.name.contains("HR") }
            } else if category == "Finance" {
                apps = apps.filter { 
                    $0.name.contains("Expense") || 
                    $0.name.contains("Analytics") ||
                    $0.name.contains("CRM")
                }
            }
        }
        
        return apps
    }
}
}
