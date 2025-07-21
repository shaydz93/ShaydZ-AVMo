import Foundation
import Combine
import CoreLocation
import Network

// MARK: - Model Structures
// Using consolidated models from SecurityModels.swift

struct WiFiNetwork: Identifiable {
    let id = UUID()
    let ssid: String
    let bssid: String
    let signalStrength: Int // dBm value
    let securityType: SecurityType
    let channel: Int
    let frequency: Int // MHz
    
    enum SecurityType: String, CaseIterable {
        case open = "Open"
        case wep = "WEP"
        case wpa = "WPA"
        case wpa2 = "WPA2"
        case wpa3 = "WPA3"
    }
    
    var securityRating: Int {
        switch securityType {
        case .open: return 1
        case .wep: return 2
        case .wpa: return 3
        case .wpa2: return 4
        case .wpa3: return 5
        }
    }
}

struct Vulnerability: Identifiable {
    let id = UUID()
    let name: String
    let severity: Severity
    let description: String
    let remediation: String
    let cveId: String?
    
    enum Severity: String, CaseIterable {
        case critical = "Critical"
        case high = "High"
        case medium = "Medium"
        case low = "Low"
        case info = "Info"
        
        var color: String {
            switch self {
            case .critical: return "red"
            case .high: return "orange"
            case .medium: return "yellow"
            case .low: return "blue"
            case .info: return "gray"
            }
        }
    }
}

struct PasswordAudit: Identifiable {
    let id = UUID()
    let password: String
    let strength: Int // 1-5 rating
    let timeToBreak: String
    let issues: [String]
    let suggestions: [String]
}

struct PhishingTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let targetPlatform: String
    let htmlContent: String
}

// MARK: - Security Toolkit Model

class SecurityToolkitModel: ObservableObject {
    // Tool selection
    enum SecurityTool {
        case dashboard
        case networkScanner
        case wirelessScanner
        case vulnerabilityScanner
        case passwordTools
        case phishingSimulator
    }
    
    @Published var selectedTool: SecurityTool = .dashboard
    
    // Network scanning
    @Published var discoveredDevices: [NetworkDevice] = []
    @Published var networkScanInProgress = false
    @Published var scanProgress: Float = 0
    @Published var scanLog: [String] = []
    
    // Wireless scanning
    @Published var discoveredNetworks: [WiFiNetwork] = []
    @Published var wirelessScanInProgress = false
    
    // Vulnerability scanning
    @Published var vulnerabilityResults: [Vulnerability] = []
    @Published var vulnerabilityScanInProgress = false
    
    // Password tools
    @Published var passwordAuditResults: [PasswordAudit] = []
    @Published var generatedPasswords: [String] = []
    
    // Phishing simulation
    @Published var phishingTemplates: [PhishingTemplate] = []
    
    // Services
    private let networkScanner = NetworkScannerService()
    private let wirelessScanner = WirelessScannerService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSampleData()
    }
    
    // MARK: - Network Scanning Methods
    
    func startNetworkScan() {
        networkScanInProgress = true
        scanProgress = 0
        scanLog.append("Starting network scan...")
        
        networkScanner.scanNetwork()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                
                switch completion {
                case .finished:
                    self.scanLog.append("Network scan completed")
                    self.networkScanInProgress = false
                    self.scanProgress = 1.0
                case .failure(let error):
                    self.scanLog.append("Scan error: \(error.localizedDescription)")
                    self.networkScanInProgress = false
                }
            } receiveValue: { [weak self] devices in
                guard let self = self else { return }
                
                self.discoveredDevices = devices
                self.scanLog.append("Found \(devices.count) devices")
                
                // Update progress for UI feedback
                let progressIncrement = 1.0 / Float(max(1, devices.count))
                self.scanProgress += progressIncrement
            }
            .store(in: &cancellables)
    }
    
    func scanPorts(for device: NetworkDevice, startPort: Int, endPort: Int) {
        if let index = discoveredDevices.firstIndex(where: { $0.id == device.id }) {
            scanLog.append("Starting port scan on \(device.ipAddress)...")
            
            networkScanner.scanPorts(ipAddress: device.ipAddress, startPort: startPort, endPort: endPort)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] completion in
                    guard let self = self else { return }
                    
                    switch completion {
                    case .finished:
                        self.scanLog.append("Port scan completed")
                    case .failure(let error):
                        self.scanLog.append("Port scan error: \(error.localizedDescription)")
                    }
                } receiveValue: { [weak self] openPorts in
                    guard let self = self else { return }
                    
                    var updatedDevice = self.discoveredDevices[index]
                    updatedDevice.openPorts = openPorts
                    
                    // Add service names for common ports
                    for port in openPorts {
                        if let serviceName = self.getServiceName(for: port) {
                            updatedDevice.services[String(port)] = serviceName
                        }
                    }
                    
                    self.discoveredDevices[index] = updatedDevice
                    self.scanLog.append("Found \(openPorts.count) open ports")
                }
                .store(in: &cancellables)
        }
    }
    
    private func getServiceName(for port: Int) -> String? {
        let commonPorts: [Int: String] = [
            21: "FTP",
            22: "SSH",
            23: "Telnet",
            25: "SMTP",
            53: "DNS",
            80: "HTTP",
            110: "POP3",
            123: "NTP",
            143: "IMAP",
            443: "HTTPS",
            445: "SMB",
            3306: "MySQL",
            3389: "RDP",
            5432: "PostgreSQL",
            8080: "HTTP-Alt"
        ]
        
        return commonPorts[port]
    }
    
    // MARK: - Wireless Scanning Methods
    
    func scanWirelessNetworks() {
        wirelessScanInProgress = true
        
        wirelessScanner.scanWirelessNetworks()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                
                switch completion {
                case .finished:
                    self.scanLog.append("Wireless scan completed")
                    self.wirelessScanInProgress = false
                case .failure(let error):
                    self.scanLog.append("Wireless scan error: \(error.localizedDescription)")
                    self.wirelessScanInProgress = false
                }
            } receiveValue: { [weak self] networks in
                guard let self = self else { return }
                
                self.discoveredNetworks = networks
                self.scanLog.append("Found \(networks.count) wireless networks")
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Vulnerability Scanning Methods
    
    func scanForVulnerabilities(device: NetworkDevice) {
        vulnerabilityScanInProgress = true
        
        // In a real app, this would call a vulnerability scanner service
        // Here we're simulating with sample vulnerabilities
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            
            let sampleVulnerabilities = self.getSampleVulnerabilities(for: device)
            
            if let index = self.discoveredDevices.firstIndex(where: { $0.id == device.id }) {
                var updatedDevice = self.discoveredDevices[index]
                updatedDevice.vulnerabilities = sampleVulnerabilities
                self.discoveredDevices[index] = updatedDevice
            }
            
            self.vulnerabilityResults = sampleVulnerabilities
            self.vulnerabilityScanInProgress = false
        }
    }
    
    // MARK: - Password Tools Methods
    
    func auditPassword(_ password: String) -> PasswordAudit {
        var strength = 0
        var issues: [String] = []
        var suggestions: [String] = []
        
        // Check length
        if password.count < 8 {
            issues.append("Password is too short")
            suggestions.append("Use at least 8 characters")
        } else {
            strength += 1
        }
        
        // Check for uppercase
        if password.range(of: "[A-Z]", options: .regularExpression) != nil {
            strength += 1
        } else {
            issues.append("No uppercase letters")
            suggestions.append("Add uppercase letters (A-Z)")
        }
        
        // Check for lowercase
        if password.range(of: "[a-z]", options: .regularExpression) != nil {
            strength += 1
        } else {
            issues.append("No lowercase letters")
            suggestions.append("Add lowercase letters (a-z)")
        }
        
        // Check for numbers
        if password.range(of: "[0-9]", options: .regularExpression) != nil {
            strength += 1
        } else {
            issues.append("No numbers")
            suggestions.append("Add numbers (0-9)")
        }
        
        // Check for special characters
        if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil {
            strength += 1
        } else {
            issues.append("No special characters")
            suggestions.append("Add special characters (e.g., !@#$%)")
        }
        
        // Estimate time to break based on strength
        let timeToBreak: String
        switch strength {
        case 1:
            timeToBreak = "Seconds"
        case 2:
            timeToBreak = "Hours"
        case 3:
            timeToBreak = "Days"
        case 4:
            timeToBreak = "Years"
        case 5:
            timeToBreak = "Centuries"
        default:
            timeToBreak = "Instantly"
        }
        
        return PasswordAudit(
            id: UUID(),
            password: password,
            strength: strength,
            timeToBreak: timeToBreak,
            issues: issues,
            suggestions: suggestions
        )
    }
    
    func generateSecurePassword(length: Int = 16) -> String {
        let uppercaseLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let lowercaseLetters = "abcdefghijklmnopqrstuvwxyz"
        let numbers = "0123456789"
        let specialCharacters = "!@#$%^&*()-_=+[]{}|;:,.<>?/"
        
        let allCharacters = uppercaseLetters + lowercaseLetters + numbers + specialCharacters
        
        var password = ""
        
        // Ensure at least one character from each category
        password.append(uppercaseLetters.randomElement()!)
        password.append(lowercaseLetters.randomElement()!)
        password.append(numbers.randomElement()!)
        password.append(specialCharacters.randomElement()!)
        
        // Fill the rest with random characters
        for _ in 0..<(length - 4) {
            password.append(allCharacters.randomElement()!)
        }
        
        // Shuffle the password to mix the guaranteed characters
        return String(password.shuffled())
    }
    
    // MARK: - Helper Methods
    
    private func setupSampleData() {
        // Set up some sample data for UI testing
        
        /* 
        // Sample network devices (OLD format, no longer used - use SecurityToolkitViewModel instead)
        discoveredDevices = [
            NetworkDevice(
                ipAddress: "192.168.1.1",
                hostName: "router.local", // updated to use consistent property name
                macAddress: "AA:BB:CC:DD:EE:FF",
                openPorts: [80, 443, 22],
                services: ["80": "HTTP", "443": "HTTPS", "22": "SSH"]
            ),
            NetworkDevice(
                ipAddress: "192.168.1.2",
                hostName: "desktop.local", // updated to use consistent property name
                macAddress: "11:22:33:44:55:66",
                openPorts: [3389],
                services: ["3389": "RDP"]
            )
        ]
        */
        
        // Sample WiFi networks
        discoveredNetworks = [
            WiFiNetwork(
                ssid: "HomeNetwork",
                bssid: "AA:BB:CC:DD:EE:FF",
                signalStrength: -65,
                securityType: .wpa2,
                channel: 6,
                frequency: 2437
            ),
            WiFiNetwork(
                ssid: "GuestNetwork",
                bssid: "AA:BB:CC:DD:EE:00",
                signalStrength: -70,
                securityType: .wpa,
                channel: 11,
                frequency: 2462
            ),
            WiFiNetwork(
                ssid: "PublicWiFi",
                bssid: "AA:BB:CC:00:00:00",
                signalStrength: -80,
                securityType: .open,
                channel: 1,
                frequency: 2412
            )
        ]
        
        // Sample phishing templates
        phishingTemplates = [
            PhishingTemplate(
                id: UUID(),
                name: "Generic Login",
                description: "Basic credential harvesting template",
                targetPlatform: "Any",
                htmlContent: "<!DOCTYPE html><html><head><title>Login</title></head><body><h1>Login</h1><form><input type='email' placeholder='Email'><input type='password' placeholder='Password'><button>Login</button></form></body></html>"
            ),
            PhishingTemplate(
                id: UUID(),
                name: "Corporate Email",
                description: "Corporate email template for security awareness",
                targetPlatform: "Email Clients",
                htmlContent: "<!DOCTYPE html><html><head><title>IT Security Alert</title></head><body><h1>Security Alert</h1><p>Your account requires verification. Please click the link below to verify your credentials.</p><a href='#'>Verify Now</a></body></html>"
            )
        ]
    }
    
    private func getSampleVulnerabilities(for device: NetworkDevice) -> [Vulnerability] {
        var vulnerabilities: [Vulnerability] = []
        
        // Check for common vulnerabilities based on open ports
        if device.openPorts.contains(22) {
            vulnerabilities.append(
                Vulnerability(
                    id: UUID(),
                    name: "SSH Weak Configuration",
                    severity: .medium,
                    description: "The SSH service is using outdated configuration options that may allow attackers to compromise the service.",
                    remediation: "Update SSH to the latest version and disable deprecated algorithms and protocols.",
                    cveId: "CVE-2020-14145"
                )
            )
        }
        
        if device.openPorts.contains(80) && !device.openPorts.contains(443) {
            vulnerabilities.append(
                Vulnerability(
                    id: UUID(),
                    name: "HTTP Service Without TLS",
                    severity: .medium,
                    description: "The web server is running without TLS encryption, which could allow attackers to intercept traffic.",
                    remediation: "Configure HTTPS with a valid SSL/TLS certificate.",
                    cveId: nil
                )
            )
        }
        
        if device.ipAddress == "192.168.1.1" {
            vulnerabilities.append(
                Vulnerability(
                    id: UUID(),
                    name: "Default Router Credentials",
                    severity: .critical,
                    description: "The router may be using default credentials which could allow unauthorized access.",
                    remediation: "Change the default admin password to a strong, unique password.",
                    cveId: nil
                )
            )
        }
        
        // Add some random vulnerabilities for demonstration
        if Int.random(in: 0...1) == 1 {
            vulnerabilities.append(
                Vulnerability(
                    id: UUID(),
                    name: "Open SNMP Service",
                    severity: .low,
                    description: "SNMP service is exposed and could reveal system information.",
                    remediation: "Restrict SNMP access or disable if not needed.",
                    cveId: nil
                )
            )
        }
        
        return vulnerabilities
    }
}
