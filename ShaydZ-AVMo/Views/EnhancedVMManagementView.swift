import SwiftUI
import Combine

/// Enhanced VM Management View with UTM-inspired features
struct EnhancedVMManagementView: View {
    @StateObject private var vmService = UTMEnhancedVirtualMachineService.shared
    @StateObject private var configManager = QEMUVMConfigurationManager.shared
    @State private var selectedTab = 0
    @State private var showingCreateVM = false
    @State private var showingTemplateGallery = false
    @State private var selectedTemplate: QEMUVMConfigurationManager.VMTemplate?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with performance overview
                performanceOverviewHeader
                
                // Tab selector
                Picker("View", selection: $selectedTab) {
                    Text("Running").tag(0)
                    Text("Templates").tag(1)
                    Text("Configurations").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    // Running VMs
                    runningVMsView
                        .tag(0)
                    
                    // VM Templates
                    templatesView
                        .tag(1)
                    
                    // Custom Configurations
                    configurationsView
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Virtual Machines")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingCreateVM = true }) {
                            Label("Create from Template", systemImage: "plus.rectangle.on.folder")
                        }
                        
                        Button(action: { showingTemplateGallery = true }) {
                            Label("Browse Templates", systemImage: "square.grid.3x3")
                        }
                        
                        Button(action: { refreshAll() }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateVM) {
                VMCreationWizard()
            }
            .sheet(isPresented: $showingTemplateGallery) {
                VMTemplateGallery(onTemplateSelected: { template in
                    selectedTemplate = template
                    showingCreateVM = true
                })
            }
        }
        .onAppear {
            vmService.startPerformanceMonitoring()
        }
    }
    
    // MARK: - Performance Overview Header
    
    private var performanceOverviewHeader: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading) {
                Text("Active VMs")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\\(vmService.activeVMs.count)")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            VStack(alignment: .leading) {
                Text("Total Memory")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\\(totalMemoryUsage)MB")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(totalMemoryUsage > 6144 ? .red : .primary)
            }
            
            Spacer()
            
            VStack(alignment: .leading) {
                Text("Network I/O")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\\(totalNetworkIO)KB/s")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(UIColor.separator)),
            alignment: .bottom
        )
    }
    
    // MARK: - Running VMs View
    
    private var runningVMsView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if vmService.activeVMs.isEmpty {
                    emptyStateView
                } else {
                    ForEach(Array(vmService.activeVMs.values), id: \\.id) { vm in
                        NavigationLink(destination: EnhancedVMViewer(vmInstance: vm)) {
                            VMInstanceCard(vm: vm)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Templates View
    
    private var templatesView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(configManager.availableTemplates, id: \\.id) { template in
                    VMTemplateCard(
                        template: template,
                        onLaunch: { launchFromTemplate(template) }
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Configurations View
    
    private var configurationsView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(configManager.customConfigurations, id: \\.id) { config in
                    VMConfigurationCard(
                        config: config,
                        onLaunch: { launchFromConfig(config) },
                        onEdit: { editConfiguration(config) },
                        onDelete: { deleteConfiguration(config) }
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "desktopcomputer")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Virtual Machines Running")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create a new VM from a template or launch an existing configuration")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { showingTemplateGallery = true }) {
                Text("Browse Templates")
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
    
    // MARK: - Computed Properties
    
    private var totalMemoryUsage: Int {
        vmService.activeVMs.values.reduce(0) { $0 + $1.config.memorySize }
    }
    
    private var totalNetworkIO: Int {
        let totalBytes = vmService.activeVMs.values.reduce(0) { total, vm in
            return total + vm.performance.networkIO.sent + vm.performance.networkIO.received
        }
        return Int(totalBytes / 1024) // Convert to KB
    }
    
    // MARK: - Actions
    
    private func refreshAll() {
        // Refresh VM list and performance data
        vmService.objectWillChange.send()
        configManager.objectWillChange.send()
    }
    
    private func launchFromTemplate(_ template: QEMUVMConfigurationManager.VMTemplate) {
        Task {
            do {
                _ = try await vmService.launchEnhancedVM(configId: template.configuration.id)
            } catch {
                print("Failed to launch VM from template: \\(error)")
            }
        }
    }
    
    private func launchFromConfig(_ config: UTMEnhancedVMConfig) {
        Task {
            do {
                _ = try await vmService.launchEnhancedVM(configId: config.id)
            } catch {
                print("Failed to launch VM from config: \\(error)")
            }
        }
    }
    
    private func editConfiguration(_ config: UTMEnhancedVMConfig) {
        // TODO: Navigate to configuration editor
    }
    
    private func deleteConfiguration(_ config: UTMEnhancedVMConfig) {
        Task {
            do {
                _ = try await configManager.deleteCustomConfiguration(id: config.id)
            } catch {
                print("Failed to delete configuration: \\(error)")
            }
        }
    }
}

/// VM Instance Card
struct VMInstanceCard: View {
    let vm: UTMEnhancedVirtualMachineService.VMInstance
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(vm.config.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(stateDescription)
                        .font(.caption)
                        .foregroundColor(stateColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\\(vm.config.architecture.rawValue)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                    
                    Text("\\(vm.config.memorySize)MB")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Performance metrics
            HStack(spacing: 16) {
                metricView("CPU", "\\(Int(vm.performance.cpuUsage))%", vm.performance.cpuUsage < 80 ? .green : .red)
                metricView("RAM", "\\(Int(vm.performance.memoryUsage))%", vm.performance.memoryUsage < 90 ? .green : .red)
                metricView("FPS", "\\(vm.performance.frameRate)", vm.performance.frameRate >= 30 ? .green : .orange)
                metricView("Ping", "\\(vm.performance.latency)ms", vm.performance.latency < 50 ? .green : .yellow)
            }
            
            // Android info if applicable
            if !vm.config.androidConfig.androidVersion.isEmpty {
                HStack {
                    Image(systemName: "smartphone")
                        .foregroundColor(.green)
                    Text("Android \\(vm.config.androidConfig.androidVersion)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if vm.config.androidConfig.isGooglePlayEnabled {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                        Text("Google Play")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var stateDescription: String {
        switch vm.state {
        case .stopped:
            return "Stopped"
        case .starting:
            return "Starting..."
        case .running:
            return "Running"
        case .pausing:
            return "Pausing..."
        case .paused:
            return "Paused"
        case .stopping:
            return "Stopping..."
        case .error(let message):
            return "Error: \\(message)"
        }
    }
    
    private var stateColor: Color {
        switch vm.state {
        case .stopped, .paused:
            return .secondary
        case .starting, .pausing, .stopping:
            return .orange
        case .running:
            return .green
        case .error:
            return .red
        }
    }
    
    private func metricView(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

/// VM Template Card
struct VMTemplateCard: View {
    let template: QEMUVMConfigurationManager.VMTemplate
    let onLaunch: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon and OS type
            HStack {
                Image(systemName: template.iconName)
                    .font(.largeTitle)
                    .foregroundColor(.accentColor)
                
                Spacer()
                
                Text(template.osType.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.2))
                    .cornerRadius(4)
            }
            
            // Template info
            Text(template.name)
                .font(.headline)
                .lineLimit(1)
            
            Text(template.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Requirements
            HStack {
                Label("\\(template.requiredMemoryMB)MB", systemImage: "memorychip")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label("\\(template.requiredStorageGB)GB", systemImage: "internaldrive")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Features
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(template.features.prefix(3)), id: \\.rawValue) { feature in
                        Text(feature.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(2)
                    }
                    
                    if template.features.count > 3 {
                        Text("+\\(template.features.count - 3)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Launch button
            Button(action: onLaunch) {
                Text("Launch")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

/// VM Configuration Card
struct VMConfigurationCard: View {
    let config: UTMEnhancedVMConfig
    let onLaunch: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(config.name)
                        .font(.headline)
                    
                    Text("\\(config.architecture.rawValue) • \\(config.memorySize)MB • \\(config.cpuCount) cores")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Menu {
                    Button(action: onLaunch) {
                        Label("Launch", systemImage: "play.fill")
                    }
                    
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(action: onDelete, role: .destructive) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                }
            }
            
            // Security features
            HStack {
                if config.security.hasSecureBoot {
                    securityBadge("Secure Boot", .green)
                }
                
                if config.security.hasEncryption {
                    securityBadge("Encrypted", .blue)
                }
                
                if config.hasTPMDevice {
                    securityBadge("TPM", .purple)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func securityBadge(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

/// VM Template Gallery
struct VMTemplateGallery: View {
    let onTemplateSelected: (QEMUVMConfigurationManager.VMTemplate) -> Void
    @Environment(\\.dismiss) private var dismiss
    @StateObject private var configManager = QEMUVMConfigurationManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(configManager.availableTemplates, id: \\.id) { template in
                        Button(action: {
                            onTemplateSelected(template)
                            dismiss()
                        }) {
                            VMTemplateCard(template: template) {
                                onTemplateSelected(template)
                                dismiss()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("VM Templates")
            .navigationBarTitleDisplayMode(.large)
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

/// VM Creation Wizard
struct VMCreationWizard: View {
    @Environment(\\.dismiss) private var dismiss
    @State private var selectedTemplate: QEMUVMConfigurationManager.VMTemplate?
    @State private var vmName = ""
    @State private var currentStep = 0
    
    var body: some View {
        NavigationView {
            VStack {
                // Progress indicator
                ProgressView(value: Double(currentStep), total: 3.0)
                    .padding()
                
                // Wizard content based on step
                Group {
                    switch currentStep {
                    case 0:
                        templateSelectionStep
                    case 1:
                        configurationStep
                    case 2:
                        confirmationStep
                    default:
                        EmptyView()
                    }
                }
                
                Spacer()
                
                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            currentStep -= 1
                        }
                    }
                    
                    Spacer()
                    
                    Button(currentStep == 2 ? "Create" : "Next") {
                        if currentStep == 2 {
                            createVM()
                        } else {
                            currentStep += 1
                        }
                    }
                    .disabled(currentStep == 0 && selectedTemplate == nil)
                    .disabled(currentStep == 1 && vmName.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Create Virtual Machine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // Wizard steps would be implemented here
    private var templateSelectionStep: some View {
        Text("Template Selection Step")
    }
    
    private var configurationStep: some View {
        Text("Configuration Step")
    }
    
    private var confirmationStep: some View {
        Text("Confirmation Step")
    }
    
    private func createVM() {
        // Create VM logic
        dismiss()
    }
}

#Preview {
    EnhancedVMManagementView()
}
