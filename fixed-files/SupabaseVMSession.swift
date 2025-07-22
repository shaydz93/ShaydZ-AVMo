import Foundation

/// Model for a Supabase virtual machine session
struct SupabaseVMSession: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let status: String
    var vmInstanceId: String?
    var appId: String?
    var startedAt: Date?
    var endedAt: Date?
    var ipAddress: String?
    var port: Int?
    var connectionUrl: String?
    var sessionData: [String: String]?
    
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
    
    static func == (lhs: SupabaseVMSession, rhs: SupabaseVMSession) -> Bool {
        return lhs.id == rhs.id
    }
    
    static var mockSession: SupabaseVMSession {
        return SupabaseVMSession(
            id: "mock-session-id",
            userId: "mock-user-id",
            status: "active",
            vmInstanceId: "mock-vm-instance-id",
            appId: "com.example.securemessenger",
            startedAt: Date(),
            endedAt: nil,
            ipAddress: "192.168.1.1",
            port: 8080,
            connectionUrl: "https://vm.shaydz-avmo.io/connect/mock-session-id",
            sessionData: ["resolution": "1920x1080", "quality": "high"]
        )
    }
}
