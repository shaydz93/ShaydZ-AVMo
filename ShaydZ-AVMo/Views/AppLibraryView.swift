import SwiftUI

struct AppLibraryView: View {
    @StateObject private var viewModel = AppLibraryViewModel()
    @StateObject private var aiRecommendationsViewModel = AIRecommendationsViewModel()
    @State private var showingAppDetail = false
    @State private var selectedApp: AppModel?
    @State private var showingAIRecommendations = false
    
    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 170), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $viewModel.searchText) {
                    viewModel.searchApps()
                }
                
                // AI Recommendations Section
                if !aiRecommendationsViewModel.topRecommendations.isEmpty {
                    AIRecommendationsSection(
                        recommendations: aiRecommendationsViewModel.topRecommendations,
                        onRecommendationTapped: { recommendation in
                            selectedApp = recommendation.toAppModel()
                            showingAppDetail = true
                            aiRecommendationsViewModel.recordInteraction(with: recommendation, type: .view)
                        },
                        onViewAllTapped: {
                            showingAIRecommendations = true
                        }
                    )
                }
                
                // Categories
                if !viewModel.categories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.categories, id: \.self) { category in
                                CategoryChipView(
                                    category: category,
                                    isSelected: viewModel.selectedCategory == category,
                                    onTap: {
                                        viewModel.selectCategory(category)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .background(Color(.systemGroupedBackground))
                }
                
                // Apps Grid
                ScrollView {
                    if filteredApps.isEmpty && !viewModel.isLoading {
                        EmptyStateView {
                            viewModel.clearSearch()
                        }
                    } else {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(filteredApps) { app in
                                AppCardView(app: app) {
                                    selectedApp = app
                                    showingAppDetail = true
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("App Library")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAIRecommendations = true
                    }) {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.blue)
                    }
                    
                    Button("Refresh") {
                        viewModel.fetchApps()
                        aiRecommendationsViewModel.refresh()
                    }
                }
            }
        }
        .loadingOverlay(isLoading: viewModel.isLoading || aiRecommendationsViewModel.isLoading)
        .errorAlert(errorMessage: .constant(viewModel.errorMessage ?? aiRecommendationsViewModel.errorMessage))
        .sheet(isPresented: $showingAppDetail) {
            if let app = selectedApp {
                AppDetailView(app: app, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showingAIRecommendations) {
            AIRecommendationsDetailView(viewModel: aiRecommendationsViewModel)
        }
    }
    
    private var filteredApps: [AppModel] {
        var apps = viewModel.apps
        
        // Filter by category
        if let selectedCategory = viewModel.selectedCategory {
            apps = apps.filter { $0.category == selectedCategory }
        }
        
        // Filter by search text
        if !viewModel.searchText.isEmpty {
            apps = apps.filter { app in
                app.name.localizedCaseInsensitiveContains(viewModel.searchText) ||
                app.description.localizedCaseInsensitiveContains(viewModel.searchText)
            }
        }
        
        return apps
    }
}

// MARK: - Supporting Views

struct SearchBar: View {
    @Binding var text: String
    let onSearchButtonClicked: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search apps...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    onSearchButtonClicked()
                }
            
            if !text.isEmpty {
                Button("Clear") {
                    text = ""
                    onSearchButtonClicked()
                }
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct CategoryChipView: View {
    let category: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(category)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct AppCardView: View {
    let app: AppModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // App Icon
                Image(systemName: app.iconName.isEmpty ? "app" : app.iconName)
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                    .frame(width: 60, height: 60)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                
                // App Name
                Text(app.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                // Status indicators
                HStack(spacing: 4) {
                    if app.isInstalled {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption2)
                    }
                    if app.isRunning {
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(.orange)
                            .font(.caption2)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyStateView: View {
    let onClearFilters: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "apps.iphone")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No Apps Found")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Try adjusting your search or filters")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Clear Filters") {
                onClearFilters()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

struct AppDetailView: View {
    let app: AppModel
    let viewModel: AppLibraryViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
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
                    }
                    
                    // Description
                    Text("Description")
                        .font(.headline)
                    Text(app.description)
                        .font(.body)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        if !app.isInstalled {
                            Button("Install") {
                                viewModel.installApp(app)
                            }
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                        } else {
                            HStack(spacing: 12) {
                                Button("Launch") {
                                    viewModel.launchApp(app)
                                }
                                .buttonStyle(.borderedProminent)
                                .frame(maxWidth: .infinity)
                                
                                Button("Uninstall") {
                                    viewModel.uninstallApp(app)
                                }
                                .buttonStyle(.bordered)
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("App Details")
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
    AppLibraryView()
}

// MARK: - AI Recommendations Section

struct AIRecommendationsSection: View {
    let recommendations: [AIRecommendation]
    let onRecommendationTapped: (AIRecommendation) -> Void
    let onViewAllTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("AI Recommended for You")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Button("View All") {
                    onViewAllTapped()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recommendations) { recommendation in
                        AIRecommendationCard(recommendation: recommendation) {
                            onRecommendationTapped(recommendation)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }
}

struct AIRecommendationCard: View {
    let recommendation: AIRecommendation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // App Icon
                Image(systemName: recommendation.iconName.isEmpty ? "app" : recommendation.iconName)
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                    .frame(width: 50, height: 50)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                // App Name
                Text(recommendation.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 80)
                
                // AI Score
                HStack(spacing: 2) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 8))
                        .foregroundColor(.blue)
                    Text("\(Int(recommendation.score * 20))%")
                        .font(.system(size: 8))
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
            }
            .frame(width: 100, height: 120)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - AI Recommendations Detail View

struct AIRecommendationsDetailView: View {
    @ObservedObject var viewModel: AIRecommendationsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedApp: AppModel?
    @State private var showingAppDetail = false
    
    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 180), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $viewModel.searchText) {
                    // Search is handled automatically by the computed property
                }
                
                // Trending Categories
                if !viewModel.trendingCategories.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Trending Categories")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                            Spacer()
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.trendingCategories, id: \.name) { category in
                                    TrendingCategoryChip(
                                        category: category,
                                        isSelected: viewModel.selectedCategory == category.name,
                                        onTap: {
                                            viewModel.selectCategory(
                                                viewModel.selectedCategory == category.name ? nil : category.name
                                            )
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color(.systemGroupedBackground))
                }
                
                // Recommendations Grid
                ScrollView {
                    if viewModel.filteredRecommendations.isEmpty && !viewModel.isLoading {
                        AIEmptyStateView {
                            viewModel.clearFilters()
                        }
                    } else {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(viewModel.filteredRecommendations) { recommendation in
                                AIRecommendationDetailCard(
                                    recommendation: recommendation,
                                    viewModel: viewModel
                                ) {
                                    selectedApp = recommendation.toAppModel()
                                    showingAppDetail = true
                                    viewModel.recordInteraction(with: recommendation, type: .view)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("AI Recommendations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        viewModel.refresh()
                    }
                }
            }
        }
        .loadingOverlay(isLoading: viewModel.isLoading)
        .errorAlert(errorMessage: .constant(viewModel.errorMessage))
        .sheet(isPresented: $showingAppDetail) {
            if let app = selectedApp {
                AIAppDetailView(app: app, recommendation: findRecommendation(for: app), viewModel: viewModel)
            }
        }
    }
    
    private func findRecommendation(for app: AppModel) -> AIRecommendation? {
        return viewModel.recommendations.first { $0.id == app.id }
    }
}

struct TrendingCategoryChip: View {
    let category: AICategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(category.name)
                    .font(.caption)
                    .fontWeight(.medium)
                
                let (icon, color) = getTrendIcon()
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
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

struct AIRecommendationDetailCard: View {
    let recommendation: AIRecommendation
    let viewModel: AIRecommendationsViewModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: recommendation.iconName.isEmpty ? "app" : recommendation.iconName)
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                        .frame(width: 40, height: 40)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(recommendation.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        Text(recommendation.category)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // AI Recommendation Reason
                Text(viewModel.getFormattedReason(for: recommendation))
                    .font(.caption)
                    .foregroundColor(.blue)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Stats
                HStack {
                    // Quality Score
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.getQualityScore(for: recommendation))
                            .font(.caption2)
                            .fontWeight(.medium)
                        
                        Text("Match Quality")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Popularity
                    Text(viewModel.getPopularityIndicator(for: recommendation))
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AIEmptyStateView: View {
    let onClearFilters: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("No AI Recommendations")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("AI is learning your preferences. Try clearing filters or check back later.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Clear Filters") {
                onClearFilters()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

struct AIAppDetailView: View {
    let app: AppModel
    let recommendation: AIRecommendation?
    let viewModel: AIRecommendationsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
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
                    }
                    
                    // AI Recommendation Reason
                    if let recommendation = recommendation {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Why AI Recommends This")
                                .font(.headline)
                            
                            Text(viewModel.getFormattedReason(for: recommendation))
                                .font(.body)
                                .foregroundColor(.blue)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Description
                    Text("Description")
                        .font(.headline)
                    Text(app.description)
                        .font(.body)
                    
                    // Action Button
                    Button("Install from AI Recommendation") {
                        if let recommendation = recommendation {
                            viewModel.installApp(recommendation)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .navigationTitle("App Details")
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
