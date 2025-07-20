import Foundation

/// Centralized app category management
struct AppCategoryManager {
    static let shared = AppCategoryManager()
    
    private let categoryFilters: [String: (AppModel) -> Bool] = [
        "Enterprise": { $0.isEnterpriseApp },
        "Human Resources": { $0.name.contains("HR") },
        "Finance": { 
            $0.name.contains("Expense") || 
            $0.name.contains("Analytics") ||
            $0.name.contains("CRM")
        }
    ]
    
    private init() {}
    
    /// Filter apps by category
    func filterApps(_ apps: [AppModel], by category: String?) -> [AppModel] {
        guard let category = category, 
              !category.isEmpty, 
              category != "All",
              let filter = categoryFilters[category] else {
            return apps
        }
        
        return apps.filter(filter)
    }
    
    /// Search apps with query and category filters
    func searchApps(_ apps: [AppModel], query: String?, category: String?) -> [AppModel] {
        var filteredApps = apps
        
        // Apply text search filter
        if let query = query, !query.isEmpty {
            filteredApps = filteredApps.filter { app in
                app.name.localizedCaseInsensitiveContains(query) ||
                app.description.localizedCaseInsensitiveContains(query) ||
                app.packageName.localizedCaseInsensitiveContains(query)
            }
        }
        
        // Apply category filter
        return filterApps(filteredApps, by: category)
    }
}

/// Optimized icon name mapping using lookup dictionary
struct AppIconMapper {
    static let shared = AppIconMapper()
    
    private let iconMappings: [String: String] = [
        // Security
        "secure": "shield.fill",
        "security": "shield.fill",
        
        // Communication
        "communication": "message.fill",
        "chat": "message.fill",
        "message": "message.fill",
        
        // Finance
        "finance": "creditcard.fill",
        "banking": "creditcard.fill",
        "money": "creditcard.fill",
        
        // Development
        "development": "hammer.fill",
        "code": "hammer.fill",
        "developer": "hammer.fill",
        
        // Productivity
        "productivity": "doc.text.fill",
        "office": "doc.text.fill",
        
        // Media
        "media": "play.rectangle.fill",
        "video": "play.rectangle.fill",
        "photo": "play.rectangle.fill",
        
        // Games
        "game": "gamecontroller.fill",
        
        // Social
        "social": "person.2.fill",
        
        // Travel
        "travel": "airplane",
        
        // Health
        "health": "heart.fill",
        "fitness": "heart.fill",
        
        // Education
        "education": "book.fill",
        "learning": "book.fill",
        
        // News
        "news": "newspaper.fill",
        
        // Weather
        "weather": "cloud.sun.fill",
        
        // Music
        "music": "music.note",
        "audio": "music.note",
        
        // Shopping
        "shopping": "bag.fill",
        "store": "bag.fill"
    ]
    
    private init() {}
    
    /// Get SF Symbol icon name from package name
    func iconName(for packageName: String) -> String {
        let lowercaseName = packageName.lowercased()
        
        // Find first matching keyword
        for (keyword, iconName) in iconMappings {
            if lowercaseName.contains(keyword) {
                return iconName
            }
        }
        
        return "app.fill" // Default icon
    }
}
