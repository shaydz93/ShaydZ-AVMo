import Foundation
import Combine
import SwiftUI

/// Service for AI analytics and performance monitoring
@MainActor
class AIAnalyticsService: ObservableObject {
    static let shared = AIAnalyticsService()
    
    // MARK: - Published Properties
    @Published var dashboardData: AIAnalyticsData?
    @Published var performanceMetrics: AIPerformanceData?
    @Published var insights: [AIInsight] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let aiService = AIService.shared
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    private init() {
        setupPeriodicRefresh()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Load analytics dashboard data
    func loadDashboard(timeRange: String = "24h") {
        isLoading = true
        errorMessage = nil
        
        aiService.getAnalyticsDashboard(timeRange: timeRange)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "Failed to load dashboard: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] response in
                    self?.dashboardData = response.data
                    self?.isLoading = false
                }
            )
            .store(in: &cancellables)
    }
    
    /// Load real-time performance metrics
    func loadPerformanceMetrics() {
        aiService.getPerformanceMetrics()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("Failed to load performance metrics: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] response in
                    self?.performanceMetrics = response.data
                }
            )
            .store(in: &cancellables)
    }
    
    /// Load AI-generated insights
    func loadInsights() {
        aiService.getInsights()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("Failed to load insights: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] response in
                    self?.insights = response.data.insights
                }
            )
            .store(in: &cancellables)
    }
    
    /// Track AI feature usage
    func trackFeature(_ feature: String, metadata: [String: Any] = [:]) {
        aiService.trackFeatureUsage(feature, metadata: metadata)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to track feature usage: \(error.localizedDescription)")
                    }
                },
                receiveValue: { _ in
                    print("Feature usage tracked: \(feature)")
                }
            )
            .store(in: &cancellables)
    }
    
    /// Refresh all analytics data
    func refreshAll() {
        loadDashboard()
        loadPerformanceMetrics()
        loadInsights()
    }
    
    /// Get system health status
    var systemHealthStatus: SystemHealthStatus {
        guard let metrics = performanceMetrics?.current else {
            return .unknown
        }
        
        let cpuHealth = metrics.cpu_usage < 80 ? 1 : 0
        let memoryHealth = metrics.memory_usage < 85 ? 1 : 0
        let diskHealth = metrics.disk_usage < 90 ? 1 : 0
        let networkHealth = metrics.network_latency < 100 ? 1 : 0
        
        let healthScore = (cpuHealth + memoryHealth + diskHealth + networkHealth) / 4.0
        
        switch healthScore {
        case 1.0:
            return .excellent
        case 0.75..<1.0:
            return .good
        case 0.5..<0.75:
            return .fair
        case 0.25..<0.5:
            return .poor
        default:
            return .critical
        }
    }
    
    /// Get efficiency score
    var efficiencyScore: Int {
        return dashboardData?.overview.vmEfficiencyScore ?? 0
    }
    
    /// Get performance trends
    var performanceTrends: PerformanceTrends {
        guard let performance = dashboardData?.performance else {
            return PerformanceTrends()
        }
        
        return PerformanceTrends(
            cpuTrend: calculateTrend(performance.cpuTrend),
            memoryTrend: calculateTrend(performance.memoryTrend),
            networkTrend: calculateTrend(performance.networkTrend)
        )
    }
    
    /// Get actionable insights count
    var actionableInsightsCount: Int {
        return insights.filter { $0.actionable }.count
    }
    
    /// Get critical alerts count
    var criticalAlertsCount: Int {
        return dashboardData?.alerts.filter { $0.severity == "high" || $0.severity == "critical" }.count ?? 0
    }
    
    // MARK: - Private Methods
    
    private func setupPeriodicRefresh() {
        // Refresh metrics every 30 seconds
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.loadPerformanceMetrics()
            }
        }
    }
    
    private func calculateTrend(_ dataPoints: [AIMetricPoint]) -> TrendDirection {
        guard dataPoints.count >= 2 else { return .stable }
        
        let recent = Array(dataPoints.suffix(5))
        let first = recent.first?.value ?? 0
        let last = recent.last?.value ?? 0
        
        let change = (last - first) / first
        
        if change > 0.1 {
            return .increasing
        } else if change < -0.1 {
            return .decreasing
        } else {
            return .stable
        }
    }
}

// MARK: - Supporting Types

enum SystemHealthStatus {
    case excellent
    case good
    case fair
    case poor
    case critical
    case unknown
    
    var color: Color {
        switch self {
        case .excellent:
            return .green
        case .good:
            return .blue
        case .fair:
            return .orange
        case .poor:
            return .red
        case .critical:
            return .red
        case .unknown:
            return .gray
        }
    }
    
    var description: String {
        switch self {
        case .excellent:
            return "Excellent"
        case .good:
            return "Good"
        case .fair:
            return "Fair"
        case .poor:
            return "Poor"
        case .critical:
            return "Critical"
        case .unknown:
            return "Unknown"
        }
    }
    
    var icon: String {
        switch self {
        case .excellent:
            return "checkmark.circle.fill"
        case .good:
            return "checkmark.circle"
        case .fair:
            return "exclamationmark.triangle"
        case .poor:
            return "xmark.circle"
        case .critical:
            return "exclamationmark.octagon.fill"
        case .unknown:
            return "questionmark.circle"
        }
    }
}

enum TrendDirection {
    case increasing
    case decreasing
    case stable
    
    var icon: String {
        switch self {
        case .increasing:
            return "arrow.up.right"
        case .decreasing:
            return "arrow.down.right"
        case .stable:
            return "arrow.right"
        }
    }
    
    var color: Color {
        switch self {
        case .increasing:
            return .green
        case .decreasing:
            return .red
        case .stable:
            return .blue
        }
    }
}

struct PerformanceTrends {
    let cpuTrend: TrendDirection
    let memoryTrend: TrendDirection
    let networkTrend: TrendDirection
    
    init(
        cpuTrend: TrendDirection = .stable,
        memoryTrend: TrendDirection = .stable,
        networkTrend: TrendDirection = .stable
    ) {
        self.cpuTrend = cpuTrend
        self.memoryTrend = memoryTrend
        self.networkTrend = networkTrend
    }
}

// MARK: - Analytics Extensions
extension AIAnalyticsService {
    /// Get formatted uptime string
    func getFormattedUptime() -> String {
        guard let uptime = performanceMetrics?.current.vm_uptime else {
            return "Unknown"
        }
        
        let hours = uptime / 3600
        let minutes = (uptime % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Get performance score out of 100
    func getPerformanceScore() -> Int {
        guard let metrics = performanceMetrics?.current else { return 0 }
        
        let cpuScore = max(0, 100 - Int(metrics.cpu_usage))
        let memoryScore = max(0, 100 - Int(metrics.memory_usage))
        let diskScore = max(0, 100 - Int(metrics.disk_usage))
        let networkScore = min(100, max(0, 100 - Int(metrics.network_latency)))
        
        return (cpuScore + memoryScore + diskScore + networkScore) / 4
    }
    
    /// Get resource utilization summary
    func getResourceSummary() -> ResourceSummary {
        guard let metrics = performanceMetrics?.current else {
            return ResourceSummary()
        }
        
        return ResourceSummary(
            cpu: ResourceUsage(current: metrics.cpu_usage, status: getUsageStatus(metrics.cpu_usage, warning: 70, critical: 85)),
            memory: ResourceUsage(current: metrics.memory_usage, status: getUsageStatus(metrics.memory_usage, warning: 75, critical: 90)),
            disk: ResourceUsage(current: metrics.disk_usage, status: getUsageStatus(metrics.disk_usage, warning: 80, critical: 95)),
            network: ResourceUsage(current: metrics.network_latency, status: getLatencyStatus(metrics.network_latency))
        )
    }
    
    private func getUsageStatus(_ usage: Double, warning: Double, critical: Double) -> ResourceStatus {
        if usage >= critical {
            return .critical
        } else if usage >= warning {
            return .warning
        } else {
            return .normal
        }
    }
    
    private func getLatencyStatus(_ latency: Double) -> ResourceStatus {
        if latency >= 200 {
            return .critical
        } else if latency >= 100 {
            return .warning
        } else {
            return .normal
        }
    }
}

struct ResourceSummary {
    let cpu: ResourceUsage
    let memory: ResourceUsage
    let disk: ResourceUsage
    let network: ResourceUsage
    
    init(
        cpu: ResourceUsage = ResourceUsage(),
        memory: ResourceUsage = ResourceUsage(),
        disk: ResourceUsage = ResourceUsage(),
        network: ResourceUsage = ResourceUsage()
    ) {
        self.cpu = cpu
        self.memory = memory
        self.disk = disk
        self.network = network
    }
}

struct ResourceUsage {
    let current: Double
    let status: ResourceStatus
    
    init(current: Double = 0, status: ResourceStatus = .normal) {
        self.current = current
        self.status = status
    }
}

enum ResourceStatus {
    case normal
    case warning
    case critical
    
    var color: Color {
        switch self {
        case .normal:
            return .green
        case .warning:
            return .orange
        case .critical:
            return .red
        }
    }
}

// MARK: - Mock Data for Preview
extension AIAnalyticsService {
    static func mock() -> AIAnalyticsService {
        let service = AIAnalyticsService()
        
        // Mock dashboard data
        service.dashboardData = AIAnalyticsData(
            overview: AIAnalyticsOverview(
                totalAppsUsed: 23,
                averageSessionTime: "2h 45m",
                vmEfficiencyScore: 87,
                lastOptimized: "2 hours ago"
            ),
            performance: AIAnalyticsPerformance(
                cpuTrend: [
                    AIMetricPoint(timestamp: "2024-01-01T10:00:00Z", value: 45.2),
                    AIMetricPoint(timestamp: "2024-01-01T11:00:00Z", value: 52.1),
                    AIMetricPoint(timestamp: "2024-01-01T12:00:00Z", value: 38.7)
                ],
                memoryTrend: [
                    AIMetricPoint(timestamp: "2024-01-01T10:00:00Z", value: 67.3),
                    AIMetricPoint(timestamp: "2024-01-01T11:00:00Z", value: 72.8),
                    AIMetricPoint(timestamp: "2024-01-01T12:00:00Z", value: 65.2)
                ],
                networkTrend: [
                    AIMetricPoint(timestamp: "2024-01-01T10:00:00Z", value: 25.1),
                    AIMetricPoint(timestamp: "2024-01-01T11:00:00Z", value: 18.9),
                    AIMetricPoint(timestamp: "2024-01-01T12:00:00Z", value: 22.3)
                ]
            ),
            insights: [
                AIAnalyticsInsight(
                    type: "optimization",
                    title: "Resource Optimization Available",
                    message: "Your VM could benefit from additional memory",
                    impact: "medium",
                    actionable: true
                )
            ],
            alerts: [
                AIAnalyticsAlert(
                    id: "alert1",
                    type: "info",
                    title: "System Running Smoothly",
                    message: "All systems operational",
                    timestamp: "2024-01-01T12:00:00Z",
                    severity: "info"
                )
            ]
        )
        
        // Mock performance metrics
        service.performanceMetrics = AIPerformanceData(
            current: AICurrentMetrics(
                cpu_usage: 45.2,
                memory_usage: 67.8,
                disk_usage: 34.5,
                network_latency: 18.3,
                active_apps: 8,
                vm_uptime: 7234,
                timestamp: "2024-01-01T12:00:00Z"
            ),
            status: "healthy",
            recommendations: [
                AIPerformanceRecommendation(
                    type: "memory",
                    message: "Memory usage is optimal",
                    priority: "info"
                )
            ]
        )
        
        return service
    }
}