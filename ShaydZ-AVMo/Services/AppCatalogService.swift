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
    let iconUrl: String?
    let category: String?
    let developer: String?
    let size: Int?
    let isSystem: Bool
    let isApproved: Bool
    let uploadedAt: String
    let lastUpdated: String
}

class AppCatalogService {
    static let shared = AppCatalogService()
    private let networkService = NetworkService.shared
    
    private init() {}
    
    /// Fetch available apps, optionally filtered
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
        
        var endpoint = "\(APIConfig.appsEndpoint)/apps"
        var queryParams = [String]()
        
        if let category = category {
            queryParams.append("category=\(category)")
        }
        
        if let search = search {
            queryParams.append("search=\(search)")
        }
        
        if !queryParams.isEmpty {
            endpoint += "?\(queryParams.joined(separator: "&"))"
        }
        
        return networkService.request(
            endpoint: endpoint
        )
        .map { (appDetails: [AppDetailsModel]) -> [AppModel] in
            return appDetails.map { details in
                return AppModel(
                    id: UUID(uuidString: details.id) ?? UUID(),
                    name: details.name,
                    description: details.description,
                    iconName: self.iconNameFromPackage(details.packageName) // Map from package to SF Symbol
                )
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Get app details
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
        
        return networkService.request(
            endpoint: "\(APIConfig.appsEndpoint)/apps/\(appId)"
        )
    }
    
    /// Get available app categories
    func getCategories() -> AnyPublisher<[String], APIError> {
        #if DEBUG
        // For demo/testing, use mock data
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
