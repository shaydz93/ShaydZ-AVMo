import SwiftUI

struct ContentView: View {
    @EnvironmentObject var securityToolkit: SecurityToolkitViewModel
    
    var body: some View {
        NavigationView {
            sidebar
            
            // Default view when app starts
            SecurityDashboardView()
                .navigationTitle("Security Toolkit")
        }
    }
    
    var sidebar: some View {
        List {
            NavigationLink(
                destination: SecurityDashboardView(),
                tag: SecurityToolkitViewModel.SecurityTool.dashboard,
                selection: $securityToolkit.selectedTool
            ) {
                Label("Dashboard", systemImage: "square.grid.2x2")
            }
            
            Section(header: Text("Reconnaissance")) {
                NavigationLink(
                    destination: NetworkScannerView(),
                    tag: SecurityToolkitViewModel.SecurityTool.networkScanner,
                    selection: $securityToolkit.selectedTool
                ) {
                    Label("Network Scanner", systemImage: "network")
                }
                
                NavigationLink(
                    destination: WirelessScannerView(),
                    tag: SecurityToolkitViewModel.SecurityTool.wirelessScanner,
                    selection: $securityToolkit.selectedTool
                ) {
                    Label("Wireless Scanner", systemImage: "wifi")
                }
            }
            
            Section(header: Text("Security Testing")) {
                NavigationLink(
                    destination: VulnerabilityScannerView(),
                    tag: SecurityToolkitViewModel.SecurityTool.vulnerabilityScanner,
                    selection: $securityToolkit.selectedTool
                ) {
                    Label("Vulnerability Scanner", systemImage: "shield.lefthalf.fill")
                }
            }
            
            Section(header: Text("Utilities")) {
                NavigationLink(
                    destination: PasswordToolsView(),
                    tag: SecurityToolkitViewModel.SecurityTool.passwordTools,
                    selection: $securityToolkit.selectedTool
                ) {
                    Label("Password Tools", systemImage: "key.fill")
                }
                
                NavigationLink(
                    destination: PhishingSimulatorView(),
                    tag: SecurityToolkitViewModel.SecurityTool.phishingSimulator,
                    selection: $securityToolkit.selectedTool
                ) {
                    Label("Phishing Simulator", systemImage: "envelope.badge.shield.half.filled")
                }
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Security Toolkit")
    }
}

// MARK: - Dashboard View

struct SecurityDashboardView: View {
    @EnvironmentObject var securityToolkit: SecurityToolkitViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Security Toolkit Dashboard")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 10)
                
                Text("Welcome to the ShaydZ AVMo Security Toolkit")
                    .font(.headline)
                
                Text("This toolkit provides security professionals with a comprehensive set of tools for network reconnaissance, vulnerability scanning, and security testing. All tools operate within the app's sandbox and don't store any data on the device.")
                    .padding(.bottom, 10)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 20) {
                    ToolCard(
                        title: "Network Scanner",
                        description: "Discover devices on your network",
                        systemImage: "network",
                        color: .blue,
                        action: { securityToolkit.selectedTool = .networkScanner }
                    )
                    
                    ToolCard(
                        title: "Wireless Scanner",
                        description: "Analyze WiFi networks and security",
                        systemImage: "wifi",
                        color: .green,
                        action: { securityToolkit.selectedTool = .wirelessScanner }
                    )
                    
                    ToolCard(
                        title: "Vulnerability Scanner",
                        description: "Identify security vulnerabilities",
                        systemImage: "shield.lefthalf.fill",
                        color: .red,
                        action: { securityToolkit.selectedTool = .vulnerabilityScanner }
                    )
                    
                    ToolCard(
                        title: "Password Tools",
                        description: "Analyze and hash passwords",
                        systemImage: "key.fill",
                        color: .purple,
                        action: { securityToolkit.selectedTool = .passwordTools }
                    )
                    
                    ToolCard(
                        title: "Phishing Simulator",
                        description: "Generate and analyze phishing attempts",
                        systemImage: "envelope.badge.shield.half.filled",
                        color: .orange,
                        action: { securityToolkit.selectedTool = .phishingSimulator }
                    )
                }
                .padding(.bottom, 20)
                
                Text("Note: This toolkit is designed for security professionals and ethical hackers. Always ensure you have proper authorization before scanning networks or testing for vulnerabilities.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

// MARK: - Tool Card Component

struct ToolCard: View {
    var title: String
    var description: String
    var systemImage: String
    var color: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.largeTitle)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Spacer()
            }
            .frame(height: 140)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(SecurityToolkitViewModel())
    }
}
