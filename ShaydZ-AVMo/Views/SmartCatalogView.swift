import SwiftUI

/// Smart Catalog View with AI-powered features
struct SmartCatalogView: View {
    @StateObject private var aiRecommendationsViewModel = AIRecommendationsViewModel()
    @StateObject private var aiAnalyticsService = AIAnalyticsService.shared
    @State private var selectedApp: AppModel?
    @State private var showingAppDetail = false
    @State private var showingAIAssistant = false
    @State private var viewMode: CatalogViewMode = .recommendations
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // View Mode Selector
                Picker("View Mode", selection: $viewMode) {
                    Text("AI Picks").tag(CatalogViewMode.recommendations)
                    Text("Categories").tag(CatalogViewMode.categories)
                    Text("Trending").tag(CatalogViewMode.trending)
                    Text("Insights").tag(CatalogViewMode.insights)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on view mode
                switch viewMode {
                case .recommendations:
                    AIRecommendationsContent(
                        viewModel: aiRecommendationsViewModel,
                        onAppSelected: selectApp
                    )
                    
                case .categories:
                    AICategoriesContent(
                        viewModel: aiRecommendationsViewModel,
                        onAppSelected: selectApp
                    )
                    
                case .trending:
                    AITrendingContent(
                        viewModel: aiRecommendationsViewModel,
                        onAppSelected: selectApp
                    )
                    
                case .insights:
                    AIInsightsContent(
                        analyticsService: aiAnalyticsService,
                        onAppSelected: selectApp
                    )
                }
            }
            .navigationTitle("Smart Catalog")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAIAssistant = true
                    }) {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.blue)
                    }
                    
                    Button("Refresh") {
                        refreshData()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAppDetail) {
            if let app = selectedApp {
                EnhancedAppDetailView(
                    app: app,
                    recommendation: findRecommendation(for: app),
                    viewModel: aiRecommendationsViewModel
                )
            }
        }
        .sheet(isPresented: $showingAIAssistant) {
            AIAssistantView()
        }
        .onAppear {
            loadInitialData()
        }
    }
    
    // MARK: - Actions
    
    private func selectApp(_ app: AppModel) {
        selectedApp = app
        showingAppDetail = true
        
        // Record interaction if it's an AI recommendation
        if let recommendation = findRecommendation(for: app) {
            aiRecommendationsViewModel.recordInteraction(with: recommendation, type: .view)
        }
    }
    
    private func findRecommendation(for app: AppModel) -> AIRecommendation? {
        return aiRecommendationsViewModel.recommendations.first { $0.id == app.id }
    }
    
    private func loadInitialData() {
        aiRecommendationsViewModel.refresh()
        aiAnalyticsService.refreshAll()
    }
    
    private func refreshData() {
        aiRecommendationsViewModel.refresh()
        aiAnalyticsService.refreshAll()
    }
}

// MARK: - View Mode Enum
enum CatalogViewMode: CaseIterable {
    case recommendations
    case categories
    case trending
    case insights
}

// MARK: - AI Recommendations Content
struct AIRecommendationsContent: View {
    @ObservedObject var viewModel: AIRecommendationsViewModel
    let onAppSelected: (AppModel) -> Void
    
    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 180), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Top Picks Section
                if !viewModel.topRecommendations.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🎯 Top AI Picks for You")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.topRecommendations) { recommendation in
                                    TopPickCard(recommendation: recommendation) {
                                        onAppSelected(recommendation.toAppModel())
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // All Recommendations Grid
                VStack(alignment: .leading, spacing: 12) {
                    Text("🧠 All AI Recommendations")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.recommendations) { recommendation in
                            SmartAppCard(
                                recommendation: recommendation,
                                viewModel: viewModel
                            ) {
                                onAppSelected(recommendation.toAppModel())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .loadingOverlay(isLoading: viewModel.isLoading)
    }
}

// MARK: - AI Categories Content
struct AICategoriesContent: View {
    @ObservedObject var viewModel: AIRecommendationsViewModel
    let onAppSelected: (AppModel) -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Trending Categories
                if !viewModel.trendingCategories.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("📈 Trending Categories")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                            ForEach(viewModel.trendingCategories, id: \.name) { category in
                                TrendingCategoryCard(
                                    category: category,
                                    apps: viewModel.recommendations.filter { $0.category == category.name }
                                ) { app in
                                    onAppSelected(app.toAppModel())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Categories with Recommendations
                ForEach(Array(viewModel.recommendationsByCategory.keys), id: \.self) { category in
                    if let apps = viewModel.recommendationsByCategory[category], !apps.isEmpty {
                        CategorySection(
                            categoryName: category,
                            recommendations: apps,
                            viewModel: viewModel,
                            onAppSelected: onAppSelected
                        )
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - AI Trending Content
struct AITrendingContent: View {
    @ObservedObject var viewModel: AIRecommendationsViewModel
    let onAppSelected: (AppModel) -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("🔥 Trending Now")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.recommendations.sorted { $0.popularity > $1.popularity }) { recommendation in
                        TrendingAppRow(
                            recommendation: recommendation,
                            viewModel: viewModel
                        ) {
                            onAppSelected(recommendation.toAppModel())
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - AI Insights Content
struct AIInsightsContent: View {
    @ObservedObject var analyticsService: AIAnalyticsService
    let onAppSelected: (AppModel) -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // System Health Overview
                if let dashboardData = analyticsService.dashboardData {
                    SystemHealthCard(overview: dashboardData.overview)
                }
                
                // AI Insights
                if !analyticsService.insights.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("💡 AI Insights")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(analyticsService.insights) { insight in
                                InsightCard(insight: insight)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Performance Metrics
                if let metrics = analyticsService.performanceMetrics {
                    PerformanceMetricsCard(metrics: metrics)
                }
            }
            .padding(.vertical)
        }
        .loadingOverlay(isLoading: analyticsService.isLoading)
    }
}

// MARK: - Supporting Cards and Views

struct TopPickCard: View {
    let recommendation: AIRecommendation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // App Icon with Badge
                ZStack {
                    Image(systemName: recommendation.iconName.isEmpty ? "app" : recommendation.iconName)
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                    
                    // AI Badge
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.blue)
                                .cornerRadius(6)
                        }
                        Spacer()
                    }
                    .offset(x: 8, y: -8)
                }
                
                VStack(spacing: 4) {
                    Text(recommendation.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text("AI Score: \(Int(recommendation.score * 20))%")
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
            }
            .frame(width: 140, height: 160)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SmartAppCard: View {
    let recommendation: AIRecommendation
    let viewModel: AIRecommendationsViewModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Header with Icon and AI Badge
                HStack {
                    Image(systemName: recommendation.iconName.isEmpty ? "app" : recommendation.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                        .frame(width: 32, height: 32)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                    
                    Spacer()
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                }
                
                Text(recommendation.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(viewModel.getQualityScore(for: recommendation))
                    .font(.caption)
                    .foregroundColor(.blue)
                    .lineLimit(1)
                
                HStack {
                    Text(viewModel.getPopularityIndicator(for: recommendation))
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text("\(Int(recommendation.score * 20))%")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TrendingCategoryCard: View {
    let category: AICategory
    let apps: [AIRecommendation]
    let onAppSelected: (AIRecommendation) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                let (icon, color) = getTrendIcon()
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }
            
            Text("\(apps.count) AI recommendations")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Preview of apps
            HStack(spacing: 4) {
                ForEach(apps.prefix(3)) { app in
                    Button(action: {
                        onAppSelected(app)
                    }) {
                        Image(systemName: app.iconName.isEmpty ? "app" : app.iconName)
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                            .frame(width: 24, height: 24)
                            .background(Color(.systemGray6))
                            .cornerRadius(4)
                    }
                }
                
                if apps.count > 3 {
                    Text("+\(apps.count - 3)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func getTrendIcon() -> (String, Color) {
        switch category.trend.lowercased() {
        case "up":
            return ("arrow.up.circle.fill", .green)
        case "down":
            return ("arrow.down.circle.fill", .red)
        default:
            return ("minus.circle.fill", .orange)
        }
    }
}

struct CategorySection: View {
    let categoryName: String
    let recommendations: [AIRecommendation]
    let viewModel: AIRecommendationsViewModel
    let onAppSelected: (AppModel) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: viewModel.getCategoryIcon(for: categoryName))
                    .foregroundColor(.blue)
                Text(categoryName)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(recommendations.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recommendations) { recommendation in
                        SmartAppCard(
                            recommendation: recommendation,
                            viewModel: viewModel
                        ) {
                            onAppSelected(recommendation.toAppModel())
                        }
                        .frame(width: 160)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct TrendingAppRow: View {
    let recommendation: AIRecommendation
    let viewModel: AIRecommendationsViewModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: recommendation.iconName.isEmpty ? "app" : recommendation.iconName)
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                    .frame(width: 48, height: 48)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Text(recommendation.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.getPopularityIndicator(for: recommendation))
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(4)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                    
                    Text("\(Int(recommendation.score * 20))%")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SystemHealthCard: View {
    let overview: AIAnalyticsOverview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🎯 System Overview")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(overview.totalAppsUsed)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("Apps Used")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("\(overview.vmEfficiencyScore)%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("Efficiency")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text(overview.averageSessionTime)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                        Text("Avg. Session")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(overview.lastOptimized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Last Optimized")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            .padding(.horizontal)
        }
    }
}

struct InsightCard: View {
    let insight: AIInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(Int(insight.confidence * 100))%")
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Text(insight.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            if insight.actionable && !insight.actions.isEmpty {
                HStack {
                    ForEach(insight.actions.prefix(2), id: \.endpoint) { action in
                        Button(action.label) {
                            // Handle action
                        }
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct PerformanceMetricsCard: View {
    let metrics: AIPerformanceData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 Performance Metrics")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                MetricRow(title: "CPU Usage", value: "\(Int(metrics.current.cpu_usage))%", color: getMetricColor(metrics.current.cpu_usage))
                MetricRow(title: "Memory Usage", value: "\(Int(metrics.current.memory_usage))%", color: getMetricColor(metrics.current.memory_usage))
                MetricRow(title: "Network Latency", value: "\(Int(metrics.current.network_latency))ms", color: getLatencyColor(metrics.current.network_latency))
                MetricRow(title: "Active Apps", value: "\(metrics.current.active_apps)", color: .blue)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            .padding(.horizontal)
        }
    }
    
    private func getMetricColor(_ value: Double) -> Color {
        switch value {
        case 0..<50:
            return .green
        case 50..<80:
            return .orange
        default:
            return .red
        }
    }
    
    private func getLatencyColor(_ latency: Double) -> Color {
        switch latency {
        case 0..<50:
            return .green
        case 50..<100:
            return .orange
        default:
            return .red
        }
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Enhanced App Detail View
struct EnhancedAppDetailView: View {
    let app: AppModel
    let recommendation: AIRecommendation?
    let viewModel: AIRecommendationsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with AI Enhancement
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: app.iconName.isEmpty ? "app" : app.iconName)
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                                .frame(width: 80, height: 80)
                                .background(Color(.systemGray6))
                                .cornerRadius(16)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(app.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(app.category)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Text("Version \(app.version)")
                                    Spacer()
                                    Text(app.size)
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if let recommendation = recommendation {
                                VStack {
                                    Image(systemName: "brain.head.profile")
                                        .font(.system(size: 16))
                                        .foregroundColor(.blue)
                                    Text("\(Int(recommendation.score * 20))%")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        // AI Recommendation Insight
                        if let recommendation = recommendation {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("🤖 AI Insight")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                
                                Text(viewModel.getFormattedReason(for: recommendation))
                                    .font(.body)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                            }
                        }
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        Text(app.description)
                            .font(.body)
                    }
                    
                    // AI-Powered Action Button
                    Button(action: {
                        if let recommendation = recommendation {
                            viewModel.installApp(recommendation)
                        }
                    }) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                            Text("Install with AI Recommendation")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Smart Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SmartCatalogView()
}