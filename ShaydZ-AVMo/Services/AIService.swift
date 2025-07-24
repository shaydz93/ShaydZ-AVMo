import Foundation
import Combine

/// Core AI Service for communication with AI backend
@MainActor
class AIService: ObservableObject {
    static let shared = AIService()
    private let networkService = NetworkService.shared
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - App Recommendations
    
    /// Get personalized app recommendations
    func getRecommendations(limit: Int = 10) -> AnyPublisher<AIRecommendationsResponse, APIError> {
        isLoading = true
        errorMessage = nil
        
        let endpoint = "\(APIConfig.baseURL)/ai/recommendations?limit=\(limit)"
        
        return networkService.request<AIRecommendationsResponse>(
            endpoint: endpoint,
            method: "GET",
            requiresAuth: false
        )
        .receive(on: DispatchQueue.main)
        .handleEvents(
            receiveOutput: { _ in self.isLoading = false },
            receiveCompletion: { completion in
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.errorMessage = error.localizedDescription
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    /// Record user interaction with an app for learning
    func recordInteraction(appId: String, type: AIInteractionType, metadata: [String: Any] = [:]) -> AnyPublisher<AIInteractionResponse, APIError> {
        let endpoint = "\(APIConfig.baseURL)/ai/recommendations/interaction"
        let body = AIInteractionRequest(
            appId: appId,
            interactionType: type.rawValue,
            metadata: metadata
        )
        
        return networkService.request<AIInteractionResponse>(
            endpoint: endpoint,
            method: "POST",
            body: try? JSONEncoder().encode(body),
            requiresAuth: false
        )
        .eraseToAnyPublisher()
    }
    
    /// Get trending categories
    func getTrendingCategories() -> AnyPublisher<AICategoriesResponse, APIError> {
        let endpoint = "\(APIConfig.baseURL)/ai/recommendations/categories"
        
        return networkService.request<AICategoriesResponse>(
            endpoint: endpoint,
            method: "GET",
            requiresAuth: false
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - AI Chat
    
    /// Send message to AI assistant
    func sendChatMessage(_ message: String, context: [String: Any] = [:]) -> AnyPublisher<AIChatResponse, APIError> {
        let endpoint = "\(APIConfig.baseURL)/ai/chat/message"
        let body = AIChatRequest(message: message, context: context)
        
        return networkService.request<AIChatResponse>(
            endpoint: endpoint,
            method: "POST",
            body: try? JSONEncoder().encode(body),
            requiresAuth: true
        )
        .eraseToAnyPublisher()
    }
    
    /// Get chat conversation history
    func getChatHistory(limit: Int = 50) -> AnyPublisher<AIChatHistoryResponse, APIError> {
        let endpoint = "\(APIConfig.baseURL)/ai/chat/history?limit=\(limit)"
        
        return networkService.request<AIChatHistoryResponse>(
            endpoint: endpoint,
            method: "GET",
            requiresAuth: true
        )
        .eraseToAnyPublisher()
    }
    
    /// Clear chat history
    func clearChatHistory() -> AnyPublisher<AIGenericResponse, APIError> {
        let endpoint = "\(APIConfig.baseURL)/ai/chat/history"
        
        return networkService.request<AIGenericResponse>(
            endpoint: endpoint,
            method: "DELETE",
            requiresAuth: true
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Analytics
    
    /// Get AI analytics dashboard data
    func getAnalyticsDashboard(timeRange: String = "24h") -> AnyPublisher<AIAnalyticsResponse, APIError> {
        let endpoint = "\(APIConfig.baseURL)/ai/analytics/dashboard?timeRange=\(timeRange)"
        
        return networkService.request<AIAnalyticsResponse>(
            endpoint: endpoint,
            method: "GET",
            requiresAuth: true
        )
        .eraseToAnyPublisher()
    }
    
    /// Get real-time performance metrics
    func getPerformanceMetrics() -> AnyPublisher<AIPerformanceResponse, APIError> {
        let endpoint = "\(APIConfig.baseURL)/ai/analytics/performance"
        
        return networkService.request<AIPerformanceResponse>(
            endpoint: endpoint,
            method: "GET",
            requiresAuth: true
        )
        .eraseToAnyPublisher()
    }
    
    /// Track AI feature usage
    func trackFeatureUsage(_ feature: String, metadata: [String: Any] = [:]) -> AnyPublisher<AIGenericResponse, APIError> {
        let endpoint = "\(APIConfig.baseURL)/ai/analytics/track"
        let body = AIFeatureTrackingRequest(feature: feature, metadata: metadata)
        
        return networkService.request<AIGenericResponse>(
            endpoint: endpoint,
            method: "POST",
            body: try? JSONEncoder().encode(body),
            requiresAuth: true
        )
        .eraseToAnyPublisher()
    }
    
    /// Get AI-generated insights
    func getInsights() -> AnyPublisher<AIInsightsResponse, APIError> {
        let endpoint = "\(APIConfig.baseURL)/ai/analytics/insights"
        
        return networkService.request<AIInsightsResponse>(
            endpoint: endpoint,
            method: "GET",
            requiresAuth: true
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - VM Optimization
    
    /// Analyze VM resources and get optimization recommendations
    func analyzeVMResources() -> AnyPublisher<AIOptimizationAnalysisResponse, APIError> {
        let endpoint = "\(APIConfig.baseURL)/ai/optimization/analyze"
        
        return networkService.request<AIOptimizationAnalysisResponse>(
            endpoint: endpoint,
            method: "GET",
            requiresAuth: true
        )
        .eraseToAnyPublisher()
    }
    
    /// Apply optimization recommendation
    func applyOptimization(type: String, parameters: [String: Any] = [:]) -> AnyPublisher<AIOptimizationResultResponse, APIError> {
        let endpoint = "\(APIConfig.baseURL)/ai/optimization/apply"
        let body = AIOptimizationRequest(type: type, parameters: parameters)
        
        return networkService.request<AIOptimizationResultResponse>(
            endpoint: endpoint,
            method: "POST",
            body: try? JSONEncoder().encode(body),
            requiresAuth: true
        )
        .eraseToAnyPublisher()
    }
    
    /// Get predictive scaling recommendations
    func getPredictiveScaling() -> AnyPublisher<AIPredictiveScalingResponse, APIError> {
        let endpoint = "\(APIConfig.baseURL)/ai/optimization/predictive"
        
        return networkService.request<AIPredictiveScalingResponse>(
            endpoint: endpoint,
            method: "GET",
            requiresAuth: true
        )
        .eraseToAnyPublisher()
    }
    
    /// Get cost optimization analysis
    func getCostOptimization() -> AnyPublisher<AICostOptimizationResponse, APIError> {
        let endpoint = "\(APIConfig.baseURL)/ai/optimization/cost"
        
        return networkService.request<AICostOptimizationResponse>(
            endpoint: endpoint,
            method: "GET",
            requiresAuth: true
        )
        .eraseToAnyPublisher()
    }
}

// MARK: - AI Models

enum AIInteractionType: String, CaseIterable {
    case view = "view"
    case install = "install"
    case launch = "launch"
    case uninstall = "uninstall"
}

// MARK: - Request Models

struct AIInteractionRequest: Codable {
    let appId: String
    let interactionType: String
    let metadata: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case appId, interactionType, metadata
    }
    
    init(appId: String, interactionType: String, metadata: [String: Any]) {
        self.appId = appId
        self.interactionType = interactionType
        self.metadata = metadata
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        appId = try container.decode(String.self, forKey: .appId)
        interactionType = try container.decode(String.self, forKey: .interactionType)
        metadata = (try? container.decode([String: Any].self, forKey: .metadata)) ?? [:]
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(appId, forKey: .appId)
        try container.encode(interactionType, forKey: .interactionType)
        // Note: Encoding [String: Any] requires custom logic or use specific types
    }
}

struct AIChatRequest: Codable {
    let message: String
    let context: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case message, context
    }
    
    init(message: String, context: [String: Any]) {
        self.message = message
        self.context = context
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        message = try container.decode(String.self, forKey: .message)
        context = (try? container.decode([String: Any].self, forKey: .context)) ?? [:]
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(message, forKey: .message)
        // Simplified encoding for context
    }
}

struct AIFeatureTrackingRequest: Codable {
    let feature: String
    let metadata: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case feature, metadata
    }
    
    init(feature: String, metadata: [String: Any]) {
        self.feature = feature
        self.metadata = metadata
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        feature = try container.decode(String.self, forKey: .feature)
        metadata = (try? container.decode([String: Any].self, forKey: .metadata)) ?? [:]
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(feature, forKey: .feature)
    }
}

struct AIOptimizationRequest: Codable {
    let type: String
    let parameters: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case type, parameters
    }
    
    init(type: String, parameters: [String: Any]) {
        self.type = type
        self.parameters = parameters
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        parameters = (try? container.decode([String: Any].self, forKey: .parameters)) ?? [:]
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
    }
}

// MARK: - Response Models

struct AIRecommendationsResponse: Codable {
    let success: Bool
    let data: AIRecommendationsData
}

struct AIRecommendationsData: Codable {
    let recommendations: [AIRecommendation]
    let userId: String
    let count: Int
    let algorithm: String
}

struct AIRecommendation: Codable, Identifiable {
    let id: String
    let name: String
    let category: String
    let description: String
    let iconName: String
    let version: String
    let size: String
    let score: Double
    let popularity: Int
    let aiRecommendationReason: String
}

struct AICategoriesResponse: Codable {
    let success: Bool
    let data: AICategoriesData
}

struct AICategoriesData: Codable {
    let categories: [AICategory]
    let lastUpdated: String
}

struct AICategory: Codable {
    let name: String
    let trend: String
    let score: Int
}

struct AIChatResponse: Codable {
    let success: Bool
    let data: AIChatData
}

struct AIChatData: Codable {
    let response: String
    let intent: String
    let confidence: Double
    let suggestions: [String]
    let actionItems: [AIChatActionItem]
    let timestamp: String
}

struct AIChatActionItem: Codable {
    let type: String
    let label: String
    let action: String
}

struct AIChatHistoryResponse: Codable {
    let success: Bool
    let data: AIChatHistoryData
}

struct AIChatHistoryData: Codable {
    let history: [AIChatMessage]
    let count: Int
}

struct AIChatMessage: Codable {
    let userMessage: String
    let aiResponse: String
    let timestamp: String
}

struct AIAnalyticsResponse: Codable {
    let success: Bool
    let data: AIAnalyticsData
}

struct AIAnalyticsData: Codable {
    let overview: AIAnalyticsOverview
    let performance: AIAnalyticsPerformance
    let insights: [AIAnalyticsInsight]
    let alerts: [AIAnalyticsAlert]
}

struct AIAnalyticsOverview: Codable {
    let totalAppsUsed: Int
    let averageSessionTime: String
    let vmEfficiencyScore: Int
    let lastOptimized: String
}

struct AIAnalyticsPerformance: Codable {
    let cpuTrend: [AIMetricPoint]
    let memoryTrend: [AIMetricPoint]
    let networkTrend: [AIMetricPoint]
}

struct AIMetricPoint: Codable {
    let timestamp: String
    let value: Double
}

struct AIAnalyticsInsight: Codable {
    let type: String
    let title: String
    let message: String
    let impact: String
    let actionable: Bool
}

struct AIAnalyticsAlert: Codable {
    let id: String
    let type: String
    let title: String
    let message: String
    let timestamp: String
    let severity: String
}

struct AIPerformanceResponse: Codable {
    let success: Bool
    let data: AIPerformanceData
}

struct AIPerformanceData: Codable {
    let current: AICurrentMetrics
    let status: String
    let recommendations: [AIPerformanceRecommendation]
}

struct AICurrentMetrics: Codable {
    let cpu_usage: Double
    let memory_usage: Double
    let disk_usage: Double
    let network_latency: Double
    let active_apps: Int
    let vm_uptime: Int
    let timestamp: String
}

struct AIPerformanceRecommendation: Codable {
    let type: String
    let message: String
    let priority: String
}

struct AIInsightsResponse: Codable {
    let success: Bool
    let data: AIInsightsData
}

struct AIInsightsData: Codable {
    let insights: [AIInsight]
    let count: Int
    let lastAnalyzed: String
}

struct AIInsight: Codable, Identifiable {
    let id: String
    let type: String
    let title: String
    let description: String
    let confidence: Double
    let actionable: Bool
    let actions: [AIInsightAction]
    let impact: String
    let category: String
}

struct AIInsightAction: Codable {
    let label: String
    let type: String
    let endpoint: String
}

struct AIOptimizationAnalysisResponse: Codable {
    let success: Bool
    let data: AIOptimizationAnalysis
}

struct AIOptimizationAnalysis: Codable {
    let current: AIResourceStatus
    let optimizations: [AIOptimizationRecommendation]
    let score: Int
    let timestamp: String
}

struct AIResourceStatus: Codable {
    let cpu: AIResourceMetric
    let memory: AIResourceMetric
    let storage: AIResourceMetric
    let network: AINetworkMetric
}

struct AIResourceMetric: Codable {
    let allocated: Int
    let usage: Double
    let efficiency: Double
}

struct AINetworkMetric: Codable {
    let bandwidth: Int
    let usage: Double
    let latency: Double
}

struct AIOptimizationRecommendation: Codable {
    let type: String
    let priority: String
    let title: String
    let description: String
    let currentValue: String
    let recommendedValue: String
    let impact: String
    let estimatedImprovement: String
}

struct AIOptimizationResultResponse: Codable {
    let success: Bool
    let data: AIOptimizationResult
}

struct AIOptimizationResult: Codable {
    let type: String
    let status: String
    let appliedAt: String
    let estimatedCompletionTime: String
    let message: String
}

struct AIPredictiveScalingResponse: Codable {
    let success: Bool
    let data: AIPredictiveScaling
}

struct AIPredictiveScaling: Codable {
    let predictions: AIPredictions
    let recommendations: [AIScalingRecommendation]
    let lastAnalyzed: String
}

struct AIPredictions: Codable {
    let nextHour: AIPredictionData
    let next4Hours: AIPredictionData
    let next24Hours: AIPredictionData
}

struct AIPredictionData: Codable {
    let cpu: Double
    let memory: Double
    let confidence: Double
}

struct AIScalingRecommendation: Codable {
    let timeframe: String
    let type: String
    let resource: String
    let reason: String
    let confidence: Double
}

struct AICostOptimizationResponse: Codable {
    let success: Bool
    let data: AICostOptimization
}

struct AICostOptimization: Codable {
    let current: AICostBreakdown
    let optimized: AICostBreakdown
    let recommendations: [AICostRecommendation]
}

struct AICostBreakdown: Codable {
    let monthly: Double
    let daily: Double
    let breakdown: AICostComponents
    let savings: Double?
}

struct AICostComponents: Codable {
    let cpu: Double
    let memory: Double
    let storage: Double
    let network: Double
}

struct AICostRecommendation: Codable {
    let type: String
    let description: String
    let monthlySavings: Double
    let impact: String
}

struct AIInteractionResponse: Codable {
    let success: Bool
    let message: String
}

struct AIGenericResponse: Codable {
    let success: Bool
    let message: String
}