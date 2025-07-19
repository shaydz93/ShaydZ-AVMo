import SwiftUI

struct AppLibraryView: View {
    @StateObject private var viewModel = AppLibraryViewModel()
    
    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 170), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
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
                
                ScrollView {
                    if viewModel.apps.isEmpty && !viewModel.isLoading {
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
            .apiErrorAlert(error: $viewModel.error)
            .sheet(item: $viewModel.selectedApp) { app in
                VirtualEnvironmentView(app: app)
            }
        }
    }
}

struct CategoryChipView: View {
    let category: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(category)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct AppIconView: View {
    let app: AppModel
    
    var body: some View {
        VStack {
            Image(systemName: app.iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .foregroundColor(.blue)
                .padding(10)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text(app.name)
                .font(.headline)
                .lineLimit(1)
            
            Text(app.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(height: 170)
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct AppRowView: View {
    let app: AppModel
    
    var body: some View {
        HStack {
            Image(systemName: app.iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .foregroundColor(.blue)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            
            VStack(alignment: .leading) {
                Text(app.name)
                    .font(.headline)
                
                Text(app.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

struct AppLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        AppLibraryView()
    }
}
