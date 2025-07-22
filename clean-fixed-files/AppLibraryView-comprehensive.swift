import SwiftUI

/// App Library View for ShaydZ AVMo
struct ShaydZAVMo_AppLibraryView: View {
    @StateObject private var viewModel = ShaydZAVMo_AppLibraryViewModel()
    
    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 170), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category filter section
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
                
                // Main content area
                ScrollView {
                    if viewModel.apps.isEmpty && !viewModel.isLoading {
                        // Empty state
                        VStack(spacing: 20) {
                            Image(systemName: "square.grid.3x3.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .foregroundColor(.secondary.opacity(0.5))
                            
                            Text("No apps found")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            
                            if viewModel.selectedCategory != nil || !viewModel.searchText.isEmpty {
                                Button("Clear filters") {
                                    viewModel.selectedCategory = nil
                                    viewModel.clearSearch()
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 50)
                    } else {
                        // Apps grid
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.apps) { app in
                                AppIconView(app: app)
                                    .onTapGesture {
                                        viewModel.launchApp(app)
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("App Library")
            .searchable(text: $viewModel.searchText, prompt: "Search apps")
            .onSubmit(of: .search) {
                viewModel.searchApps()
            }
            .loadingOverlay(isLoading: viewModel.isLoading)
            .errorAlert(errorMessage: $viewModel.errorMessage)
            .sheet(item: $viewModel.selectedApp) { app in
                AppDetailView(app: app)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            viewModel.showInstalledOnly.toggle()
                        }) {
                            Label(
                                viewModel.showInstalledOnly ? "Show All Apps" : "Show Installed Only",
                                systemImage: viewModel.showInstalledOnly ? "square.grid.3x3" : "checkmark.square"
                            )
                        }
                        
                        Button(action: {
                            viewModel.refreshApps()
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear {
            viewModel.refreshApps()
        }
    }
}

/// Category chip view component
struct CategoryChipView: View {
    let category: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(category)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// App icon view component
struct AppIconView: View {
    let app: ShaydZAVMo_AppModel
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .frame(width: 60, height: 60)
                
                Image(systemName: app.systemIcon)
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 2) {
                Text(app.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if app.isInstalled {
                    Text("Installed")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                } else if app.canInstall {
                    Text("Available")
                        .font(.caption2)
                        .foregroundColor(.blue)
                } else {
                    Text("Incompatible")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
        }
        .frame(width: 100)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

/// App detail view component
struct AppDetailView: View {
    let app: ShaydZAVMo_AppModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ShaydZAVMo_AppLibraryViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // App header
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemGray6))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: app.systemIcon)
                                .font(.largeTitle)
                                .foregroundColor(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(app.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(app.category)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Version \(app.version)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(app.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // App info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Information")
                            .font(.headline)
                        
                        InfoRow(title: "Size", value: app.sizeFormatted)
                        InfoRow(title: "Category", value: app.category)
                        InfoRow(title: "Compatible", value: app.isCompatible ? "Yes" : "No")
                        
                        if let metadata = app.metadata {
                            if let developer = metadata.developer {
                                InfoRow(title: "Developer", value: developer)
                            }
                            if let rating = metadata.rating {
                                InfoRow(title: "Rating", value: String(format: "%.1f", rating))
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("App Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if app.isInstalled {
                        if app.canLaunch {
                            Button("Launch") {
                                viewModel.launchApp(app)
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Button("Uninstall") {
                                viewModel.uninstallApp(app)
                                dismiss()
                            }
                            .buttonStyle(.bordered)
                        }
                    } else if app.canInstall {
                        Button("Install") {
                            viewModel.installApp(app)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }
}

/// Info row component for app details
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

// Type aliases for backward compatibility
typealias AppLibraryView = ShaydZAVMo_AppLibraryView

#Preview {
    ShaydZAVMo_AppLibraryView()
        .environmentObject(ShaydZAVMo_AppLibraryViewModel())
}
