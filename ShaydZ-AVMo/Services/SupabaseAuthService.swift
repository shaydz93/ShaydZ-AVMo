import Foundation
import Combine

/// Supabase authentication service
class SupabaseAuthService: ObservableObject {
    static let shared = SupabaseAuthService()
    private let networkService = SupabaseNetworkService.shared
    private var cancellables = Set<AnyCancellable>()
    
    /// Current authenticated user
    @Published var currentUser: SupabaseUser?
    @Published var isAuthenticated = false
    @Published var userProfile: SupabaseUserProfile?
    
    private init() {
        // Check for existing authentication on initialization
        checkExistingAuth()
    }
    
    // MARK: - Authentication Methods
    
    /// Sign up with email and password
    func signUp(email: String, password: String, metadata: [String: Any]? = nil) -> AnyPublisher<SupabaseAuthResponse, SupabaseError> {
        let endpoint = "\(SupabaseConfig.authURL)/signup"
        
        var requestBody: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        if let metadata = metadata {
            requestBody["data"] = metadata
        }
        
        guard let body = try? JSONSerialization.data(withJSONObject: requestBody) else {
            return Fail(error: SupabaseError(error: "encoding_error", errorDescription: nil, message: "Failed to encode request"))
                .eraseToAnyPublisher()
        }
        
        return networkService.request(
            endpoint: endpoint,
            method: .POST,
            body: body,
            authenticated: false,
            responseType: SupabaseAuthResponse.self
        )
        .handleEvents(receiveOutput: { [weak self] response in
            self?.handleAuthResponse(response)
        })
        .eraseToAnyPublisher()
    }
    
    /// Sign in with email and password
    func signIn(email: String, password: String) -> AnyPublisher<SupabaseAuthResponse, SupabaseError> {
        let endpoint = "\(SupabaseConfig.authURL)/token?grant_type=password"
        
        let requestBody = [
            "email": email,
            "password": password
        ]
        
        guard let body = try? JSONSerialization.data(withJSONObject: requestBody) else {
            return Fail(error: SupabaseError(error: "encoding_error", errorDescription: nil, message: "Failed to encode request"))
                .eraseToAnyPublisher()
        }
        
        return networkService.request(
            endpoint: endpoint,
            method: .POST,
            body: body,
            authenticated: false,
            responseType: SupabaseAuthResponse.self
        )
        .handleEvents(receiveOutput: { [weak self] response in
            self?.handleAuthResponse(response)
        })
        .eraseToAnyPublisher()
    }
    
    /// Sign out current user
    func signOut() -> AnyPublisher<Void, SupabaseError> {
        let endpoint = "\(SupabaseConfig.authURL)/logout"
        
        return networkService.request(
            endpoint: endpoint,
            method: .POST,
            responseType: EmptyResponse.self
        )
        .handleEvents(receiveOutput: { [weak self] _ in
            self?.handleSignOut()
        })
        .map { _ in () }
        .eraseToAnyPublisher()
    }
    
    /// Refresh current authentication token
    func refreshToken() -> AnyPublisher<SupabaseAuthResponse, SupabaseError> {
        guard let refreshToken = UserDefaults.standard.string(forKey: "supabase_refresh_token") else {
            return Fail(error: SupabaseError(error: "no_refresh_token", errorDescription: nil, message: "No refresh token available"))
                .eraseToAnyPublisher()
        }
        
        let endpoint = "\(SupabaseConfig.authURL)/token?grant_type=refresh_token"
        
        let requestBody = [
            "refresh_token": refreshToken
        ]
        
        guard let body = try? JSONSerialization.data(withJSONObject: requestBody) else {
            return Fail(error: SupabaseError(error: "encoding_error", errorDescription: nil, message: "Failed to encode request"))
                .eraseToAnyPublisher()
        }
        
        return networkService.request(
            endpoint: endpoint,
            method: .POST,
            body: body,
            authenticated: false,
            responseType: SupabaseAuthResponse.self
        )
        .handleEvents(receiveOutput: { [weak self] response in
            self?.handleAuthResponse(response)
        })
        .eraseToAnyPublisher()
    }
    
    /// Reset password
    func resetPassword(email: String) -> AnyPublisher<Void, SupabaseError> {
        let endpoint = "\(SupabaseConfig.authURL)/recover"
        
        let requestBody = [
            "email": email
        ]
        
        guard let body = try? JSONSerialization.data(withJSONObject: requestBody) else {
            return Fail(error: SupabaseError(error: "encoding_error", errorDescription: nil, message: "Failed to encode request"))
                .eraseToAnyPublisher()
        }
        
        return networkService.request(
            endpoint: endpoint,
            method: .POST,
            body: body,
            authenticated: false,
            responseType: EmptyResponse.self
        )
        .map { _ in () }
        .eraseToAnyPublisher()
    }
    
    // MARK: - User Profile Methods
    
    /// Fetch user profile from database
    func fetchUserProfile() -> AnyPublisher<SupabaseUserProfile, SupabaseError> {
        guard let userId = currentUser?.id else {
            return Fail(error: SupabaseError(error: "not_authenticated", errorDescription: nil, message: "User not authenticated"))
                .eraseToAnyPublisher()
        }
        
        return networkService.select(
            from: "user_profiles",
            filter: "id=eq.\(userId)",
            responseType: SupabaseUserProfile.self
        )
        .tryMap { profiles in
            guard let profile = profiles.first else {
                throw SupabaseError(error: "profile_not_found", errorDescription: nil, message: "User profile not found")
            }
            return profile
        }
        .mapError { error in
            if let supabaseError = error as? SupabaseError {
                return supabaseError
            }
            return SupabaseError(error: "unknown_error", errorDescription: nil, message: error.localizedDescription)
        }
        .handleEvents(receiveOutput: { [weak self] profile in
            DispatchQueue.main.async {
                self?.userProfile = profile
            }
        })
        .eraseToAnyPublisher()
    }
    
    /// Update user profile
    func updateUserProfile(_ profile: SupabaseUserProfile) -> AnyPublisher<SupabaseUserProfile, SupabaseError> {
        return networkService.update(
            table: "user_profiles",
            data: profile,
            filter: "id=eq.\(profile.id)"
        )
        .handleEvents(receiveOutput: { [weak self] updatedProfile in
            DispatchQueue.main.async {
                self?.userProfile = updatedProfile
            }
        })
        .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    private func handleAuthResponse(_ response: SupabaseAuthResponse) {
        // Save tokens
        networkService.saveAuthToken(response.accessToken)
        UserDefaults.standard.set(response.refreshToken, forKey: "supabase_refresh_token")
        
        // Update state
        DispatchQueue.main.async { [weak self] in
            self?.currentUser = response.user
            self?.isAuthenticated = true
        }
        
        // Fetch user profile
        fetchUserProfile()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to fetch user profile: \(error.localizedDescription)")
                    }
                },
                receiveValue: { _ in
                    print("User profile fetched successfully")
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleSignOut() {
        networkService.clearAuthToken()
        UserDefaults.standard.removeObject(forKey: "supabase_refresh_token")
        
        DispatchQueue.main.async { [weak self] in
            self?.currentUser = nil
            self?.userProfile = nil
            self?.isAuthenticated = false
        }
    }
    
    private func checkExistingAuth() {
        guard let token = networkService.getAuthToken() else {
            return
        }
        
        // Try to get current user with existing token
        let endpoint = "\(SupabaseConfig.authURL)/user"
        
        networkService.request(
            endpoint: endpoint,
            method: .GET,
            authenticated: true,
            responseType: SupabaseUser.self
        )
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure = completion {
                    // Token is invalid, clear it
                    self?.handleSignOut()
                }
            },
            receiveValue: { [weak self] user in
                DispatchQueue.main.async {
                    self?.currentUser = user
                    self?.isAuthenticated = true
                }
                
                // Fetch user profile
                self?.fetchUserProfile()
                    .sink(
                        receiveCompletion: { _ in },
                        receiveValue: { _ in }
                    )
                    .store(in: &self?.cancellables ?? Set<AnyCancellable>())
            }
        )
        .store(in: &cancellables)
    }
}
