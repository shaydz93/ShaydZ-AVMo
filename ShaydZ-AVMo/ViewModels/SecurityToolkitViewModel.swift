import Foundation
import Combine
import SwiftUI

// Main ViewModel used by all security toolkit views
// This class uses the model structures defined in SecurityModels.swift
class SecurityToolkitViewModel: ObservableObject {
    // Services
    private let networkScanner = NetworkScannerService.shared
    private let vulnerabilityScanner = VulnerabilityScanner.shared
    private let wirelessScanner = WirelessScanner.shared
    private let securityToolkitService = SecurityToolkitService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Network Scanner Properties
    @Published var networkDevices: [NetworkDevice] = []
    @Published var openPorts: [OpenPort] = []
    @Published var networkScanInProgress = false
    @Published var networkScanProgress: Double = 0.0
    @Published var networkScanError: String?
    
    // MARK: - Vulnerability Scanner Properties
    @Published var webVulnerabilities: [Vulnerability] = []
    @Published var serviceVulnerability: ServiceVulnerability?
    @Published var vulnerabilityScanInProgress = false
    @Published var vulnerabilityScanProgress: Double = 0.0
    @Published var vulnerabilityScanError: String?
    
    // MARK: - Wireless Scanner Properties
    @Published var wifiNetworks: [WiFiNetwork] = []
    @Published var selectedNetwork: WiFiNetwork?
    @Published var networkSecurityAnalysis: SecurityAnalysis?
    @Published var wirelessScanInProgress = false
    @Published var wirelessScanProgress: Double = 0.0
    @Published var wirelessScanError: String?
    
    // MARK: - Security Tools Properties
    @Published var passwordAnalysis: PasswordStrength?
    @Published var currentHash: String?
    @Published var hashAlgorithm: HashAlgorithm = .sha256
    @Published var phishingCampaign: PhishingCampaign?
    @Published var phishingAnalysis: PhishingIndicators?
    
    // MARK: - Tool Selection
    @Published var selectedTool: SecurityTool = .dashboard
    
    enum SecurityTool {
        case dashboard
        case networkScanner
        case vulnerabilityScanner
        case wirelessScanner
        case passwordTools
        case phishingSimulator
    }
    
    init() {
        // Set up subscribers for network scanner
        networkScanner.$isScanning
            .assign(to: &$networkScanInProgress)
        
        networkScanner.$scanProgress
            .assign(to: &$networkScanProgress)
        
        networkScanner.$error
            .assign(to: &$networkScanError)
        
        networkScanner.$discoveredDevices
            .assign(to: &$networkDevices)
        
        // Set up subscribers for vulnerability scanner
        vulnerabilityScanner.$isScanning
            .assign(to: &$vulnerabilityScanInProgress)
        
        vulnerabilityScanner.$scanProgress
            .assign(to: &$vulnerabilityScanProgress)
        
        vulnerabilityScanner.$error
            .assign(to: &$vulnerabilityScanError)
        
        // Set up subscribers for wireless scanner
        wirelessScanner.$isScanning
            .assign(to: &$wirelessScanInProgress)
        
        wirelessScanner.$scanProgress
            .assign(to: &$wirelessScanProgress)
        
        wirelessScanner.$error
            .assign(to: &$wirelessScanError)
        
        wirelessScanner.$discoveredNetworks
            .assign(to: &$wifiNetworks)
    }
    
    // MARK: - Network Scanner Methods
    
    func startNetworkScan() {
        networkScanner.scanLocalNetwork()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] devices in
                    self?.networkDevices = devices
                }
            )
            .store(in: &cancellables)
    }
    
    func scanPorts(ipAddress: String, startPort: Int = 1, endPort: Int = 1024) {
        let portRange = startPort..<(endPort + 1)
        
        networkScanner.portScan(ipAddress: ipAddress, portRange: portRange)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] ports in
                    self?.openPorts = ports
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Vulnerability Scanner Methods
    
    func scanWebApplication(urlString: String) {
        guard let url = URL(string: urlString) else {
            vulnerabilityScanError = "Invalid URL"
            return
        }
        
        vulnerabilityScanner.scanWebApplication(url: url)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] vulnerabilities in
                    self?.webVulnerabilities = vulnerabilities
                }
            )
            .store(in: &cancellables)
    }
    
    func scanNetworkService(host: String, port: Int) {
        vulnerabilityScanner.scanNetworkService(host: host, port: port)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] serviceVulnerability in
                    self?.serviceVulnerability = serviceVulnerability
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Wireless Scanner Methods
    
    func scanWirelessNetworks() {
        wirelessScanner.scanAvailableNetworks()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] networks in
                    self?.wifiNetworks = networks
                }
            )
            .store(in: &cancellables)
    }
    
    func analyzeNetworkSecurity(network: WiFiNetwork) {
        selectedNetwork = network
        networkSecurityAnalysis = wirelessScanner.analyzeWirelessSecurity(network: network)
    }
    
    // MARK: - Security Tools Methods
    
    func analyzePassword(password: String) {
        passwordAnalysis = securityToolkitService.analyzePasswordStrength(password: password)
    }
    
    func hashPassword(password: String) {
        currentHash = securityToolkitService.hashPassword(password: password, algorithm: hashAlgorithm)
    }
    
    func generatePhishingTemplate(type: String) {
        phishingCampaign = securityToolkitService.generatePhishingTemplate(type: type)
    }
    
    func analyzePhishingAttempt(email: String) {
        phishingAnalysis = securityToolkitService.analyzePhishingAttempt(email: email)
    }
}
