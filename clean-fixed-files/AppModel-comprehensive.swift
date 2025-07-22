import Foundation

/// Comprehensive app model for ShaydZ AVMo
public struct ShaydZAVMo_AppModel: Identifiable, Codable, Hashable {
    public let id: UUID
    public let name: String
    public let description: String
    public let iconName: String
    public let version: String
    public let category: String
    public let size: Int64
    public let isInstalled: Bool
    public let isCompatible: Bool
    public let requiresPermissions: [String]
    public let metadata: AppMetadata?
    public let createdAt: Date?
    public let updatedAt: Date?
    
    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        iconName: String = "app.badge",
        version: String = "1.0.0",
        category: String = "General",
        size: Int64 = 0,
        isInstalled: Bool = false,
        isCompatible: Bool = true,
        requiresPermissions: [String] = [],
        metadata: AppMetadata? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.iconName = iconName
        self.version = version
        self.category = category
        self.size = size
        self.isInstalled = isInstalled
        self.isCompatible = isCompatible
        self.requiresPermissions = requiresPermissions
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public var sizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    public var canInstall: Bool {
        return !isInstalled && isCompatible
    }
    
    public var canLaunch: Bool {
        return isInstalled && isCompatible
    }
}

/// App metadata structure
public struct AppMetadata: Codable, Hashable {
    public let developer: String?
    public let website: String?
    public let supportEmail: String?
    public let minimumRAM: Int?
    public let minimumStorage: Int?
    public let tags: [String]
    public let screenshots: [String]
    public let rating: Double?
    public let downloadCount: Int?
    
    public init(
        developer: String? = nil,
        website: String? = nil,
        supportEmail: String? = nil,
        minimumRAM: Int? = nil,
        minimumStorage: Int? = nil,
        tags: [String] = [],
        screenshots: [String] = [],
        rating: Double? = nil,
        downloadCount: Int? = nil
    ) {
        self.developer = developer
        self.website = website
        self.supportEmail = supportEmail
        self.minimumRAM = minimumRAM
        self.minimumStorage = minimumStorage
        self.tags = tags
        self.screenshots = screenshots
        self.rating = rating
        self.downloadCount = downloadCount
    }
}

/// App installation status
public enum AppInstallationStatus: String, Codable, CaseIterable {
    case notInstalled = "not_installed"
    case downloading = "downloading"
    case installing = "installing"
    case installed = "installed"
    case updating = "updating"
    case failed = "failed"
    case uninstalling = "uninstalling"
}

/// App launch status
public enum AppLaunchStatus: String, Codable, CaseIterable {
    case notLaunched = "not_launched"
    case launching = "launching"
    case running = "running"
    case suspended = "suspended"
    case crashed = "crashed"
    case terminated = "terminated"
}

// Type aliases for backward compatibility
public typealias AppModel = ShaydZAVMo_AppModel
public typealias ShaydZ_AppModel = ShaydZAVMo_AppModel
