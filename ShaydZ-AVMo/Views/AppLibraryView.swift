import SwiftUI

struct AppLibraryView: View {
    @StateObject private var viewModel = AppLibraryViewModel()
    @State private var showingAppDetail = false
    @State private var selectedApp: AppModel?
    
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        viewModel.fetchApps()
                    }
                }
            }
        }
        .loadingOverlay(isLoading: viewModel.isLoading)
        .errorAlert(errorMessage: .constant(viewModel.errorMessage))
        .sheet(isPresented: $showingAppDetail) {
            if let app = selectedApp {
                AppDetailView(app: app, viewModel: viewModel)
            }
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
