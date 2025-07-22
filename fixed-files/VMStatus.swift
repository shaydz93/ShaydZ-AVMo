import Foundation

/// Model representing the status of a virtual machine
struct VMStatus: Codable, Equatable {
    let id: String
    let appId: String?
    let status: String
    let ipAddress: String?
    let port: Int?
    let connectionUrl: String?
    let startedAt: Date?
    let elapsedSeconds: Int?
    
    /// Calculate current elapsed time
    var currentElapsedTime: TimeInterval {
        guard let startedAt = startedAt else { return 0 }
        return Date().timeIntervalSince(startedAt)
    }
    
    /// Format the elapsed time as a string
    var formattedElapsedTime: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: currentElapsedTime) ?? "0s"
    }
    
    /// Check if VM is in a running state
    var isRunning: Bool {
        return status == "running" || status == "active" || status == "connected"
    }
    
    /// Check if VM is still starting
    var isStarting: Bool {
        return status == "initializing" || status == "provisioning" || status == "starting"
    }
    
    static func == (lhs: VMStatus, rhs: VMStatus) -> Bool {
        return lhs.id == rhs.id && lhs.status == rhs.status
    }
    
    static var mockStatus: VMStatus {
        return VMStatus(
            id: "mock-vm-id",
            appId: "com.example.securemessenger",
            status: "running",
            ipAddress: "192.168.1.1",
            port: 8080,
            connectionUrl: "https://vm.shaydz-avmo.io/connect/mock-vm-id",
            startedAt: Date().addingTimeInterval(-300), // 5 minutes ago
            elapsedSeconds: 300
        )
    }
}
