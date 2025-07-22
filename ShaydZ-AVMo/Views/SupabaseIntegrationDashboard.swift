import SwiftUI
import Combine

struct SupabaseIntegrationDashboard: View {
    @StateObject private var demoService = SupabaseDemoService.shared
    @StateObject private var integrationManager = SupabaseIntegrationManager.shared
    @State private var showingDetails = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with status
                headerView
                
                // Tab selection
                tabSelector
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    connectionStatusView
                        .tag(0)
                    
                    demoView
                        .tag(1)
                    
                    featuresView
                        .tag(2)
                    
                    testResultsView
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Supabase Integration")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Details") {
                        showingDetails = true
                    }
                }
            }
            .sheet(isPresented: $showingDetails) {
                IntegrationDetailsView()
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            // Connection Status
            HStack {
                Circle()
                    .fill(integrationManager.isConnected ? Color.green : Color.orange)
                    .frame(width: 12, height: 12)
                    .scaleEffect(integrationManager.isConnected ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: integrationManager.isConnected)
                
                Text(integrationManager.connectionStatus.displayText)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if integrationManager.syncInProgress {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // Last sync info
            if let lastSync = integrationManager.lastSyncTime {
                Text("Last sync: \\(lastSync, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(0..<4) { index in
                Button(action: {
                    selectedTab = index
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tabIcon(for: index))
                            .font(.title2)
                        Text(tabTitle(for: index))
                            .font(.caption)
                    }
                    .foregroundColor(selectedTab == index ? .accentColor : .secondary)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.05))
    }
    
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "wifi"
        case 1: return "play.circle"
        case 2: return "star.circle"
        case 3: return "checkmark.circle"
        default: return "circle"
        }
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Status"
        case 1: return "Demo"
        case 2: return "Features"
        case 3: return "Tests"
        default: return "Tab"
        }
    }
    
    // MARK: - Connection Status View
    
    private var connectionStatusView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Connection Health
                connectionHealthCard
                
                // Configuration
                configurationCard
                
                // Actions
                actionsCard
            }
            .padding()
        }
    }
    
    private var connectionHealthCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Connection Health")
                    .font(.headline)
                Spacer()
                Text(integrationManager.getConnectionHealth().statusEmoji)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HealthRow(title: "Connection", status: integrationManager.isConnected)
                HealthRow(title: "Authentication", status: integrationManager.isConnected)
                HealthRow(title: "Database", status: integrationManager.isConnected)
                HealthRow(title: "Real-time", status: integrationManager.isConnected)
            }
            
            if integrationManager.errorCount > 0 {
                Text("Errors: \\(integrationManager.errorCount)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var configurationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Configuration")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 6) {
                ConfigRow(title: "Project URL", value: SupabaseConfig.supabaseURL)
                ConfigRow(title: "API Key", value: String(SupabaseConfig.supabaseAnonKey.prefix(20)) + "...")
                ConfigRow(title: "Auth URL", value: SupabaseConfig.authURL)
                ConfigRow(title: "Rest URL", value: SupabaseConfig.restURL)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var actionsCard: some View {
        VStack(spacing: 12) {
            Button("Reconnect") {
                integrationManager.reconnect()
            }
            .buttonStyle(.borderedProminent)
            .disabled(integrationManager.syncInProgress)
            
            Button("Full Sync") {
                integrationManager.performFullSync()
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &cancellables)
            }
            .buttonStyle(.bordered)
            .disabled(integrationManager.syncInProgress)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Demo View
    
    private var demoView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Demo Status
                VStack(alignment: .leading, spacing: 8) {
                    Text("Integration Demo")
                        .font(.headline)
                    
                    Text(demoService.demoStatus.displayText)
                        .foregroundColor(demoService.isRunningDemo ? .orange : .primary)
                    
                    if !demoService.currentStep.isEmpty {
                        Text(demoService.currentStep)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                
                // Demo Controls
                VStack(spacing: 12) {
                    Button("Run Full Demo") {
                        demoService.runFullDemo()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(demoService.isRunningDemo)
                    
                    if demoService.isRunningDemo {
                        ProgressView("Running demo...")
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                
                // Demo Data Preview
                if !demoService.demoApps.isEmpty {
                    demoDataPreview
                }
            }
            .padding()
        }
    }
    
    private var demoDataPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Demo Data")
                .font(.headline)
            
            // Apps preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Apps (\\(demoService.demoApps.count))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ForEach(demoService.demoApps.prefix(3), id: \\.id) { app in
                    HStack {
                        Image(systemName: app.iconName)
                            .foregroundColor(.accentColor)
                        VStack(alignment: .leading) {
                            Text(app.name)
                                .font(.caption)
                                .fontWeight(.medium)
                            Text(app.category)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(app.version)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                if demoService.demoApps.count > 3 {
                    Text("... and \\(demoService.demoApps.count - 3) more")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Features View
    
    private var featuresView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Integration Features")
                    .font(.title2)
                    .fontWeight(.bold)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    FeatureCard(
                        icon: "person.badge.key",
                        title: "Authentication",
                        description: "JWT-based authentication with user profiles",
                        isEnabled: integrationManager.isConnected
                    )
                    
                    FeatureCard(
                        icon: "cylinder.split.1x2",
                        title: "Database",
                        description: "PostgreSQL with Row Level Security",
                        isEnabled: integrationManager.isConnected
                    )
                    
                    FeatureCard(
                        icon: "bolt.circle",
                        title: "Real-time",
                        description: "Live data synchronization",
                        isEnabled: integrationManager.isConnected
                    )
                    
                    FeatureCard(
                        icon: "apps.iphone",
                        title: "App Catalog",
                        description: "Enterprise app management",
                        isEnabled: true
                    )
                    
                    FeatureCard(
                        icon: "desktopcomputer",
                        title: "VM Sessions",
                        description: "Virtual machine tracking",
                        isEnabled: true
                    )
                    
                    FeatureCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Analytics",
                        description: "User activity logging",
                        isEnabled: integrationManager.isConnected
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Test Results View
    
    private var testResultsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Test Results")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if demoService.testResults.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "testtube.2")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No tests run yet")
                            .foregroundColor(.secondary)
                        Text("Run the demo to see test results")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(demoService.testResults.indices, id: \\.self) { index in
                            let result = demoService.testResults[index]
                            TestResultRow(result: result)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Supporting Views
    
    private struct HealthRow: View {
        let title: String
        let status: Bool
        
        var body: some View {
            HStack {
                Text(title)
                    .font(.caption)
                Spacer()
                Image(systemName: status ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(status ? .green : .red)
                    .font(.caption)
            }
        }
    }
    
    private struct ConfigRow: View {
        let title: String
        let value: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }
    
    private struct FeatureCard: View {
        let icon: String
        let title: String
        let description: String
        let isEnabled: Bool
        
        var body: some View {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isEnabled ? .accentColor : .secondary)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(isEnabled ? .primary : .secondary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                HStack {
                    Circle()
                        .fill(isEnabled ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    Text(isEnabled ? "Active" : "Inactive")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(height: 120)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private struct TestResultRow: View {
        let result: SupabaseDemoService.TestResult
        
        var body: some View {
            HStack {
                Text(result.emoji)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.test)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(result.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(result.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Helpers
    
    @State private var cancellables = Set<AnyCancellable>()
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Integration Details View

struct IntegrationDetailsView: View {
    @Environment(\\.dismiss) private var dismiss
    @StateObject private var integrationManager = SupabaseIntegrationManager.shared
    @StateObject private var demoService = SupabaseDemoService.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Integration Status
                    statusSection
                    
                    // Configuration Details
                    configurationSection
                    
                    // Performance Metrics
                    performanceSection
                    
                    // Available Features
                    featuresSection
                }
                .padding()
            }
            .navigationTitle("Integration Details")
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
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Integration Status")
                .font(.headline)
            
            let status = demoService.getIntegrationStatus()
            
            HStack {
                Text("Overall Health:")
                Spacer()
                Text(status.overallHealth)
                    .fontWeight(.medium)
                Text(status.statusEmoji)
            }
            
            HStack {
                Text("Connection:")
                Spacer()
                Text(status.isConnected ? "Connected" : "Disconnected")
                    .foregroundColor(status.isConnected ? .green : .orange)
            }
            
            HStack {
                Text("Features Enabled:")
                Spacer()
                Text("\\(status.featuresEnabled.count)")
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Configuration")
                .font(.headline)
            
            Group {
                DetailRow(title: "Supabase URL", value: SupabaseConfig.supabaseURL)
                DetailRow(title: "Auth Endpoint", value: SupabaseConfig.authURL)
                DetailRow(title: "REST Endpoint", value: SupabaseConfig.restURL)
                DetailRow(title: "Realtime Endpoint", value: SupabaseConfig.realtimeURL)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance")
                .font(.headline)
            
            let health = integrationManager.getConnectionHealth()
            
            HStack {
                Text("Health Score:")
                Spacer()
                Text(String(format: "%.1f%%", health.healthScore * 100))
                    .fontWeight(.medium)
            }
            
            HStack {
                Text("Error Count:")
                Spacer()
                Text("\\(health.errorCount)")
                    .foregroundColor(health.errorCount > 0 ? .red : .green)
            }
            
            if let lastSync = health.lastSync {
                HStack {
                    Text("Last Sync:")
                    Spacer()
                    Text(lastSync, style: .relative)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Features")
                .font(.headline)
            
            let status = demoService.getIntegrationStatus()
            
            ForEach(status.featuresEnabled, id: \\.self) { feature in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(feature)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    private struct DetailRow: View {
        let title: String
        let value: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                    .textSelection(.enabled)
            }
        }
    }
}

#Preview {
    SupabaseIntegrationDashboard()
}
