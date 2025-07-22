//
//  AppModel.swift
//  ShaydZ-AVMo
//
//  Created by ShaydZ AVMo
//

import Foundation

/// Model representing an application in the catalog
struct AppModel: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let developer: String
    let version: String
    let iconURL: String
    let categories: [String]
    let size: Int // In bytes
    let lastUpdated: Date
    let rating: Double
    let downloadCount: Int
    let isVerified: Bool
    let permissions: [String]
    let screenshots: [String]
    let requiredAndroidVersion: String
    
    // Format the app size in a readable format
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
    
    // Format the last updated date
    var formattedLastUpdated: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: lastUpdated)
    }
    
    static func == (lhs: AppModel, rhs: AppModel) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Mock Data
extension AppModel {
    static var mockApps: [AppModel] = [
        AppModel(
            id: "com.example.securemessenger",
            name: "Secure Messenger",
            description: "End-to-end encrypted messaging app for secure communications.",
            developer: "SecureCom Inc",
            version: "2.5.1",
            iconURL: "secure_messenger_icon",
            categories: ["Communication", "Security"],
            size: 45_000_000,
            lastUpdated: Date().addingTimeInterval(-7_776_000), // 90 days ago
            rating: 4.7,
            downloadCount: 5_000_000,
            isVerified: true,
            permissions: ["Camera", "Microphone", "Contacts"],
            screenshots: ["secure_messenger_1", "secure_messenger_2", "secure_messenger_3"],
            requiredAndroidVersion: "8.0"
        ),
        AppModel(
            id: "com.example.encryptedvault",
            name: "Encrypted Vault",
            description: "Secure storage for sensitive documents and information.",
            developer: "DataSafe Corp",
            version: "3.1.0",
            iconURL: "encrypted_vault_icon",
            categories: ["Productivity", "Security"],
            size: 28_000_000,
            lastUpdated: Date().addingTimeInterval(-2_592_000), // 30 days ago
            rating: 4.5,
            downloadCount: 2_000_000,
            isVerified: true,
            permissions: ["Storage"],
            screenshots: ["encrypted_vault_1", "encrypted_vault_2"],
            requiredAndroidVersion: "7.0"
        ),
        AppModel(
            id: "com.example.securebrowser",
            name: "Secure Browser",
            description: "Privacy-focused web browser with built-in tracking protection.",
            developer: "PrivacyGuard Tech",
            version: "5.2.3",
            iconURL: "secure_browser_icon",
            categories: ["Utilities", "Security"],
            size: 55_000_000,
            lastUpdated: Date().addingTimeInterval(-864_000), // 10 days ago
            rating: 4.8,
            downloadCount: 10_000_000,
            isVerified: true,
            permissions: ["Storage", "Location"],
            screenshots: ["secure_browser_1", "secure_browser_2", "secure_browser_3", "secure_browser_4"],
            requiredAndroidVersion: "6.0"
        )
    ]
}
