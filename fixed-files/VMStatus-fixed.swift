import Foundation

/// Model representing the status of a virtual machine with namespace prefix to avoid conflicts
public struct ShaydZ_VMStatus: Codable, Equatable {
    public let id: String
    public let appId: String?
    public let status: String
    public let ipAddress: String?
    public let port: Int?
    public let connectionUrl: String?
    public let startedAt: Date?
    public let elapsedSeconds: Int?
    
    public init(
        id: String,
        appId: String?,
        status: String,
        ipAddress: String?,
        port: Int?,
        connectionUrl: String?,
        startedAt: Date?,
        elapsedSeconds: Int?
    ) {
        self.id = id
        self.appId = appId
        self.status = status
        self.ipAddress = ipAddress
        self.port = port
        self.connectionUrl = connectionUrl
        self.startedAt = startedAt
        self.elapsedSeconds = elapsedSeconds
    }
    
    /// Calculate current elapsed time
    public var currentElapsedTime: TimeInterval {
        guard let startedAt = startedAt else { return 0 }
        return Date().timeIntervalSince(startedAt)
    }
    
    /// Format the elapsed time as a string
    public var formattedElapsedTime: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: currentElapsedTime) ?? "0s"
    }
    
    /// Check if VM is in a running state
    public var isRunning: Bool {
        return status == "running" || status == "active" || status == "connected"
    }
    
    /// Check if VM is still starting
    public var isStarting: Bool {
        return status == "initializing" || status == "provisioning" || status == "starting"
    }
    
    public static func == (lhs: ShaydZ_VMStatus, rhs: ShaydZ_VMStatus) -> Bool {
        return lhs.id == rhs.id && lhs.status == rhs.status
    }
    
    public static var mockStatus: ShaydZ_VMStatus {
        return ShaydZ_VMStatus(
            id: "mock-vm-id",
            appId: "mock-app-id",
            status: "running",
            ipAddress: "192.168.1.100",
            port: 8080,
            connectionUrl: "wss://192.168.1.100:8080/vm/connect",
            startedAt: Date().addingTimeInterval(-300), // 5 minutes ago
            elapsedSeconds: 300
        )
    }
}

// Type alias for backward compatibility
public typealias VMStatus = ShaydZ_VMStatus
