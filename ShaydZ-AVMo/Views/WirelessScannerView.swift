import SwiftUI

struct WirelessScannerView: View {
    @EnvironmentObject var securityToolkit: SecurityToolkitViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Wireless Scanner")
                    .font(.largeTitle)
                    .bold()
                
                // Wireless Scan Section
                VStack(alignment: .leading) {
                    Text("WiFi Network Discovery")
                        .font(.headline)
                    
                    Text("Scan for nearby WiFi networks and analyze their security")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        securityToolkit.scanWirelessNetworks()
                    }) {
                        Text(securityToolkit.wirelessScanInProgress ? "Scanning..." : "Scan WiFi Networks")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(securityToolkit.wirelessScanInProgress)
                    
                    if securityToolkit.wirelessScanInProgress {
                        ProgressView(value: securityToolkit.wirelessScanProgress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle())
                            .padding(.vertical)
                    }
                    
                    if let error = securityToolkit.wirelessScanError {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .padding(.vertical)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // WiFi Networks Section
                VStack(alignment: .leading) {
                    Text("Available Networks (\(securityToolkit.wifiNetworks.count))")
                        .font(.headline)
                    
                    if securityToolkit.wifiNetworks.isEmpty && !securityToolkit.wirelessScanInProgress {
                        Text("No networks discovered yet")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                ForEach(securityToolkit.wifiNetworks) { network in
                                    WiFiNetworkRow(network: network)
                                        .onTapGesture {
                                            securityToolkit.analyzeNetworkSecurity(network: network)
                                        }
                                }
                            }
                        }
                        .frame(maxHeight: 400)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Network Security Analysis Section
                if let network = securityToolkit.selectedNetwork, let analysis = securityToolkit.networkSecurityAnalysis {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Security Analysis")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text(network.ssid)
                                .font(.subheadline)
                                .padding(6)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        // Security Score
                        HStack {
                            Text("Security Score:")
                                .font(.subheadline)
                                .bold()
                            
                            Spacer()
                            
                            SecurityScoreView(score: analysis.securityScore)
                        }
                        
                        // Vulnerabilities
                        Text("Vulnerabilities:")
                            .font(.subheadline)
                            .bold()
                        
                        ForEach(analysis.vulnerabilities, id: \.self) { vulnerability in
                            Text("• \(vulnerability)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Recommendations
                        Text("Recommendations:")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 5)
                        
                        ForEach(analysis.recommendations, id: \.self) { recommendation in
                            Text("• \(recommendation)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                
                Text("Note: Only use this tool on networks you own or have explicit permission to scan.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle("Wireless Scanner")
    }
}

struct WiFiNetworkRow: View {
    let network: WiFiNetwork
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(network.ssid)
                    .font(.headline)
                
                Text(network.bssid)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Label("Ch \(network.channel)", systemImage: "antenna.radiowaves.left.and.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    SecurityTypeView(type: network.securityType)
                    
                    StandardsView(standards: network.supportedStandards)
                }
            }
            
            Spacer()
            
            SignalStrengthView(strength: network.signalStrength)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct SecurityTypeView: View {
    let type: WiFiNetwork.SecurityType
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: securityIcon)
            Text(securityText)
        }
        .font(.caption)
        .foregroundColor(securityColor)
    }
    
    var securityIcon: String {
        switch type {
        case .open:
            return "lock.open.fill"
        case .wep:
            return "lock.open"
        case .wpa, .wpa2:
            return "lock.fill"
        case .wpa3:
            return "lock.shield.fill"
        case .enterprise:
            return "building.columns.fill"
        case .unknown:
            return "questionmark"
        }
    }
    
    var securityText: String {
        switch type {
        case .open:
            return "Open"
        case .wep:
            return "WEP"
        case .wpa:
            return "WPA"
        case .wpa2:
            return "WPA2"
        case .wpa3:
            return "WPA3"
        case .enterprise:
            return "Enterprise"
        case .unknown:
            return "Unknown"
        }
    }
    
    var securityColor: Color {
        switch type {
        case .open:
            return .red
        case .wep:
            return .orange
        case .wpa:
            return .yellow
        case .wpa2:
            return .blue
        case .wpa3, .enterprise:
            return .green
        case .unknown:
            return .gray
        }
    }
}

struct StandardsView: View {
    let standards: [WiFiNetwork.WiFiStandard]
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "wifi")
            Text(standardsText)
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
    
    var standardsText: String {
        let sortedStandards = standards.sorted { standard1, standard2 in
            let order: [WiFiNetwork.WiFiStandard] = [.ax, .ac, .n, .g, .a, .b]
            return order.firstIndex(of: standard1) ?? 999 < order.firstIndex(of: standard2) ?? 999
        }
        
        return sortedStandards.map { standard in
            switch standard {
            case .a:
                return "a"
            case .b:
                return "b"
            case .g:
                return "g"
            case .n:
                return "n"
            case .ac:
                return "ac"
            case .ax:
                return "ax"
            }
        }.joined(separator: "/")
    }
}

struct SignalStrengthView: View {
    let strength: Int
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: signalIcon)
            Text("\(strength) dBm")
        }
        .font(.caption)
        .foregroundColor(signalColor)
    }
    
    var signalIcon: String {
        if strength > -50 {
            return "wifi"
        } else if strength > -70 {
            return "wifi"
        } else {
            return "wifi.slash"
        }
    }
    
    var signalColor: Color {
        if strength > -50 {
            return .green
        } else if strength > -70 {
            return .yellow
        } else {
            return .orange
        }
    }
}

struct SecurityScoreView: View {
    let score: Int
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 8)
                .opacity(0.3)
                .foregroundColor(scoreColor)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(Double(score) / 100.0, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                .foregroundColor(scoreColor)
                .rotationEffect(Angle(degrees: 270.0))
            
            Text("\(score)")
                .font(.title2)
                .bold()
                .foregroundColor(scoreColor)
        }
        .frame(width: 60, height: 60)
    }
    
    var scoreColor: Color {
        if score >= 80 {
            return .green
        } else if score >= 50 {
            return .yellow
        } else {
            return .red
        }
    }
}

struct WirelessScannerView_Previews: PreviewProvider {
    static var previews: some View {
        WirelessScannerView()
            .environmentObject(SecurityToolkitViewModel())
    }
}
