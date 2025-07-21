import SwiftUI

struct NetworkScannerView: View {
    @EnvironmentObject var securityToolkit: SecurityToolkitViewModel
    @State private var ipAddress = "192.168.1.1"
    @State private var startPort = "1"
    @State private var endPort = "1024"
    @State private var selectedDevice: NetworkDevice?
    @State private var isShowingDeviceDetail = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Network Scanner")
                    .font(.largeTitle)
                    .bold()
                
                // Network Scan Section
                VStack(alignment: .leading) {
                    Text("Network Discovery")
                        .font(.headline)
                    
                    Text("Scan your local network to discover connected devices")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        securityToolkit.startNetworkScan()
                    }) {
                        Text(securityToolkit.networkScanInProgress ? "Scanning..." : "Start Network Scan")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(securityToolkit.networkScanInProgress)
                    
                    if securityToolkit.networkScanInProgress {
                        ProgressView(value: securityToolkit.networkScanProgress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle())
                            .padding(.vertical)
                    }
                    
                    if let error = securityToolkit.networkScanError {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .padding(.vertical)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Device List Section
                VStack(alignment: .leading) {
                    Text("Discovered Devices (\(securityToolkit.networkDevices.count))")
                        .font(.headline)
                    
                    if securityToolkit.networkDevices.isEmpty && !securityToolkit.networkScanInProgress {
                        Text("No devices discovered yet")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                ForEach(securityToolkit.networkDevices) { device in
                                    DeviceRow(device: device)
                                        .onTapGesture {
                                            selectedDevice = device
                                            isShowingDeviceDetail = true
                                        }
                                }
                            }
                        }
                        .frame(maxHeight: 300)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Port Scan Section
                VStack(alignment: .leading) {
                    Text("Port Scanner")
                        .font(.headline)
                    
                    Text("Scan a specific IP address for open ports")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("IP Address", text: $ipAddress)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numbersAndPunctuation)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    HStack {
                        TextField("Start Port", text: $startPort)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                        
                        Text("to")
                        
                        TextField("End Port", text: $endPort)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    Button(action: {
                        guard let start = Int(startPort), let end = Int(endPort) else { return }
                        securityToolkit.scanPorts(ipAddress: ipAddress, startPort: start, endPort: end)
                    }) {
                        Text(securityToolkit.networkScanInProgress ? "Scanning..." : "Scan Ports")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(securityToolkit.networkScanInProgress)
                    
                    if securityToolkit.networkScanInProgress {
                        ProgressView(value: securityToolkit.networkScanProgress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle())
                            .padding(.vertical)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Open Ports Section
                VStack(alignment: .leading) {
                    Text("Open Ports (\(securityToolkit.openPorts.count))")
                        .font(.headline)
                    
                    if securityToolkit.openPorts.isEmpty && !securityToolkit.networkScanInProgress {
                        Text("No open ports discovered yet")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 8) {
                                ForEach(securityToolkit.openPorts) { port in
                                    PortRow(port: port)
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                Text("Note: Only use this tool on networks you own or have explicit permission to scan.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle("Network Scanner")
        .sheet(isPresented: $isShowingDeviceDetail) {
            if let device = selectedDevice {
                DeviceDetailView(device: device)
            }
        }
    }
}

struct DeviceRow: View {
    let device: NetworkDevice
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(device.hostName ?? "Unknown Device")
                    .font(.headline)
                
                Text(device.ipAddress)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let mac = device.macAddress {
                    Text("MAC: \(mac)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if device.isVulnerable {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .padding(.trailing, 4)
            }
            
            Text("\(device.services.count) service(s)")
                .font(.caption)
                .padding(6)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct PortRow: View {
    let port: OpenPort
    
    var body: some View {
        HStack {
            Text("Port \(port.port)")
                .font(.headline)
            
            if let service = port.serviceName {
                Text(service)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let banner = port.banner {
                Text(banner)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct DeviceDetailView: View {
    let device: NetworkDevice
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Device Info Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Device Information")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        InfoRow(label: "Hostname", value: device.hostName ?? "Unknown")
                        InfoRow(label: "IP Address", value: device.ipAddress)
                        
                        if let mac = device.macAddress {
                            InfoRow(label: "MAC Address", value: mac)
                        }
                        
                        InfoRow(label: "Security Status", value: device.isVulnerable ? "Potentially Vulnerable" : "No Known Vulnerabilities")
                            .foregroundColor(device.isVulnerable ? .red : .green)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Services Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Services (\(device.services.count))")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        ForEach(device.services, id: \.port) { service in
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text("\(service.serviceName) (Port \(service.port))")
                                        .font(.subheadline)
                                        .bold()
                                    
                                    Spacer()
                                    
                                    if service.isVulnerable {
                                        Label("Vulnerable", systemImage: "exclamationmark.triangle.fill")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                                
                                if let version = service.version {
                                    Text("Version: \(version)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle(device.hostName ?? "Device Details")
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct InfoRow: View {
    var label: String
    var value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .font(.subheadline)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

struct NetworkScannerView_Previews: PreviewProvider {
    static var previews: some View {
        NetworkScannerView()
            .environmentObject(SecurityToolkitViewModel())
    }
}
