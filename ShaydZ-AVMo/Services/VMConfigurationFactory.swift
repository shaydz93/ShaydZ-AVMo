//
//  VMConfigurationFactory.swift
//  ShaydZ-AVMo
//
//  Extracted from UTMEnhancedVirtualMachineService for better separation of concerns
//

import Foundation

/// Factory for creating VM configurations
class VMConfigurationFactory {
    
    /// Create Android VM configuration
    static func createAndroidConfig(
        name: String,
        androidVersion: String,
        memorySize: Int,
        cpuCount: Int,
        deviceProfile: String
    ) -> UTMEnhancedVMConfig {
        return UTMEnhancedVMConfig(
            id: UUID().uuidString,
            name: name,
            architecture: .aarch64,
            target: "virt",
            memorySize: memorySize,
            cpuCount: cpuCount,
            hasHypervisor: true,
            hasUefiBoot: true,
            hasTPMDevice: true,
            hasRNGDevice: true,
            hasBalloonDevice: true,
            hasRTCLocalTime: false,
            displays: [createDefaultDisplay()],
            networks: [createDefaultNetwork()],
            drives: [createSystemDrive()],
            serials: [createConsoleSerial()],
            sound: [createDefaultSound()],
            sharing: createDefaultSharing(),
            security: createStandardSecurity(),
            androidConfig: createAndroidVMConfig(
                androidVersion: androidVersion,
                deviceProfile: deviceProfile
            )
        )
    }
    
    /// Create enterprise security VM configuration
    static func createEnterpriseConfig(
        name: String,
        androidVersion: String,
        memorySize: Int,
        cpuCount: Int
    ) -> UTMEnhancedVMConfig {
        var config = createAndroidConfig(
            name: name,
            androidVersion: androidVersion,
            memorySize: memorySize,
            cpuCount: cpuCount,
            deviceProfile: "enterprise"
        )
        
        // Enhanced security settings
        config.security = createEnterpriseSecurity()
        
        // Remove port forwards for security
        config.networks[0].portForwards.removeAll()
        
        // Enterprise Android settings
        config.androidConfig = UTMEnhancedVMConfig.AndroidVMConfig(
            androidVersion: androidVersion,
            isGooglePlayEnabled: false,
            hasGoogleServices: false,
            deviceProfile: "enterprise",
            orientation: "portrait",
            isRooted: false,
            customApps: ["CompanyPortal", "MDM", "VPN"]
        )
        
        return config
    }
    
    // MARK: - Private Helper Methods
    
    private static func createDefaultDisplay() -> UTMEnhancedVMConfig.DisplayConfig {
        return UTMEnhancedVMConfig.DisplayConfig(
            hardware: "virtio-gpu-gl-pci",
            width: 1080,
            height: 2400,
            isDynamicResolution: true,
            hasGLAcceleration: true
        )
    }
    
    private static func createDefaultNetwork() -> UTMEnhancedVMConfig.NetworkConfig {
        return UTMEnhancedVMConfig.NetworkConfig(
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
    }
    
    private static func createSystemDrive() -> UTMEnhancedVMConfig.DriveConfig {
        return UTMEnhancedVMConfig.DriveConfig(
            id: "system",
            interface: "virtio-blk-pci",
            imageType: "disk",
            sizeMB: 32768,
            isExternal: false,
            isReadOnly: false
        )
    }
    
    private static func createConsoleSerial() -> UTMEnhancedVMConfig.SerialConfig {
        return UTMEnhancedVMConfig.SerialConfig(
            id: "console",
            mode: "builtin",
            target: "gdb"
        )
    }
    
    private static func createDefaultSound() -> UTMEnhancedVMConfig.SoundConfig {
        return UTMEnhancedVMConfig.SoundConfig(
            hardware: "intel-hda",
            isEnabled: true
        )
    }
    
    private static func createDefaultSharing() -> UTMEnhancedVMConfig.SharingConfig {
        return UTMEnhancedVMConfig.SharingConfig(
            hasClipboardSharing: true,
            directoryShareMode: "virtfs",
            isDirectoryShareReadOnly: false,
            sharedDirectoryURL: nil
        )
    }
    
    private static func createStandardSecurity() -> UTMEnhancedVMConfig.SecurityConfig {
        return UTMEnhancedVMConfig.SecurityConfig(
            hasSecureBoot: true,
            hasEncryption: true,
            isolationLevel: "high",
            networkIsolation: true
        )
    }
    
    private static func createEnterpriseSecurity() -> UTMEnhancedVMConfig.SecurityConfig {
        return UTMEnhancedVMConfig.SecurityConfig(
            hasSecureBoot: true,
            hasEncryption: true,
            isolationLevel: "maximum",
            networkIsolation: true
        )
    }
    
    private static func createAndroidVMConfig(
        androidVersion: String,
        deviceProfile: String
    ) -> UTMEnhancedVMConfig.AndroidVMConfig {
        return UTMEnhancedVMConfig.AndroidVMConfig(
            androidVersion: androidVersion,
            isGooglePlayEnabled: false,
            hasGoogleServices: false,
            deviceProfile: deviceProfile,
            orientation: "portrait",
            isRooted: false,
            customApps: []
        )
    }
}
