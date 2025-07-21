import SwiftUI
import Combine

@main
struct ShaydZAVMoApp: App {
    // Initialize security toolkit services
    @StateObject private var securityToolkitModel = SecurityToolkitViewModel()
    
    // Initialize Supabase services
    @StateObject private var authService = SupabaseAuthService.shared
    @StateObject private var appCatalogService = SupabaseAppCatalogService.shared
    @StateObject private var vmService = SupabaseVMService.shared
    
    // Initialize UTM-enhanced services
    @StateObject private var enhancedVMService = UTMEnhancedVirtualMachineService.shared
    @StateObject private var configManager = QEMUVMConfigurationManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(securityToolkitModel)
                .environmentObject(authService)
                .environmentObject(appCatalogService)
                .environmentObject(vmService)
                .environmentObject(enhancedVMService)
                .environmentObject(configManager)
        }
    }
}
