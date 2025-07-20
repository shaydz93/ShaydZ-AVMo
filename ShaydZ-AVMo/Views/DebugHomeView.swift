import SwiftUI

struct DebugHomeView: View {
    @State private var selectedTab: Int = 0
    @State private var vmStatus = "Ready"
    @State private var isVMRunning = false
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // VM Management Tab
                VStack(spacing: 20) {
                    Text("🚀 ShaydZ-AVMo Debug Mode")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("UTM-Enhanced Virtual Machine")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    // VM Status
                    VStack {
                        HStack {
                            Circle()
                                .fill(isVMRunning ? Color.green : Color.red)
                                .frame(width: 12, height: 12)
                            Text("Status: \(vmStatus)")
                                .font(.headline)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        
                        // VM Controls
                        HStack(spacing: 20) {
                            Button(action: startVM) {
                                Text(isVMRunning ? "Stop VM" : "Start VM")
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(isVMRunning ? Color.red : Color.green)
                                    .cornerRadius(8)
                            }
                            
                            Button(action: resetVM) {
                                Text("Reset")
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.orange)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Debug VM Viewer
                    VStack {
                        Text("Virtual Android Environment")
                            .font(.headline)
                            .padding(.bottom)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black)
                                .frame(height: 400)
                            
                            if isVMRunning {
                                VStack {
                                    Text("🤖")
                                        .font(.system(size: 60))
                                    Text("Android VM Running")
                                        .foregroundColor(.green)
                                        .font(.title3)
                                    Text("UTM-Enhanced QEMU Backend")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                            } else {
                                VStack {
                                    Image(systemName: "display.trianglebadge.exclamationmark")
                                        .font(.system(size: 60))
                                        .foregroundColor(.gray)
                                    Text("VM Stopped")
                                        .foregroundColor(.gray)
                                        .font(.title3)
                                }
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    Spacer()
                }
                .padding()
                .tabItem {
                    Image(systemName: "display")
                    Text("VM Control")
                }
                .tag(0)
                
                // Features Tab
                VStack(spacing: 20) {
                    Text("✨ UTM Features")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            FeatureCard(
                                icon: "cpu",
                                title: "QEMU Virtualization",
                                description: "Multi-architecture VM support (ARM64, x86_64, RISC-V)"
                            )
                            
                            FeatureCard(
                                icon: "shield.fill",
                                title: "Enterprise Security",
                                description: "TPM 2.0, UEFI Secure Boot, Disk Encryption"
                            )
                            
                            FeatureCard(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Performance Monitoring",
                                description: "Real-time CPU, memory, and network metrics"
                            )
                            
                            FeatureCard(
                                icon: "network",
                                title: "SPICE Protocol",
                                description: "High-performance VM display with touch input"
                            )
                            
                            FeatureCard(
                                icon: "externaldrive.fill",
                                title: "Storage Management",
                                description: "Dynamic disk allocation and snapshot support"
                            )
                            
                            FeatureCard(
                                icon: "app.badge",
                                title: "App Virtualization",
                                description: "Enterprise Android app catalog integration"
                            )
                        }
                    }
                }
                .padding()
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("Features")
                }
                .tag(1)
                
                // Debug Info Tab
                VStack(spacing: 20) {
                    Text("🛠️ Debug Info")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        DebugInfoRow(label: "Mode", value: "Development")
                        DebugInfoRow(label: "Authentication", value: "Disabled")
                        DebugInfoRow(label: "Backend", value: "Mock Services")
                        DebugInfoRow(label: "VM Engine", value: "UTM-Enhanced QEMU")
                        DebugInfoRow(label: "Security", value: "TPM 2.0 + Secure Boot")
                        DebugInfoRow(label: "Display", value: "SPICE Protocol")
                        DebugInfoRow(label: "Architecture", value: "ARM64/x86_64")
                        DebugInfoRow(label: "Network", value: "Isolated Bridge")
                        DebugInfoRow(label: "Storage", value: "qcow2 with CoW")
                        DebugInfoRow(label: "Platform", value: "iOS 15.0+")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
                .tabItem {
                    Image(systemName: "info.circle")
                    Text("Debug")
                }
                .tag(2)
            }
            .navigationTitle("ShaydZ-AVMo")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func startVM() {
        withAnimation {
            isVMRunning.toggle()
            vmStatus = isVMRunning ? "Running (UTM-QEMU)" : "Stopped"
        }
    }
    
    private func resetVM() {
        withAnimation {
            isVMRunning = false
            vmStatus = "Reset Complete"
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            vmStatus = "Ready"
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct DebugInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .fontWeight(.medium)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

struct DebugHomeView_Previews: PreviewProvider {
    static var previews: some View {
        DebugHomeView()
    }
}
