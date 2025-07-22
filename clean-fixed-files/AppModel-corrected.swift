import Foundation

/// Model representing an application in the catalog
public struct AppModel: Identifiable, Codable, Equatable {
    public let id: String
    public let name: String
    public let description: String
    public let developer: String?
    public let version: String?
    public let iconURL: String?
    public let iconName: String? // For SF Symbols or local icons
    public let categories: [String]
    public let size: Int? // In bytes
    public let lastUpdated: Date?
    public let rating: Double?
    public let downloadCount: Int?
    public let isVerified: Bool
    public let permissions: [String]
    public let screenshots: [String]
    public let requiredAndroidVersion: String?
    
    // Additional properties needed by the services
    public var isInstalled: Bool
    public var isFeatured: Bool
    public var lastUsed: Date?
    
    public init(
        id: String,
        name: String,
        description: String,
        developer: String? = nil,
        version: String? = nil,
        iconURL: String? = nil,
        iconName: String? = nil,
        categories: [String] = [],
        size: Int? = nil,
        lastUpdated: Date? = nil,
        rating: Double? = nil,
        downloadCount: Int? = nil,
        isVerified: Bool = false,
        permissions: [String] = [],
        screenshots: [String] = [],
        requiredAndroidVersion: String? = nil,
        isInstalled: Bool = false,
        isFeatured: Bool = false,
        lastUsed: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.developer = developer
        self.version = version
        self.iconURL = iconURL
        self.iconName = iconName
        self.categories = categories
        self.size = size
        self.lastUpdated = lastUpdated
        self.rating = rating
        self.downloadCount = downloadCount
        self.isVerified = isVerified
        self.permissions = permissions
        self.screenshots = screenshots
        self.requiredAndroidVersion = requiredAndroidVersion
        self.isInstalled = isInstalled
        self.isFeatured = isFeatured
        self.lastUsed = lastUsed
    }
    
    // Format the app size in a readable format
    public var formattedSize: String {
        guard let size = size else { return "Unknown" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
    
    // Format the last updated date
    public var formattedLastUpdated: String {
        guard let lastUpdated = lastUpdated else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: lastUpdated)
    }
    
    public static func == (lhs: AppModel, rhs: AppModel) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Mock Data
extension AppModel {
    public static var mockApps: [AppModel] = [
        AppModel(
            id: "1",
            name: "Browser",
            description: "Secure browser with privacy features",
            developer: "ShaydZ Corp",
            version: "2.5.1",
            iconURL: "browser_icon",
            iconName: "safari",
            categories: ["Utilities", "Security"],
            size: 45_000_000,
            lastUpdated: Date().addingTimeInterval(-7_776_000), // 90 days ago
            rating: 4.7,
            downloadCount: 5_000_000,
            isVerified: true,
            permissions: ["Internet", "Storage"],
            screenshots: ["browser_1", "browser_2"],
            requiredAndroidVersion: "8.0",
            isInstalled: true,
            isFeatured: true,
            lastUsed: Date().addingTimeInterval(-1800) // 30 minutes ago
        ),
        AppModel(
            id: "2",
            name: "Notes",
            description: "Simple note taking app",
            developer: "ShaydZ Corp",
            version: "3.1.0",
            iconURL: "notes_icon",
            iconName: "note.text",
            categories: ["Productivity"],
            size: 28_000_000,
            lastUpdated: Date().addingTimeInterval(-2_592_000), // 30 days ago
            rating: 4.5,
            downloadCount: 2_000_000,
            isVerified: true,
            permissions: ["Storage"],
            screenshots: ["notes_1", "notes_2"],
            requiredAndroidVersion: "7.0",
            isInstalled: true,
            isFeatured: false,
            lastUsed: Date().addingTimeInterval(-86400) // 1 day ago
        ),
        AppModel(
            id: "3",
            name: "Calculator",
            description: "Scientific calculator",
            developer: "ShaydZ Corp",
            version: "5.2.3",
            iconURL: "calculator_icon",
            iconName: "function",
            categories: ["Utilities"],
            size: 15_000_000,
            lastUpdated: Date().addingTimeInterval(-864_000), // 10 days ago
            rating: 4.8,
            downloadCount: 10_000_000,
            isVerified: true,
            permissions: [],
            screenshots: ["calculator_1"],
            requiredAndroidVersion: "6.0",
            isInstalled: true,
            isFeatured: false,
            lastUsed: nil
        ),
        AppModel(
            id: "4",
            name: "Calendar",
            description: "Schedule management",
            developer: "ShaydZ Corp",
            version: "1.5.0",
            iconURL: "calendar_icon",
            iconName: "calendar",
            categories: ["Productivity"],
            size: 32_000_000,
            lastUpdated: Date().addingTimeInterval(-432_000), // 5 days ago
            rating: 4.3,
            downloadCount: 3_000_000,
            isVerified: true,
            permissions: ["Calendar", "Notifications"],
            screenshots: ["calendar_1", "calendar_2"],
            requiredAndroidVersion: "7.0",
            isInstalled: false,
            isFeatured: true,
            lastUsed: nil
        ),
        AppModel(
            id: "5",
            name: "Email Client",
            description: "Secure email access",
            developer: "ShaydZ Corp",
            version: "4.1.2",
            iconURL: "email_icon",
            iconName: "envelope",
            categories: ["Communication", "Security"],
            size: 42_000_000,
            lastUpdated: Date().addingTimeInterval(-172_800), // 2 days ago
            rating: 4.6,
            downloadCount: 7_500_000,
            isVerified: true,
            permissions: ["Internet", "Contacts", "Storage"],
            screenshots: ["email_1", "email_2", "email_3"],
            requiredAndroidVersion: "8.0",
            isInstalled: false,
            isFeatured: true,
            lastUsed: nil
        )
    ]
}
