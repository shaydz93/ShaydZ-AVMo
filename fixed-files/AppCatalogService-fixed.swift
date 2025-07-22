import Foundation
import Combine

/// Service for accessing app catalog data
public class ShaydZ_AppCatalogService {
    public static let shared = ShaydZ_AppCatalogService()
    
    // Example app catalog for mock data
    private var mockApps: [AppModel] = [
        AppModel(id: "1", name: "Browser", description: "Secure browser with privacy features", iconName: "safari", isInstalled: true, isFeatured: true, lastUsed: Date().addingTimeInterval(-1800)),
        AppModel(id: "2", name: "Notes", description: "Simple note taking app", iconName: "note.text", isInstalled: true, isFeatured: false, lastUsed: Date().addingTimeInterval(-86400)),
        AppModel(id: "3", name: "Calculator", description: "Scientific calculator", iconName: "function", isInstalled: true, isFeatured: false, lastUsed: nil),
        AppModel(id: "4", name: "Calendar", description: "Schedule management", iconName: "calendar", isInstalled: false, isFeatured: true, lastUsed: nil),
        AppModel(id: "5", name: "Email Client", description: "Secure email access", iconName: "envelope", isInstalled: false, isFeatured: true, lastUsed: nil)
    ]
    
    private let networkService: ShaydZ_AppCatalogNetworkService
    
    public init(networkService: ShaydZ_AppCatalogNetworkService = ShaydZ_AppCatalogNetworkService.shared) {
        self.networkService = networkService
    }
    
    /// Fetch the app catalog
    public func fetchAppCatalog(completion: @escaping (Result<[AppModel], ShaydZ_APIError>) -> Void) {
        // In a real implementation, this would call an API endpoint
        // For this mock, we'll just return the mock apps
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion(.success(self.mockApps))
        }
    }
    
    /// Get details for a specific app
    public func getAppDetails(appId: String, completion: @escaping (Result<AppModel, ShaydZ_APIError>) -> Void) {
        if let app = mockApps.first(where: { $0.id == appId }) {
            completion(.success(app))
        } else {
            completion(.failure(ShaydZ_APIError.notFound))
        }
    }
    
    /// Install an app
    public func installApp(appId: String, completion: @escaping (Result<Bool, ShaydZ_APIError>) -> Void) {
        // In a real implementation, this would trigger an app installation
        // For this mock, we'll just update our local data
        
        if let index = mockApps.firstIndex(where: { $0.id == appId }) {
            mockApps[index].isInstalled = true
            completion(.success(true))
        } else {
            completion(.failure(ShaydZ_APIError.notFound))
        }
    }
    
    /// Launch an app
    public func launchApp(appId: String, completion: @escaping (Result<Bool, ShaydZ_APIError>) -> Void) {
        // In a real implementation, this would launch the app in the VM
        // For this mock, we'll just update the lastUsed timestamp
        
        if let index = mockApps.firstIndex(where: { $0.id == appId }) {
            mockApps[index].lastUsed = Date()
            completion(.success(true))
        } else {
            completion(.failure(ShaydZ_APIError.notFound))
        }
    }
}

// Type alias for backward compatibility
public typealias AppCatalogService = ShaydZ_AppCatalogService
