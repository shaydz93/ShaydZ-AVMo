import Foundation
import Network
import Combine

// Models for network scanning
struct NetworkDevice: Identifiable, Equatable {
    let id = UUID()
    let ipAddress: String
    let macAddress: String?
    let hostName: String?
    let services: [ServiceInfo]
    let isVulnerable: Bool
    
    struct ServiceInfo: Identifiable, Equatable {
        let id = UUID()
        let port: Int
        let serviceName: String
        let version: String?
        let isVulnerable: Bool
        
        static func == (lhs: ServiceInfo, rhs: ServiceInfo) -> Bool {
            return lhs.port == rhs.port && lhs.serviceName == rhs.serviceName
        }
    }
    
    static func == (lhs: NetworkDevice, rhs: NetworkDevice) -> Bool {
        return lhs.id == rhs.id || lhs.ipAddress == rhs.ipAddress
    }
}

struct OpenPort: Identifiable, Equatable {
    let id = UUID()
    let port: Int
    let serviceName: String?
    let banner: String?
    var isVulnerable: Bool = false
    
    static func == (lhs: OpenPort, rhs: OpenPort) -> Bool {
        return lhs.id == rhs.id || (lhs.port == rhs.port && lhs.serviceName == rhs.serviceName)
    }
}

struct PacketData {
    let timestamp: Date
    let sourceIP: String
    let destinationIP: String
    let protocol: NetworkProtocol
    let size: Int
    let data: Data
    
    enum NetworkProtocol {
        case tcp
        case udp
        case icmp
        case other(String)
    }
}

struct TrafficAnalysis {
    let topTalkers: [(ipAddress: String, bytesSent: Int, bytesReceived: Int)]
    let protocolDistribution: [String: Double] // protocol name: percentage
    let activeConnections: Int
}

// Models for vulnerability scanning
struct Vulnerability: Identifiable {
    let id = UUID()
    let type: VulnerabilityType
    let severity: Severity
    let description: String
    let affectedComponent: String
    let remediationSteps: String
    
    enum VulnerabilityType {
        case sqlInjection
        case xss
        case csrf
        case insecureHeaders
        case outdatedSoftware
        case defaultCredentials
        case other(String)
    }
    
    enum Severity {
        case low
        case medium
        case high
        case critical
    }
}

struct ServiceVulnerability {
    let service: String
    let version: String?
    let vulnerabilities: [Vulnerability]
}

// Models for wireless analysis
struct WiFiNetwork: Identifiable {
    let id = UUID()
    let ssid: String
    let bssid: String
    let signalStrength: Int // in dBm
    let channel: Int
    let securityType: SecurityType
    let supportedStandards: [WiFiStandard]
    
    enum SecurityType {
        case open
        case wep
        case wpa
        case wpa2
        case wpa3
        case enterprise
        case unknown
    }
    
    enum WiFiStandard {
        case a
        case b
        case g
        case n
        case ac
        case ax
    }
}

struct SecurityAnalysis {
    let vulnerabilities: [String]
    let securityScore: Int // 0-100
    let recommendations: [String]
}

// Models for password tools
struct PasswordStrength {
    let score: Int // 0-100
    let timeToBreak: String
    let weaknesses: [String]
    let suggestions: [String]
}

enum HashAlgorithm {
    case md5
    case sha1
    case sha256
    case sha512
    case bcrypt
    case argon2
}

struct EncryptedData {
    let data: Data
    let iv: Data
    let algorithm: String
}

// Models for social engineering simulation
struct PhishingCampaign {
    let template: String
    let targetProfile: String
    let successLikelihood: Double // 0.0 to 1.0
    let indicators: [String]
}

struct PhishingIndicators {
    let suspiciousElements: [SuspiciousElement]
    let riskScore: Int // 0-100
    let recommendation: String
    
    struct SuspiciousElement {
        let type: ElementType
        let description: String
        let location: String
        
        enum ElementType {
            case spoofedSender
            case maliciousLink
            case grammaticalErrors
            case urgencyTactics
            case attachments
            case inconsistentDomains
            case other(String)
        }
    }
}
