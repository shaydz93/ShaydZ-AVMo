import SwiftUI
import Combine

@main
struct ShaydZAVMoApp: App {
    // Initialize Supabase services
    @StateObject private var authService = SupabaseAuthService.shared
    @StateObject private var appCatalogService = AppCatalogService.shared
    @StateObject private var vmService = VirtualMachineService.shared
    
    // Initialize UTM-enhanced services
    @StateObject private var enhancedVMService = UTMEnhancedVirtualMachineService.shared
    @StateObject private var configManager = QEMUVMConfigurationManager.shared
    
    // Initialize Supabase integration services
    @StateObject private var integrationManager = SupabaseIntegrationManager.shared
    @StateObject private var demoService = SupabaseDemoService.shared
    
    var body: some Scene {
        WindowGroup {
            IntegratedAppView()
                .environmentObject(authService)
                .environmentObject(appCatalogService)
                .environmentObject(vmService)
                .environmentObject(enhancedVMService)
                .environmentObject(configManager)
                .environmentObject(integrationManager)
                .environmentObject(demoService)
                .onAppear {
                    // Initialize services on app launch
                    setupSupabaseServices()
                    setupEnhancedVirtualization()
                    setupSupabaseIntegration()
                }
        }
    }
    
    private func setupSupabaseServices() {
        // Check for existing authentication
        if authService.isAuthenticated {
            // Load user data if authenticated
            appCatalogService.fetchUserInstalledApps()
        }
    }
    
    private func setupEnhancedVirtualization() {
        // Initialize enhanced VM services
        enhancedVMService.startPerformanceMonitoring()
        
        // Setup configuration validation
        configManager.objectWillChange.sink { _ in
            print("VM configuration updated")
        }
        .store(in: &cancellables)
    }
    
    private func setupSupabaseIntegration() {
        // Initialize Supabase integration
        integrationManager.initializeConnection()
        
        // Setup real-time features when connected
        integrationManager.$isConnected
            .filter { $0 }
            .sink { _ in
                integrationManager.startRealtimeSubscriptions()
            }
            .store(in: &cancellables)
        
        // Monitor integration health
        integrationManager.$connectionStatus
            .sink { status in
                print("🔄 Supabase connection status: \(status.displayText)")
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
}

// Import Combine for reactive programming
import Combine
