import Foundation

/// Model for a Supabase virtual machine session with unique namespace
public struct ShaydZ_SupabaseVMSession: Identifiable, Codable, Equatable {
    public let id: String
    public let userId: String
    public let status: String
    public var vmInstanceId: String?
    public var appId: String?
    public var startedAt: Date?
    public var endedAt: Date?
    public var ipAddress: String?
    public var port: Int?
    public var connectionUrl: String?
    public var sessionData: [String: String]?
    
    public init(
        id: String,
        userId: String,
        status: String,
        vmInstanceId: String? = nil,
        appId: String? = nil,
        startedAt: Date? = nil,
        endedAt: Date? = nil,
        ipAddress: String? = nil,
        port: Int? = nil,
        connectionUrl: String? = nil,
        sessionData: [String: String]? = nil
    ) {
        self.id = id
        self.userId = userId
        self.status = status
        self.vmInstanceId = vmInstanceId
        self.appId = appId
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.ipAddress = ipAddress
        self.port = port
        self.connectionUrl = connectionUrl
        self.sessionData = sessionData
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case status
        case vmInstanceId = "vm_instance_id"
        case appId = "app_id"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case ipAddress = "ip_address"
        case port
        case connectionUrl = "connection_url"
        case sessionData = "session_data"
    }
    
    public static func == (lhs: ShaydZ_SupabaseVMSession, rhs: ShaydZ_SupabaseVMSession) -> Bool {
        return lhs.id == rhs.id
    }
    
    public static var mockSession: ShaydZ_SupabaseVMSession {
        return ShaydZ_SupabaseVMSession(
            id: "mock-session-id",
            userId: "mock-user-id",
            status: "active",
            vmInstanceId: "mock-vm-instance-id",
            appId: "mock-app-id",
            startedAt: Date(),
            ipAddress: "192.168.1.100",
            port: 8080,
            connectionUrl: "wss://192.168.1.100:8080/vm/connect"
        )
    }
}

// Only provide type alias if it doesn't already exist
#if !SUPABASEVMSESSION_TYPEALIAS_DEFINED
#define SUPABASEVMSESSION_TYPEALIAS_DEFINED
public typealias SupabaseVMSession = ShaydZ_SupabaseVMSession
#endif
