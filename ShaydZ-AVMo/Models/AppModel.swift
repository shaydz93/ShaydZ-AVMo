import Foundation

struct AppModel: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let iconName: String
    let category: String
    let version: String
    let size: String
    let isInstalled: Bool
    let isRunning: Bool
    
    init(id: UUID = UUID(), name: String, description: String, iconName: String, category: String = "Productivity", version: String = "1.0.0", size: String = "25 MB", isInstalled: Bool = false, isRunning: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.iconName = iconName
        self.category = category
        self.version = version
        self.size = size
        self.isInstalled = isInstalled
        self.isRunning = isRunning
    }
}
