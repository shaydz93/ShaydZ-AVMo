import Foundation
import Combine

/// Service for accessing app catalog data
public class ShaydZ_AppCatalogService: ObservableObject {
    public static let shared = ShaydZ_AppCatalogService()
    
    // Use the corrected mock apps
    private var mockApps: [AppModel] = AppModel.mockApps
    
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
