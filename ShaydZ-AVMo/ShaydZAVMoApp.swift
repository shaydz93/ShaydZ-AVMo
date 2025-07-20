import SwiftUI
import Combine

// Mock services for compilation
class SupabaseAuthService: ObservableObject {
    static let shared = SupabaseAuthService()
}

class UTMEnhancedVirtualMachineService: ObservableObject {
    static let shared = UTMEnhancedVirtualMachineService()
}

class QEMUVMConfigurationManager: ObservableObject {
    static let shared = QEMUVMConfigurationManager()
}

class SupabaseIntegrationManager: ObservableObject {
    static let shared = SupabaseIntegrationManager()
}

class SupabaseDemoService: ObservableObject {
    static let shared = SupabaseDemoService()
}

@main
struct ShaydZAVMoApp: App {
    // Initialize services
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
            ContentView()
                .environmentObject(authService)
                .environmentObject(appCatalogService)
                .environmentObject(vmService)
                .environmentObject(enhancedVMService)
                .environmentObject(configManager)
                .environmentObject(integrationManager)
                .environmentObject(demoService)
        }
    }
}
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
