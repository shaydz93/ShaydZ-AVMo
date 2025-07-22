import SwiftUI
import Combine

@main
struct ShaydZAVMoApp: App {
    // Use prefixed versions to avoid ambiguity
    @StateObject private var authService = ShaydZ_SupabaseAuthService.shared
    @StateObject private var appCatalogService = ShaydZ_AppCatalogService.shared
    @StateObject private var vmService = ShaydZ_VirtualMachineService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(appCatalogService)
                .environmentObject(vmService)
        }
    }
}

// VirtualMachineService with prefix to avoid conflicts
public class ShaydZ_VirtualMachineService: ObservableObject {
    public static let shared = ShaydZ_VirtualMachineService()
    
    // Basic implementation so ShaydZAVMoApp.swift can compile
    @Published public var activeVMs: [String] = []
    @Published public var isConnecting: Bool = false
    
    // Add any required properties and methods for the app to compile
    public func connect(toVM vmId: String) {
        print("Connecting to VM: \(vmId)")
    }
    
    public func disconnect() {
        print("Disconnecting from VM")
    }
}

// Add type alias for backward compatibility
public typealias VirtualMachineService = ShaydZ_VirtualMachineService
