import SwiftUI
import Combine

// Remove duplicate service declarations that exist elsewhere in the project
// These mock services will be replaced with imported actual services

@main
struct ShaydZAVMoApp: App {
    // Initialize services
    @StateObject private var authService = SupabaseAuthService.shared
    @StateObject private var appCatalogService = AppCatalogService.shared
    @StateObject private var vmService = VirtualMachineService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(appCatalogService)
                .environmentObject(vmService)
        }
    }
}

class VirtualMachineService: ObservableObject {
    static let shared = VirtualMachineService()
    
    // Basic implementation so ShaydZAVMoApp.swift can compile
    @Published var activeVMs: [String] = []
    @Published var isConnecting: Bool = false
    
    // Add any required properties and methods for the app to compile
    func connect(toVM vmId: String) {
        print("Connecting to VM: \(vmId)")
    }
    
    func disconnect() {
        print("Disconnecting from VM")
    }
}

class AppCatalogService: ObservableObject {
    static let shared = AppCatalogService()
    
    // Basic implementation so ShaydZAVMoApp.swift can compile
    @Published var availableApps: [String] = ["App 1", "App 2", "App 3"]
    
    func fetchAppCatalog() {
        print("Fetching app catalog")
    }
}
