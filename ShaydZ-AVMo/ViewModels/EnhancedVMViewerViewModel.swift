import Foundation
import Combine
import UIKit

/// Enhanced VM Viewer ViewModel with UTM-inspired controls
class EnhancedVMViewerViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var statusMessage: String?
    @Published var errorMessage: String?
    @Published var showingVirtualKeyboard = false
    @Published var showingVolumeControls = false
    @Published var isConnected = false
    @Published var connectionLatency: Int = 0
    
    // MARK: - Private Properties
    private let vmService = UTMEnhancedVirtualMachineService.shared
    private let networkService = NetworkService.shared
    private var cancellables = Set<AnyCancellable>()
    private var latencyTimer: Timer?
    private var currentVMInstance: UTMEnhancedVirtualMachineService.VMInstance?
    
    // MARK: - Android Key Codes
    enum AndroidKey: Int {
        case back = 4
        case home = 3
        case recent = 187
        case menu = 82
        case volumeUp = 24
        case volumeDown = 25
        case power = 26
        case search = 84
        case camera = 27
        case call = 5
        case endCall = 6
    }
    
    // MARK: - Initialization
    init() {
        setupLatencyMonitoring()
    }
    
    deinit {
        latencyTimer?.invalidate()
    }
    
    // MARK: - Connection Management
    
    /// Connect to VM instance
    func connectToVM(_ instance: UTMEnhancedVirtualMachineService.VMInstance) {
        currentVMInstance = instance
        statusMessage = "Connecting to VM..."
        
        // Simulate connection process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.onDisplayConnected()
        }
    }
    
    /// Handle successful display connection
    func onDisplayConnected() {
        isConnected = true
        statusMessage = nil
        startLatencyMonitoring()
        
        // Log connection activity
        if let instance = currentVMInstance {
            Task {
                await logVMActivity(
                    instanceId: instance.id,
                    activity: "display_connected",
                    description: "Display connected to VM '\\(instance.config.name)'"
                )
            }
        }
    }
    
    /// Handle display connection error
    func onDisplayError(_ error: String) {
        isConnected = false
        errorMessage = "Display connection failed: \\(error)"
        statusMessage = nil
        stopLatencyMonitoring()
    }
    
    // MARK: - VM Control Operations
    
    /// Pause VM
    func pauseVM(_ instanceId: String) {
        statusMessage = "Pausing VM..."
        
        Task {
            do {
                try await vmService.pauseVM(instanceId: instanceId)
                
                DispatchQueue.main.async {
                    self.statusMessage = "VM paused"
                    
                    // Auto-hide status after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.statusMessage = nil
                    }
                }
                
                await logVMActivity(
                    instanceId: instanceId,
                    activity: "vm_paused",
                    description: "VM paused by user"
                )
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to pause VM: \\(error.localizedDescription)"
                    self.statusMessage = nil
                }
            }
        }
    }
    
    /// Resume VM
    func resumeVM(_ instanceId: String) {
        statusMessage = "Resuming VM..."
        
        Task {
            do {
                try await vmService.resumeVM(instanceId: instanceId)
                
                DispatchQueue.main.async {
                    self.statusMessage = "VM resumed"
                    
                    // Auto-hide status after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.statusMessage = nil
                    }
                }
                
                await logVMActivity(
                    instanceId: instanceId,
                    activity: "vm_resumed",
                    description: "VM resumed by user"
                )
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to resume VM: \\(error.localizedDescription)"
                    self.statusMessage = nil
                }
            }
        }
    }
    
    /// Reset VM
    func resetVM(_ instanceId: String) {
        statusMessage = "Resetting VM..."
        
        Task {
            do {
                // Stop and restart VM
                try await vmService.stopVM(instanceId: instanceId)
                
                // Wait a moment
                try await Task.sleep(nanoseconds: 2_000_000_000)
                
                // Launch again with same configuration
                if let instance = currentVMInstance {
                    _ = try await vmService.launchEnhancedVM(configId: instance.config.id)
                }
                
                DispatchQueue.main.async {
                    self.statusMessage = "VM reset complete"
                    
                    // Auto-hide status after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.statusMessage = nil
                    }
                }
                
                await logVMActivity(
                    instanceId: instanceId,
                    activity: "vm_reset",
                    description: "VM reset by user"
                )
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to reset VM: \\(error.localizedDescription)"
                    self.statusMessage = nil
                }
            }
        }
    }
    
    // MARK: - Screenshot & Snapshot Operations
    
    /// Take screenshot
    func takeScreenshot(_ instanceId: String) {
        statusMessage = "Taking screenshot..."
        
        Task {
            do {
                // Simulate screenshot capture
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                let screenshotId = UUID().uuidString
                let filename = "screenshot_\\(Date().timeIntervalSince1970).png"
                
                DispatchQueue.main.async {
                    self.statusMessage = "Screenshot saved as \\(filename)"
                    
                    // Auto-hide status after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.statusMessage = nil
                    }
                }
                
                await logVMActivity(
                    instanceId: instanceId,
                    activity: "screenshot_taken",
                    description: "Screenshot captured: \\(filename)"
                )
                
                // Save screenshot metadata to Supabase
                await saveScreenshotMetadata(
                    instanceId: instanceId,
                    screenshotId: screenshotId,
                    filename: filename
                )
                
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to take screenshot: \\(error.localizedDescription)"
                    self.statusMessage = nil
                }
            }
        }
    }
    
    /// Take VM snapshot
    func takeSnapshot(_ instanceId: String) {
        statusMessage = "Creating snapshot..."
        
        Task {
            do {
                let snapshotName = "Snapshot_\\(DateFormatter.snapshotFormatter.string(from: Date()))"
                let snapshotId = try await vmService.takeSnapshot(instanceId: instanceId, name: snapshotName)
                
                DispatchQueue.main.async {
                    self.statusMessage = "Snapshot '\\(snapshotName)' created"
                    
                    // Auto-hide status after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.statusMessage = nil
                    }
                }
                
                await logVMActivity(
                    instanceId: instanceId,
                    activity: "snapshot_created",
                    description: "Snapshot created: \\(snapshotName)"
                )
                
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to create snapshot: \\(error.localizedDescription)"
                    self.statusMessage = nil
                }
            }
        }
    }
    
    // MARK: - Input Handling
    
    /// Send Android key input
    func sendAndroidKey(_ key: AndroidKey) {
        guard isConnected else { return }
        
        statusMessage = "Sending \\(getKeyName(key)) key"
        
        Task {
            // Simulate sending key to Android VM
            await sendKeyToVM(keyCode: key.rawValue)
            
            DispatchQueue.main.async {
                self.statusMessage = nil
            }
        }
    }
    
    /// Toggle virtual keyboard
    func toggleVirtualKeyboard() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingVirtualKeyboard.toggle()
        }
    }
    
    /// Send key input from virtual keyboard
    func sendKeyInput(_ key: String) {
        guard isConnected else { return }
        
        Task {
            let keyCode = mapKeyToAndroidCode(key)
            await sendKeyToVM(keyCode: keyCode)
        }
    }
    
    /// Show volume controls
    func showVolumeControls() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingVolumeControls.toggle()
        }
        
        // Auto-hide after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.showingVolumeControls = false
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Send key to VM
    private func sendKeyToVM(keyCode: Int) async {
        // Simulate sending key command to QEMU monitor
        // In real implementation, this would send commands via QEMU monitor socket
        
        let command = "sendkey \\(keyCode)"
        print("Sending QEMU command: \\(command)")
        
        // Simulate latency
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
    }
    
    /// Map keyboard key to Android key code
    private func mapKeyToAndroidCode(_ key: String) -> Int {
        switch key.uppercased() {
        case "A"..."Z":
            let asciiValue = key.uppercased().unicodeScalars.first?.value ?? 0
            return Int(asciiValue - 65 + 29) // KEYCODE_A = 29
        case "0"..."9":
            let asciiValue = key.unicodeScalars.first?.value ?? 0
            return Int(asciiValue - 48 + 7) // KEYCODE_0 = 7
        case "SPACE":
            return 62 // KEYCODE_SPACE
        case "RETURN", "ENTER":
            return 66 // KEYCODE_ENTER
        case "⌫", "BACKSPACE":
            return 67 // KEYCODE_DEL
        case "⇧", "SHIFT":
            return 59 // KEYCODE_SHIFT_LEFT
        case "123":
            return 82 // KEYCODE_MENU (for number mode)
        default:
            return 0 // KEYCODE_UNKNOWN
        }
    }
    
    /// Get key name for display
    private func getKeyName(_ key: AndroidKey) -> String {
        switch key {
        case .back:
            return "Back"
        case .home:
            return "Home"
        case .recent:
            return "Recent Apps"
        case .menu:
            return "Menu"
        case .volumeUp:
            return "Volume Up"
        case .volumeDown:
            return "Volume Down"
        case .power:
            return "Power"
        case .search:
            return "Search"
        case .camera:
            return "Camera"
        case .call:
            return "Call"
        case .endCall:
            return "End Call"
        }
    }
    
    // MARK: - Latency Monitoring
    
    /// Setup latency monitoring
    private func setupLatencyMonitoring() {
        // Monitor latency every 5 seconds
        latencyTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.measureLatency()
        }
    }
    
    /// Start latency monitoring
    private func startLatencyMonitoring() {
        latencyTimer?.fire()
    }
    
    /// Stop latency monitoring
    private func stopLatencyMonitoring() {
        latencyTimer?.invalidate()
        latencyTimer = nil
    }
    
    /// Measure connection latency
    private func measureLatency() {
        guard isConnected else { return }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        Task {
            // Simulate ping to VM
            try? await Task.sleep(nanoseconds: UInt64.random(in: 20_000_000...100_000_000)) // 20-100ms
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let latency = Int((endTime - startTime) * 1000) // Convert to milliseconds
            
            DispatchQueue.main.async {
                self.connectionLatency = latency
            }
        }
    }
    
    // MARK: - Data Persistence
    
    /// Save screenshot metadata
    private func saveScreenshotMetadata(instanceId: String, screenshotId: String, filename: String) async {
        guard let userId = SupabaseAuthService.shared.currentUser?.id else { return }
        
        do {
            let activity = UserActivity(
                id: screenshotId,
                userId: userId,
                activityType: "screenshot",
                description: "Screenshot captured from VM",
                metadata: [
                    "vm_instance_id": instanceId,
                    "filename": filename,
                    "timestamp": ISO8601DateFormatter().string(from: Date())
                ],
                createdAt: ISO8601DateFormatter().string(from: Date())
            )
            
            _ = try await SupabaseDatabaseService.shared.logActivity(userId: userId, activity: activity)
        } catch {
            print("Failed to save screenshot metadata: \\(error)")
        }
    }
    
    /// Log VM activity
    private func logVMActivity(instanceId: String, activity: String, description: String) async {
        guard let userId = SupabaseAuthService.shared.currentUser?.id else { return }
        
        do {
            let activityLog = UserActivity(
                id: UUID().uuidString,
                userId: userId,
                activityType: activity,
                description: description,
                metadata: [
                    "vm_instance_id": instanceId,
                    "timestamp": ISO8601DateFormatter().string(from: Date())
                ],
                createdAt: ISO8601DateFormatter().string(from: Date())
            )
            
            _ = try await SupabaseDatabaseService.shared.logActivity(userId: userId, activity: activityLog)
        } catch {
            print("Failed to log VM activity: \\(error)")
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let snapshotFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}
