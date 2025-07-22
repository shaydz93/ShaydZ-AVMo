import Foundation

/// Virtual Machine status enumeration
public enum ShaydZAVMo_VMStatus: String, Codable, CaseIterable {
    case stopped = "stopped"
    case starting = "starting"
    case running = "running"
    case pausing = "pausing"
    case paused = "paused"
    case resuming = "resuming"
    case stopping = "stopping"
    case error = "error"
    case unknown = "unknown"
    
    public var isActive: Bool {
        switch self {
        case .running, .starting, .pausing, .resuming:
            return true
        default:
            return false
        }
    }
    
    public var canStart: Bool {
        return self == .stopped
    }
    
    public var canStop: Bool {
        return [.running, .paused].contains(self)
    }
    
    public var canPause: Bool {
        return self == .running
    }
    
    public var canResume: Bool {
        return self == .paused
    }
    
    public var displayName: String {
        switch self {
        case .stopped:
            return "Stopped"
        case .starting:
            return "Starting..."
        case .running:
            return "Running"
        case .pausing:
            return "Pausing..."
        case .paused:
            return "Paused"
        case .resuming:
            return "Resuming..."
        case .stopping:
            return "Stopping..."
        case .error:
            return "Error"
        case .unknown:
            return "Unknown"
        }
    }
}

/// Virtual Machine session model
public struct ShaydZAVMo_VMSession: Identifiable, Codable, Hashable {
    public let id: String
    public let userId: String
    public let vmId: String
    public let status: ShaydZAVMo_VMStatus
    public let ipAddress: String?
    public let port: Int?
    public let startedAt: Date?
    public let lastActivity: Date?
    public let configuration: VMConfiguration
    public let performance: VMPerformance?
    
    public init(
        id: String = UUID().uuidString,
        userId: String,
        vmId: String,
        status: ShaydZAVMo_VMStatus = .stopped,
        ipAddress: String? = nil,
        port: Int? = nil,
        startedAt: Date? = nil,
        lastActivity: Date? = nil,
        configuration: VMConfiguration,
        performance: VMPerformance? = nil
    ) {
        self.id = id
        self.userId = userId
        self.vmId = vmId
        self.status = status
        self.ipAddress = ipAddress
        self.port = port
        self.startedAt = startedAt
        self.lastActivity = lastActivity
        self.configuration = configuration
        self.performance = performance
    }
    
    public var isConnectable: Bool {
        return status == .running && ipAddress != nil && port != nil
    }
    
    public var connectionURL: URL? {
        guard let ipAddress = ipAddress, let port = port else { return nil }
        return URL(string: "http://\(ipAddress):\(port)")
    }
    
    public var uptimeFormatted: String {
        guard let startedAt = startedAt else { return "Not running" }
        let uptime = Date().timeIntervalSince(startedAt)
        let hours = Int(uptime) / 3600
        let minutes = Int(uptime) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
}

/// VM Configuration
public struct VMConfiguration: Codable, Hashable {
    public let name: String
    public let osType: String
    public let ramMB: Int
    public let storageMB: Int
    public let cpuCores: Int
    public let enableGPU: Bool
    public let networkType: String
    public let autoStart: Bool
    public let settings: [String: String]
    
    public init(
        name: String,
        osType: String = "Android",
        ramMB: Int = 2048,
        storageMB: Int = 8192,
        cpuCores: Int = 2,
        enableGPU: Bool = false,
        networkType: String = "NAT",
        autoStart: Bool = false,
        settings: [String: String] = [:]
    ) {
        self.name = name
        self.osType = osType
        self.ramMB = ramMB
        self.storageMB = storageMB
        self.cpuCores = cpuCores
        self.enableGPU = enableGPU
        self.networkType = networkType
        self.autoStart = autoStart
        self.settings = settings
    }
    
    public var ramFormatted: String {
        return "\(ramMB) MB"
    }
    
    public var storageFormatted: String {
        let gb = Double(storageMB) / 1024.0
        return String(format: "%.1f GB", gb)
    }
}

/// VM Performance metrics
public struct VMPerformance: Codable, Hashable {
    public let cpuUsagePercent: Double
    public let memoryUsagePercent: Double
    public let diskUsagePercent: Double
    public let networkBytesIn: Int64
    public let networkBytesOut: Int64
    public let timestamp: Date
    
    public init(
        cpuUsagePercent: Double = 0.0,
        memoryUsagePercent: Double = 0.0,
        diskUsagePercent: Double = 0.0,
        networkBytesIn: Int64 = 0,
        networkBytesOut: Int64 = 0,
        timestamp: Date = Date()
    ) {
        self.cpuUsagePercent = cpuUsagePercent
        self.memoryUsagePercent = memoryUsagePercent
        self.diskUsagePercent = diskUsagePercent
        self.networkBytesIn = networkBytesIn
        self.networkBytesOut = networkBytesOut
        self.timestamp = timestamp
    }
    
    public var networkTrafficFormatted: String {
        let formatter = ByteCountFormatter()
        let totalBytes = networkBytesIn + networkBytesOut
        return formatter.string(fromByteCount: totalBytes)
    }
}

/// VM Operation types
public enum VMOperation: String, Codable, CaseIterable {
    case start = "start"
    case stop = "stop"
    case pause = "pause"
    case resume = "resume"
    case restart = "restart"
    case reset = "reset"
    case delete = "delete"
    case backup = "backup"
    case restore = "restore"
    case clone = "clone"
}

// Type aliases for backward compatibility
public typealias VMStatus = ShaydZAVMo_VMStatus
public typealias ShaydZ_VMStatus = ShaydZAVMo_VMStatus
public typealias VMSession = ShaydZAVMo_VMSession
public typealias ShaydZ_VMSession = ShaydZAVMo_VMSession
public typealias SupabaseVMSession = ShaydZAVMo_VMSession
public typealias ShaydZUnique_SupabaseVMSession = ShaydZAVMo_VMSession
