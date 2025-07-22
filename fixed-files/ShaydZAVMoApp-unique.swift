import SwiftUI
import Combine

@main
struct ShaydZAVMoApp: App {
    // Use uniquely named versions to avoid ambiguity
    @StateObject private var authService = ShaydZ_SupabaseAuthService.shared
    @StateObject private var appCatalogService = ShaydZ_AppCatalogService.shared
    @StateObject private var vmService = ShaydZUnique_VirtualMachineService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(appCatalogService)
                .environmentObject(vmService)
        }
    }
}
