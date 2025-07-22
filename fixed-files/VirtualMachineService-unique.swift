import Foundation
import Combine

/// Unique VirtualMachineService to avoid conflicts
public class ShaydZUnique_VirtualMachineService: ObservableObject {
    public static let shared = ShaydZUnique_VirtualMachineService()
    
    // Basic implementation so ShaydZAVMoApp.swift can compile
    @Published public var activeVMs: [String] = []
    @Published public var isConnecting: Bool = false
    
    private init() {}
    
    // Add any required properties and methods for the app to compile
    public func connect(toVM vmId: String) {
        print("Connecting to VM: \(vmId)")
        isConnecting = true
        
        // Simulate connection process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isConnecting = false
            self.activeVMs.append(vmId)
        }
    }
    
    public func disconnect() {
        print("Disconnecting from VM")
        activeVMs.removeAll()
    }
}

// Add type alias for backward compatibility
public typealias VirtualMachineService = ShaydZUnique_VirtualMachineService
