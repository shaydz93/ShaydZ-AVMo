import SwiftUI

struct AppDetailsView: View {
    let app: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var appDetails: AppDetailsModel?
    @State private var isLoading = false
    @State private var error: APIError?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 16) {
                        Image(systemName: app.iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .foregroundColor(.blue)
                            .padding(10)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(app.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            if let details = appDetails {
                                Text(details.developer ?? "ShaydZ Inc.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("v\(details.version)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(app.description)
                            .font(.body)
                    }
                    
                    if let details = appDetails {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 16) {
                            DetailRow(title: "Category", value: details.category ?? "Uncategorized")
                            DetailRow(title: "Size", value: formatSize(details.size))
                            DetailRow(title: "Last updated", value: formatDate(details.lastUpdated))
                            DetailRow(title: "Package", value: details.packageName)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Launch app
                        dismiss()
                    }) {
                        Text("Launch")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("App Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Close")
                    }
                }
            }
            .loadingOverlay(isLoading: isLoading)
            .apiErrorAlert(error: $error)
            .onAppear {
                loadAppDetails()
            }
        }
    }
    
    private func loadAppDetails() {
        isLoading = true
        
        let appCatalogService = SupabaseAppCatalogService.shared
        appCatalogService.getAppDetails(appId: app.id.uuidString)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                isLoading = false
                if case .failure(let apiError) = completion {
                    error = apiError
                }
            }, receiveValue: { details in
                self.appDetails = details
            })
            .store(in: &Utilities.cancellables)
    }
    
    private func formatSize(_ size: Int?) -> String {
        guard let size = size else { return "Unknown" }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
    
    private func formatDate(_ dateString: String) -> String {
        // Parse ISO8601 date
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        // Format for display
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .none
        return displayFormatter.string(from: date)
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

// A utility struct to store cancellables
struct Utilities {
    static var cancellables = Set<AnyCancellable>()
}
