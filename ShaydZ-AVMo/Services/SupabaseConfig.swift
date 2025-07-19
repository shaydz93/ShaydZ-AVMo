import Foundation

/// Supabase configuration settings
struct SupabaseConfig {
    /// Your Supabase project URL
    /// Replace with your actual Supabase project URL
    static let supabaseURL = "https://qnzskbfqqzxuikjyzqdp.supabase.co"
    
    /// Your Supabase anon/public key
    /// Replace with your actual Supabase anon key
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFuenNrYmZxcXp4dWlranl6cWRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI5NjAwNTksImV4cCI6MjA2ODUzNjA1OX0.qGZ3Y6nR9CfQWGt1O_qrzxJcYXTgntD8pCmM2gayjBQ"
    
    /// API endpoints
    static var authURL: String {
        return "\(supabaseURL)/auth/v1"
    }
    
    static var restURL: String {
        return "\(supabaseURL)/rest/v1"
    }
    
    static var realtimeURL: String {
        return "\(supabaseURL)/realtime/v1"
    }
    
    /// Headers for API requests
    static var defaultHeaders: [String: String] {
        return [
            "apikey": supabaseAnonKey,
            "Authorization": "Bearer \(supabaseAnonKey)",
            "Content-Type": "application/json",
            "Prefer": "return=minimal"
        ]
    }
    
    /// Headers for authenticated requests
    static func authHeaders(token: String) -> [String: String] {
        var headers = defaultHeaders
        headers["Authorization"] = "Bearer \(token)"
        return headers
    }
}
