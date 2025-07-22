import Foundation
import Combine

/// Comprehensive app library view model for ShaydZ AVMo
public class ShaydZAVMo_AppLibraryViewModel: ObservableObject {
    @Published public var availableApps: [ShaydZAVMo_AppModel] = []
    @Published public var installedApps: [ShaydZAVMo_AppModel] = []
    @Published public var filteredApps: [ShaydZAVMo_AppModel] = []
    @Published public var categories: [String] = []
    @Published public var isLoading: Bool = false
    @Published public var selectedApp: ShaydZAVMo_AppModel?
    @Published public var errorMessage: String?
    @Published public var searchText: String = "" {
        didSet {
            filterApps()
        }
    }
    @Published public var selectedCategory: String? {
        didSet {
            filterApps()
        }
    }
    @Published public var showInstalledOnly: Bool = false {
        didSet {
            filterApps()
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    private let appCatalogService = ShaydZAVMo_AppCatalogService.shared
    private let vmService = ShaydZAVMo_VirtualMachineService.shared
    private let authService = ShaydZAVMo_AuthenticationService.shared
    
    public init() {
        setupBindings()
        loadApps()
    }
    
    // MARK: - Public Methods
    
    /// Refresh app catalog
    public func refreshApps() {
        loadApps()
    }
    
    /// Install an app
    public func installApp(_ app: ShaydZAVMo_AppModel) {
        guard let currentUser = authService.currentUser,
              let activeSession = vmService.activeSessions.first(where: { $0.userId == currentUser.id && $0.status == .running }) else {
            errorMessage = "No active virtual machine session"
            return
        }
        
        appCatalogService.installApp(appId: app.id, vmSessionId: activeSession.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] success in
                    if success {
                        self?.loadApps()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    /// Uninstall an app
    public func uninstallApp(_ app: ShaydZAVMo_AppModel) {
        guard let currentUser = authService.currentUser,
              let activeSession = vmService.activeSessions.first(where: { $0.userId == currentUser.id }) else {
            errorMessage = "No virtual machine session found"
            return
        }
        
        appCatalogService.uninstallApp(appId: app.id, vmSessionId: activeSession.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] success in
                    if success {
                        self?.loadApps()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    /// Launch an app
    public func launchApp(_ app: ShaydZAVMo_AppModel) {
        guard app.canLaunch else {
            errorMessage = "App cannot be launched"
            return
        }
        
        guard let currentUser = authService.currentUser,
              let activeSession = vmService.activeSessions.first(where: { $0.userId == currentUser.id && $0.status == .running }) else {
            errorMessage = "No active virtual machine session"
            return
        }
        
        appCatalogService.launchApp(appId: app.id, vmSessionId: activeSession.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] success in
                    if success {
                        // App launched successfully
                        self?.errorMessage = nil
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    /// Search apps
    public func searchApps(query: String, category: String? = nil) {
        appCatalogService.searchApps(query: query, category: category)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] apps in
                    self?.filteredApps = apps
                }
            )
            .store(in: &cancellables)
    }
    
    /// Get app details
    public func getAppDetails(appId: UUID) {
        appCatalogService.getAppDetails(appId: appId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] app in
                    self?.selectedApp = app
                }
            )
            .store(in: &cancellables)
    }
    
    /// Clear error message
    public func clearError() {
        errorMessage = nil
    }
    
    /// Clear selection
    public func clearSelection() {
        selectedApp = nil
    }
    
    // MARK: - Computed Properties
    
    public var hasActiveVMSession: Bool {
        guard let currentUser = authService.currentUser else { return false }
        return vmService.activeSessions.contains { $0.userId == currentUser.id && $0.status.isActive }
    }
    
    public var canInstallApps: Bool {
        guard let currentUser = authService.currentUser else { return false }
        return vmService.activeSessions.contains { $0.userId == currentUser.id && $0.status == .running }
    }
    
    public var appStats: (total: Int, installed: Int, available: Int) {
        let total = availableApps.count
        let installed = installedApps.count
        let available = total - installed
        return (total: total, installed: installed, available: available)
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Observe app catalog service changes
        appCatalogService.$availableApps
            .receive(on: DispatchQueue.main)
            .sink { [weak self] apps in
                self?.availableApps = apps
                self?.updateCategories()
                self?.filterApps()
            }
            .store(in: &cancellables)
        
        appCatalogService.$installedApps
            .receive(on: DispatchQueue.main)
            .sink { [weak self] apps in
                self?.installedApps = apps
                self?.filterApps()
            }
            .store(in: &cancellables)
        
        appCatalogService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        appCatalogService.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
    }
    
    private func loadApps() {
        appCatalogService.fetchAvailableApps()
            .sink(
                receiveCompletion: { completion in
                    // Handled by service binding
                },
                receiveValue: { _ in
                    // Handled by service binding
                }
            )
            .store(in: &cancellables)
    }
    
    private func updateCategories() {
        categories = appCatalogService.availableCategories
    }
    
    private func filterApps() {
        var apps = showInstalledOnly ? installedApps : availableApps
        
        // Filter by search text
        if !searchText.isEmpty {
            apps = apps.filter { app in
                app.name.localizedCaseInsensitiveContains(searchText) ||
                app.description.localizedCaseInsensitiveContains(searchText) ||
                app.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by category
        if let selectedCategory = selectedCategory {
            apps = apps.filter { $0.category == selectedCategory }
        }
        
        filteredApps = apps
    }
}

// Type aliases for backward compatibility
public typealias AppLibraryViewModel = ShaydZAVMo_AppLibraryViewModel
public typealias ShaydZ_AppLibraryViewModel = ShaydZAVMo_AppLibraryViewModel
