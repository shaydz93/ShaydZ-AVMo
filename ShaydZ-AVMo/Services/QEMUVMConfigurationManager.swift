import Foundation
import Combine

/// QEMU-based VM Configuration Manager inspired by UTM
class QEMUVMConfigurationManager: ObservableObject {
    static let shared = QEMUVMConfigurationManager()
    
    @Published var availableTemplates: [VMTemplate] = []
    @Published var customConfigurations: [UTMEnhancedVMConfig] = []
    @Published var isValidating = false
    
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    private var cancellables = Set<AnyCancellable>()
    
    /// VM Template for quick setup
    struct VMTemplate {
        let id: String
        let name: String
        let description: String
        let architecture: QEMUArchitecture
        let osType: OSType
        let iconName: String
        let requiredMemoryMB: Int
        let requiredStorageGB: Int
        let features: [VMFeature]
        let configuration: UTMEnhancedVMConfig
        
        enum OSType: String, CaseIterable {
            case android = "Android"
            case linux = "Linux"
            case windows = "Windows"
            case macos = "macOS"
            case custom = "Custom"
            
            var defaultArchitecture: QEMUArchitecture {
                switch self {
                case .android:
                    return .aarch64
                case .linux:
                    return .x86_64
                case .windows:
                    return .x86_64
                case .macos:
                    return .aarch64
                case .custom:
                    return .x86_64
                }
            }
        }
        
        enum VMFeature: String, CaseIterable {
            case hypervisor = "Hypervisor Support"
            case gpu = "GPU Acceleration"
            case tpm = "TPM Security"
            case uefi = "UEFI Boot"
            case networking = "Advanced Networking"
            case sharing = "File Sharing"
            case clipboard = "Clipboard Sync"
            case audio = "Audio Support"
            case usb = "USB Passthrough"
            case snapshot = "Snapshot Support"
        }
    }
    
    /// QEMU Command Builder
    struct QEMUCommandBuilder {
        let config: UTMEnhancedVMConfig
        
        /// Generate QEMU command line arguments
        func buildCommand() -> [String] {
            var args: [String] = []
            
            // Basic system configuration
            args.append(contentsOf: [
                "-machine", config.target,
                "-cpu", getCPUModel(),
                "-smp", "cpus=\(config.cpuCount)",
                "-m", "\(config.memorySize)M"
            ])
            
            // Enable hypervisor if supported
            if config.hasHypervisor {
                #if arch(arm64)
                args.append(contentsOf: ["-accel", "hvf"])
                #elseif arch(x86_64)
                args.append(contentsOf: ["-accel", "hvf,whpx,tcg"])
                #else
                args.append(contentsOf: ["-accel", "tcg"])
                #endif
            }
            
            // UEFI boot configuration
            if config.hasUefiBoot {
                args.append(contentsOf: [
                    "-drive", "if=pflash,format=raw,readonly=on,file=\(getUEFIPath())"
                ])
            }
            
            // TPM device
            if config.hasTPMDevice {
                args.append(contentsOf: [
                    "-tpmdev", "emulator,id=tpm0,chardev=chrtpm",
                    "-chardev", "socket,id=chrtpm,path=/tmp/tpm-sock",
                    "-device", "tpm-tis,tpmdev=tpm0"
                ])
            }
            
            // RNG device for entropy
            if config.hasRNGDevice {
                args.append(contentsOf: [
                    "-object", "rng-random,id=rng0,filename=/dev/urandom",
                    "-device", "virtio-rng-pci,rng=rng0"
                ])
            }
            
            // Memory balloon
            if config.hasBalloonDevice {
                args.append(contentsOf: ["-device", "virtio-balloon-pci"])
            }
            
            // RTC configuration
            if config.hasRTCLocalTime {
                args.append(contentsOf: ["-rtc", "base=localtime,clock=host"])
            } else {
                args.append(contentsOf: ["-rtc", "base=utc,clock=host"])
            }
            
            // Display configuration
            for (index, display) in config.displays.enumerated() {
                if display.hasGLAcceleration {
                    args.append(contentsOf: [
                        "-device", "\(display.hardware),id=video\(index)",
                        "-display", "default,gl=on"
                    ])
                } else {
                    args.append(contentsOf: [
                        "-device", "\(display.hardware),id=video\(index)",
                        "-display", "default"
                    ])
                }
            }
            
            // Network configuration
            for (index, network) in config.networks.enumerated() {
                args.append(contentsOf: [
                    "-netdev", buildNetworkConfig(network, index: index),
                    "-device", "\(network.interface),netdev=net\(index)"
                ])
            }
            
            // Drive configuration
            for (index, drive) in config.drives.enumerated() {
                args.append(contentsOf: [
                    "-drive", buildDriveConfig(drive, index: index)
                ])
            }
            
            // Serial configuration
            for serial in config.serials {
                args.append(contentsOf: [
                    "-chardev", "stdio,id=\(serial.id)",
                    "-serial", "chardev:\(serial.id)"
                ])
            }
            
            // Sound configuration
            for sound in config.sound {
                if sound.isEnabled {
                    args.append(contentsOf: [
                        "-audiodev", "coreaudio,id=audio0",
                        "-device", "\(sound.hardware),audiodev=audio0"
                    ])
                }
            }
            
            // VNC server for remote access
            args.append(contentsOf: ["-vnc", ":0"])
            
            // Monitor interface
            args.append(contentsOf: [
                "-monitor", "unix:/tmp/qemu-monitor.sock,server=on,wait=off"
            ])
            
            // SPICE server for enhanced graphics
            args.append(contentsOf: [
                "-spice", "port=5930,addr=127.0.0.1,disable-ticketing=on,seamless-migration=on"
            ])
            
            return args
        }
        
        private func getCPUModel() -> String {
            switch config.architecture {
            case .aarch64:
                return "cortex-a72"
            case .arm:
                return "cortex-a15"
            case .x86_64:
                return "qemu64"
            case .i386:
                return "qemu32"
            default:
                return "max"
            }
        }
        
        private func getUEFIPath() -> String {
            // Return path to UEFI firmware
            return "/usr/share/qemu-efi-aarch64/QEMU_EFI.fd"
        }
        
        private func buildNetworkConfig(_ network: UTMEnhancedVMConfig.NetworkConfig, index: Int) -> String {
            var config = "user,id=net\(index)"
            
            // Add port forwards
            for forward in network.portForwards {
                config += ",hostfwd=\(forward.protocol):\(forward.hostAddress ?? ""):\(forward.hostPort)-\(forward.guestAddress ?? ""):\(forward.guestPort)"
            }
            
            return config
        }
        
        private func buildDriveConfig(_ drive: UTMEnhancedVMConfig.DriveConfig, index: Int) -> String {
            var config = "file=\(getDrivePath(drive)),format=\(drive.imageType),id=drive\(index)"
            
            if drive.isReadOnly {
                config += ",readonly=on"
            }
            
            config += ",if=\(drive.interface)"
            
            return config
        }
        
        private func getDrivePath(_ drive: UTMEnhancedVMConfig.DriveConfig) -> String {
            // Return path to drive image
            return "/tmp/\(drive.id).qcow2"
        }
    }
    
    private init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        loadVMTemplates()
        loadCustomConfigurations()
    }
    
    // MARK: - Template Management
    
    /// Load predefined VM templates
    private func loadVMTemplates() {
        let templates = [
            createAndroidTemplate(),
            createEnterpriseAndroidTemplate(),
            createLinuxTemplate(),
            createWindowsTemplate()
        ]
        
        DispatchQueue.main.async {
            self.availableTemplates = templates
        }
    }
    
    /// Create Android VM template
    private func createAndroidTemplate() -> VMTemplate {
        let config = UTMEnhancedVMConfig(
            id: "android-template",
            name: "Android Virtual Device",
            architecture: .aarch64,
            target: "virt",
            memorySize: 3072,
            cpuCount: 4,
            hasHypervisor: true,
            hasUefiBoot: true,
            hasTPMDevice: false,
            hasRNGDevice: true,
            hasBalloonDevice: true,
            hasRTCLocalTime: false,
            displays: [
                UTMEnhancedVMConfig.DisplayConfig(
                    hardware: "virtio-gpu-gl-pci",
                    width: 1080,
                    height: 2400,
                    isDynamicResolution: true,
                    hasGLAcceleration: true
                )
            ],
            networks: [
                UTMEnhancedVMConfig.NetworkConfig(
                    interface: "virtio-net-pci",
                    mode: "emulated",
                    portForwards: [
                        UTMEnhancedVMConfig.NetworkConfig.PortForward(
                            protocol: "tcp",
                            hostPort: 5555,
                            guestPort: 5555,
                            hostAddress: nil,
                            guestAddress: nil
                        )
                    ]
                )
            ],
            drives: [
                UTMEnhancedVMConfig.DriveConfig(
                    id: "android-system",
                    interface: "virtio-blk-pci",
                    imageType: "qcow2",
                    sizeMB: 16384,
                    isExternal: false,
                    isReadOnly: false
                )
            ],
            serials: [],
            sound: [
                UTMEnhancedVMConfig.SoundConfig(
                    hardware: "intel-hda",
                    isEnabled: true
                )
            ],
            sharing: UTMEnhancedVMConfig.SharingConfig(
                hasClipboardSharing: true,
                directoryShareMode: "virtfs",
                isDirectoryShareReadOnly: false,
                sharedDirectoryURL: nil
            ),
            security: UTMEnhancedVMConfig.SecurityConfig(
                hasSecureBoot: false,
                hasEncryption: false,
                isolationLevel: "medium",
                networkIsolation: false
            ),
            androidConfig: UTMEnhancedVMConfig.AndroidVMConfig(
                androidVersion: "13.0",
                isGooglePlayEnabled: true,
                hasGoogleServices: true,
                deviceProfile: "pixel",
                orientation: "portrait",
                isRooted: false,
                customApps: []
            )
        )
        
        return VMTemplate(
            id: "android-standard",
            name: "Android 13",
            description: "Standard Android virtual device with Google Play services",
            architecture: .aarch64,
            osType: .android,
            iconName: "smartphone",
            requiredMemoryMB: 3072,
            requiredStorageGB: 16,
            features: [.hypervisor, .gpu, .networking, .sharing, .clipboard, .audio],
            configuration: config
        )
    }
    
    /// Create Enterprise Android template
    private func createEnterpriseAndroidTemplate() -> VMTemplate {
        let config = UTMEnhancedVMConfig(
            id: "android-enterprise-template",
            name: "Enterprise Android",
            architecture: .aarch64,
            target: "virt",
            memorySize: 4096,
            cpuCount: 6,
            hasHypervisor: true,
            hasUefiBoot: true,
            hasTPMDevice: true,
            hasRNGDevice: true,
            hasBalloonDevice: true,
            hasRTCLocalTime: false,
            displays: [
                UTMEnhancedVMConfig.DisplayConfig(
                    hardware: "virtio-gpu-gl-pci",
                    width: 1440,
                    height: 3120,
                    isDynamicResolution: true,
                    hasGLAcceleration: true
                )
            ],
            networks: [
                UTMEnhancedVMConfig.NetworkConfig(
                    interface: "virtio-net-pci",
                    mode: "emulated",
                    portForwards: []
                )
            ],
            drives: [
                UTMEnhancedVMConfig.DriveConfig(
                    id: "android-enterprise-system",
                    interface: "virtio-blk-pci",
                    imageType: "qcow2",
                    sizeMB: 32768,
                    isExternal: false,
                    isReadOnly: false
                )
            ],
            serials: [],
            sound: [
                UTMEnhancedVMConfig.SoundConfig(
                    hardware: "intel-hda",
                    isEnabled: false
                )
            ],
            sharing: UTMEnhancedVMConfig.SharingConfig(
                hasClipboardSharing: false,
                directoryShareMode: "none",
                isDirectoryShareReadOnly: true,
                sharedDirectoryURL: nil
            ),
            security: UTMEnhancedVMConfig.SecurityConfig(
                hasSecureBoot: true,
                hasEncryption: true,
                isolationLevel: "maximum",
                networkIsolation: true
            ),
            androidConfig: UTMEnhancedVMConfig.AndroidVMConfig(
                androidVersion: "13.0",
                isGooglePlayEnabled: false,
                hasGoogleServices: false,
                deviceProfile: "enterprise",
                orientation: "portrait",
                isRooted: false,
                customApps: ["MDM", "VPN", "SecureBrowser"]
            )
        )
        
        return VMTemplate(
            id: "android-enterprise",
            name: "Enterprise Android",
            description: "Secure Android for enterprise use with enhanced security features",
            architecture: .aarch64,
            osType: .android,
            iconName: "lock.shield",
            requiredMemoryMB: 4096,
            requiredStorageGB: 32,
            features: [.hypervisor, .gpu, .tpm, .uefi, .networking],
            configuration: config
        )
    }
    
    /// Create Linux template
    private func createLinuxTemplate() -> VMTemplate {
        let config = UTMEnhancedVMConfig(
            id: "linux-template",
            name: "Ubuntu Linux",
            architecture: .x86_64,
            target: "q35",
            memorySize: 2048,
            cpuCount: 2,
            hasHypervisor: true,
            hasUefiBoot: true,
            hasTPMDevice: false,
            hasRNGDevice: true,
            hasBalloonDevice: true,
            hasRTCLocalTime: false,
            displays: [
                UTMEnhancedVMConfig.DisplayConfig(
                    hardware: "virtio-gpu-pci",
                    width: 1920,
                    height: 1080,
                    isDynamicResolution: true,
                    hasGLAcceleration: false
                )
            ],
            networks: [
                UTMEnhancedVMConfig.NetworkConfig(
                    interface: "virtio-net-pci",
                    mode: "emulated",
                    portForwards: [
                        UTMEnhancedVMConfig.NetworkConfig.PortForward(
                            protocol: "tcp",
                            hostPort: 22,
                            guestPort: 22,
                            hostAddress: nil,
                            guestAddress: nil
                        )
                    ]
                )
            ],
            drives: [
                UTMEnhancedVMConfig.DriveConfig(
                    id: "linux-system",
                    interface: "virtio-blk-pci",
                    imageType: "qcow2",
                    sizeMB: 20480,
                    isExternal: false,
                    isReadOnly: false
                )
            ],
            serials: [
                UTMEnhancedVMConfig.SerialConfig(
                    id: "console",
                    mode: "builtin",
                    target: "console"
                )
            ],
            sound: [
                UTMEnhancedVMConfig.SoundConfig(
                    hardware: "intel-hda",
                    isEnabled: true
                )
            ],
            sharing: UTMEnhancedVMConfig.SharingConfig(
                hasClipboardSharing: true,
                directoryShareMode: "virtfs",
                isDirectoryShareReadOnly: false,
                sharedDirectoryURL: nil
            ),
            security: UTMEnhancedVMConfig.SecurityConfig(
                hasSecureBoot: false,
                hasEncryption: false,
                isolationLevel: "medium",
                networkIsolation: false
            ),
            androidConfig: UTMEnhancedVMConfig.AndroidVMConfig(
                androidVersion: "",
                isGooglePlayEnabled: false,
                hasGoogleServices: false,
                deviceProfile: "",
                orientation: "",
                isRooted: false,
                customApps: []
            )
        )
        
        return VMTemplate(
            id: "linux-ubuntu",
            name: "Ubuntu Linux",
            description: "Ubuntu Linux desktop environment",
            architecture: .x86_64,
            osType: .linux,
            iconName: "desktopcomputer",
            requiredMemoryMB: 2048,
            requiredStorageGB: 20,
            features: [.hypervisor, .uefi, .networking, .sharing, .clipboard, .audio],
            configuration: config
        )
    }
    
    /// Create Windows template
    private func createWindowsTemplate() -> VMTemplate {
        let config = UTMEnhancedVMConfig(
            id: "windows-template",
            name: "Windows 11",
            architecture: .x86_64,
            target: "q35",
            memorySize: 4096,
            cpuCount: 4,
            hasHypervisor: true,
            hasUefiBoot: true,
            hasTPMDevice: true,
            hasRNGDevice: true,
            hasBalloonDevice: true,
            hasRTCLocalTime: true,
            displays: [
                UTMEnhancedVMConfig.DisplayConfig(
                    hardware: "virtio-gpu-pci",
                    width: 1920,
                    height: 1080,
                    isDynamicResolution: true,
                    hasGLAcceleration: false
                )
            ],
            networks: [
                UTMEnhancedVMConfig.NetworkConfig(
                    interface: "virtio-net-pci",
                    mode: "emulated",
                    portForwards: [
                        UTMEnhancedVMConfig.NetworkConfig.PortForward(
                            protocol: "tcp",
                            hostPort: 3389,
                            guestPort: 3389,
                            hostAddress: nil,
                            guestAddress: nil
                        )
                    ]
                )
            ],
            drives: [
                UTMEnhancedVMConfig.DriveConfig(
                    id: "windows-system",
                    interface: "virtio-blk-pci",
                    imageType: "qcow2",
                    sizeMB: 65536,
                    isExternal: false,
                    isReadOnly: false
                )
            ],
            serials: [],
            sound: [
                UTMEnhancedVMConfig.SoundConfig(
                    hardware: "intel-hda",
                    isEnabled: true
                )
            ],
            sharing: UTMEnhancedVMConfig.SharingConfig(
                hasClipboardSharing: true,
                directoryShareMode: "spice-webdav",
                isDirectoryShareReadOnly: false,
                sharedDirectoryURL: nil
            ),
            security: UTMEnhancedVMConfig.SecurityConfig(
                hasSecureBoot: true,
                hasEncryption: false,
                isolationLevel: "medium",
                networkIsolation: false
            ),
            androidConfig: UTMEnhancedVMConfig.AndroidVMConfig(
                androidVersion: "",
                isGooglePlayEnabled: false,
                hasGoogleServices: false,
                deviceProfile: "",
                orientation: "",
                isRooted: false,
                customApps: []
            )
        )
        
        return VMTemplate(
            id: "windows-11",
            name: "Windows 11",
            description: "Windows 11 with TPM and Secure Boot",
            architecture: .x86_64,
            osType: .windows,
            iconName: "laptopcomputer",
            requiredMemoryMB: 4096,
            requiredStorageGB: 64,
            features: [.hypervisor, .tpm, .uefi, .networking, .sharing, .clipboard, .audio],
            configuration: config
        )
    }
    
    // MARK: - Configuration Validation
    
    /// Validate VM configuration
    func validateConfiguration(_ config: UTMEnhancedVMConfig) -> AnyPublisher<ValidationResult, Never> {
        isValidating = true
        
        return Future { [weak self] promise in
            Task {
                let result = await self?.performValidation(config) ?? ValidationResult(isValid: false, errors: ["Validation failed"])
                
                DispatchQueue.main.async {
                    self?.isValidating = false
                }
                
                promise(.success(result))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Perform configuration validation
    private func performValidation(_ config: UTMEnhancedVMConfig) async -> ValidationResult {
        var errors: [String] = []
        var warnings: [String] = []
        
        // Validate memory requirements
        if config.memorySize < 512 {
            errors.append("Memory size too low (minimum 512MB required)")
        } else if config.memorySize > 8192 {
            warnings.append("High memory usage may impact device performance")
        }
        
        // Validate CPU count
        if config.cpuCount < 1 {
            errors.append("At least 1 CPU core required")
        } else if config.cpuCount > ProcessInfo.processInfo.processorCount {
            warnings.append("CPU count exceeds available cores")
        }
        
        // Validate architecture support
        if !config.architecture.hasHypervisorSupport && config.hasHypervisor {
            warnings.append("Hypervisor not supported for \(config.architecture.rawValue)")
        }
        
        // Validate display configuration
        for display in config.displays {
            if display.hasGLAcceleration && !checkGLSupport() {
                warnings.append("OpenGL acceleration may not be available")
            }
        }
        
        // Validate drive configuration
        for drive in config.drives {
            if let size = drive.sizeMB, size < 1024 {
                warnings.append("Drive \(drive.id) size is very small")
            }
        }
        
        // Validate security configuration
        if config.security.hasSecureBoot && !config.hasUefiBoot {
            errors.append("Secure Boot requires UEFI boot")
        }
        
        if config.security.hasEncryption && !config.hasTPMDevice {
            warnings.append("Encryption is more secure with TPM device")
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
    
    /// Check OpenGL support
    private func checkGLSupport() -> Bool {
        // Simplified check - in real implementation would check device capabilities
        return true
    }
    
    struct ValidationResult {
        let isValid: Bool
        let errors: [String]
        let warnings: [String]
        
        init(isValid: Bool, errors: [String], warnings: [String] = []) {
            self.isValid = isValid
            self.errors = errors
            self.warnings = warnings
        }
    }
    
    // MARK: - Configuration Persistence
    
    /// Save custom configuration
    func saveCustomConfiguration(_ config: UTMEnhancedVMConfig) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "ConfigManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Manager deallocated"])))
                return
            }
            
            do {
                let data = try JSONEncoder().encode(config)
                let url = self.documentsDirectory.appendingPathComponent("vm-configs").appendingPathComponent("\(config.id).json")
                
                try self.fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try data.write(to: url)
                
                DispatchQueue.main.async {
                    if !self.customConfigurations.contains(where: { $0.id == config.id }) {
                        self.customConfigurations.append(config)
                    }
                }
                
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Load custom configurations
    private func loadCustomConfigurations() {
        let configsDir = documentsDirectory.appendingPathComponent("vm-configs")
        
        guard fileManager.fileExists(atPath: configsDir.path) else { return }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: configsDir, includingPropertiesForKeys: nil)
            let jsonFiles = files.filter { $0.pathExtension == "json" }
            
            var configs: [UTMEnhancedVMConfig] = []
            
            for file in jsonFiles {
                do {
                    let data = try Data(contentsOf: file)
                    let config = try JSONDecoder().decode(UTMEnhancedVMConfig.self, from: data)
                    configs.append(config)
                } catch {
                    print("Failed to load config from \(file): \(error)")
                }
            }
            
            DispatchQueue.main.async {
                self.customConfigurations = configs
            }
        } catch {
            print("Failed to load custom configurations: \(error)")
        }
    }
    
    /// Delete custom configuration
    func deleteCustomConfiguration(id: String) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "ConfigManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Manager deallocated"])))
                return
            }
            
            do {
                let url = self.documentsDirectory.appendingPathComponent("vm-configs").appendingPathComponent("\(id).json")
                
                if self.fileManager.fileExists(atPath: url.path) {
                    try self.fileManager.removeItem(at: url)
                }
                
                DispatchQueue.main.async {
                    self.customConfigurations.removeAll { $0.id == id }
                }
                
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
}
