import Foundation
import Combine
import SwiftUI

/// ViewModel for AI-powered app recommendations
@MainActor
class AIRecommendationsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var recommendations: [AIRecommendation] = []
    @Published var trendingCategories: [AICategory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedCategory: String?
    @Published var searchText = ""
    
    // MARK: - Private Properties
    private let aiService = AIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        loadRecommendations()
        loadTrendingCategories()
    }
    
    // MARK: - Public Methods
    
    /// Load AI-powered app recommendations
    func loadRecommendations() {
        isLoading = true
        errorMessage = nil
        
        aiService.getRecommendations(limit: 20)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "Failed to load recommendations: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] response in
                    self?.recommendations = response.data.recommendations
                    self?.isLoading = false
                }
            )
            .store(in: &cancellables)
    }
    
    /// Load trending categories
    func loadTrendingCategories() {
        aiService.getTrendingCategories()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("Failed to load trending categories: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] response in
                    self?.trendingCategories = response.data.categories
                }
            )
            .store(in: &cancellables)
    }
    
    /// Record user interaction with an app
    func recordInteraction(with recommendation: AIRecommendation, type: AIInteractionType) {
        let metadata = [
            "category": recommendation.category,
            "score": recommendation.score,
            "source": "ai_recommendations"
        ] as [String: Any]
        
        aiService.recordInteraction(
            appId: recommendation.id,
            type: type,
            metadata: metadata
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Failed to record interaction: \(error.localizedDescription)")
                }
            },
            receiveValue: { _ in
                print("Interaction recorded successfully")
            }
        )
        .store(in: &cancellables)
        
        // Track AI feature usage
        aiService.trackFeatureUsage("app_recommendation_interaction", metadata: metadata)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    /// Filter recommendations by category
    func selectCategory(_ category: String?) {
        selectedCategory = category
    }
    
    /// Clear search and filters
    func clearFilters() {
        selectedCategory = nil
        searchText = ""
    }
    
    /// Get filtered recommendations based on search and category
    var filteredRecommendations: [AIRecommendation] {
        var filtered = recommendations
        
        // Filter by category
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { recommendation in
                recommendation.name.localizedCaseInsensitiveContains(searchText) ||
                recommendation.description.localizedCaseInsensitiveContains(searchText) ||
                recommendation.aiRecommendationReason.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    /// Get recommendations grouped by category
    var recommendationsByCategory: [String: [AIRecommendation]] {
        Dictionary(grouping: filteredRecommendations) { $0.category }
    }
    
    /// Get top recommended apps (highest scores)
    var topRecommendations: [AIRecommendation] {
        Array(recommendations.sorted { $0.score > $1.score }.prefix(5))
    }
    
    /// Install app action
    func installApp(_ recommendation: AIRecommendation) {
        recordInteraction(with: recommendation, type: .install)
        // Here you would integrate with actual app installation logic
        print("Installing app: \(recommendation.name)")
    }
    
    /// View app details action
    func viewAppDetails(_ recommendation: AIRecommendation) {
        recordInteraction(with: recommendation, type: .view)
        // Navigation to app details would be handled by the view
    }
    
    /// Get recommendation reason with enhanced formatting
    func getFormattedReason(for recommendation: AIRecommendation) -> String {
        let baseReason = recommendation.aiRecommendationReason
        let score = Int(recommendation.score * 20) // Convert to percentage-like score
        return "🤖 AI Recommendation: \(baseReason) (Confidence: \(score)%)"
    }
    
    /// Get category icon
    func getCategoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "productivity":
            return "briefcase.fill"
        case "developer tools":
            return "hammer.fill"
        case "communication":
            return "message.fill"
        case "internet":
            return "globe"
        case "entertainment":
            return "play.fill"
        case "business":
            return "building.2.fill"
        case "education":
            return "book.fill"
        case "health":
            return "heart.fill"
        case "finance":
            return "dollarsign.circle.fill"
        case "graphics":
            return "paintbrush.fill"
        default:
            return "app.fill"
        }
    }
    
    /// Get trend icon for category
    func getTrendIcon(for trend: String) -> (icon: String, color: Color) {
        switch trend.lowercased() {
        case "up":
            return ("arrow.up.circle.fill", .green)
        case "down":
            return ("arrow.down.circle.fill", .red)
        case "stable":
            return ("minus.circle.fill", .orange)
        default:
            return ("circle.fill", .gray)
        }
    }
    
    /// Refresh all data
    func refresh() {
        loadRecommendations()
        loadTrendingCategories()
    }
    
    /// Get recommendation quality score
    func getQualityScore(for recommendation: AIRecommendation) -> String {
        let score = recommendation.score
        switch score {
        case 4.5...5.0:
            return "Excellent Match"
        case 4.0..<4.5:
            return "Great Match"
        case 3.5..<4.0:
            return "Good Match"
        case 3.0..<3.5:
            return "Fair Match"
        default:
            return "Potential Match"
        }
    }
    
    /// Get popularity indicator
    func getPopularityIndicator(for recommendation: AIRecommendation) -> String {
        let popularity = recommendation.popularity
        switch popularity {
        case 90...100:
            return "🔥 Trending"
        case 80..<90:
            return "⭐ Popular"
        case 70..<80:
            return "👍 Well-liked"
        case 60..<70:
            return "✨ Rising"
        default:
            return "🆕 New"
        }
    }
}

// MARK: - AI Recommendation Extensions
extension AIRecommendation {
    /// Convert to AppModel for compatibility with existing views
    func toAppModel() -> AppModel {
        AppModel(
            id: self.id,
            name: self.name,
            description: self.description,
            iconName: self.iconName,
            category: self.category,
            version: self.version,
            size: self.size,
            isInstalled: false, // AI recommendations are for new apps
            isRunning: false,
            downloadURL: "",
            packageName: self.id,
            platform: "iOS",
            rating: self.score,
            developer: "AI Recommended",
            screenshots: [],
            releaseNotes: "AI recommended based on your preferences",
            requirements: "iOS 15.0+",
            languages: ["English"],
            contentRating: "4+",
            privacyPolicy: "",
            supportURL: "",
            lastUpdated: Date(),
            fileSize: 0,
            bundleId: self.id
        )
    }
}

// MARK: - Mock Data for Preview
extension AIRecommendationsViewModel {
    static func mock() -> AIRecommendationsViewModel {
        let viewModel = AIRecommendationsViewModel()
        viewModel.recommendations = [
            AIRecommendation(
                id: "mock_1",
                name: "AI Code Assistant",
                category: "Developer Tools",
                description: "Smart coding companion with AI-powered suggestions",
                iconName: "chevron.left.forwardslash.chevron.right",
                version: "2.1.0",
                size: "45MB",
                score: 4.8,
                popularity: 92,
                aiRecommendationReason: "Perfect for developers like you"
            ),
            AIRecommendation(
                id: "mock_2",
                name: "Smart Notes Pro",
                category: "Productivity",
                description: "AI-enhanced note-taking with intelligent organization",
                iconName: "note.text",
                version: "1.5.0",
                size: "28MB",
                score: 4.6,
                popularity: 87,
                aiRecommendationReason: "Matches your productivity workflow"
            )
        ]
        viewModel.trendingCategories = [
            AICategory(name: "Productivity", trend: "up", score: 92),
            AICategory(name: "Developer Tools", trend: "up", score: 88)
        ]
        return viewModel
    }
}