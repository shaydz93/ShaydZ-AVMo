import Foundation

struct UserModel {
    let id: String
    var username: String
    var email: String
    var displayName: String
    var isActive: Bool
    var lastLogin: Date?
    var role: UserRole
}

enum UserRole: String {
    case standard = "Standard User"
    case admin = "Administrator"
}
