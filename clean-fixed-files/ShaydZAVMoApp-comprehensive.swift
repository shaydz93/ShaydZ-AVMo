import SwiftUI
import Combine

/// Main application entry point for ShaydZ AVMo
@main
struct ShaydZAVMo_App: App {
    @StateObject private var authService = ShaydZAVMo_AuthenticationService.shared
    @StateObject private var vmService = ShaydZAVMo_VirtualMachineService.shared
    @StateObject private var appCatalogService = ShaydZAVMo_AppCatalogService.shared
    @StateObject private var networkService = ShaydZAVMo_NetworkService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(vmService)
                .environmentObject(appCatalogService)
                .environmentObject(networkService)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // Initialize services and perform any startup tasks
        print("ShaydZ AVMo starting up...")
        
        // Check for stored authentication
        if authService.isAuthenticated {
            print("User already authenticated")
        }
        
        // Initialize network monitoring
        if networkService.isConnected {
            print("Network connection available")
        }
    }
}

// Type aliases for backward compatibility
typealias ShaydZAVMoApp = ShaydZAVMo_App
