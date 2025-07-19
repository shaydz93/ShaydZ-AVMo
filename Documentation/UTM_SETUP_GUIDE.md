# UTM-Enhanced ShaydZ-AVMo Quick Setup Guide

## Overview

ShaydZ-AVMo now includes enterprise-grade virtual machine capabilities inspired by the UTM project. This guide will help you get started with the enhanced virtualization features.

## New Features

### 1. Enhanced Virtual Machine Service
- **QEMU-based virtualization** with multi-architecture support
- **Advanced security** with TPM, Secure Boot, and encryption
- **Performance monitoring** with real-time metrics
- **Android optimization** for mobile app virtualization

### 2. Configuration Management
- **VM Templates** for quick setup (Android, Linux, Windows)
- **Custom configurations** with validation
- **Template gallery** for browsing available VMs
- **Configuration persistence** and sharing

### 3. Enhanced VM Viewer
- **SPICE protocol** for high-performance display
- **Touch input** translation for iOS devices
- **Virtual keyboard** for text input
- **Android controls** (Back, Home, Recent Apps)
- **Screenshot and snapshot** capabilities

## Getting Started

### 1. Launch Enhanced VM Management

```swift
import SwiftUI

struct MainView: View {
    var body: some View {
        NavigationView {
            EnhancedVMManagementView()
        }
    }
}
```

### 2. Create VM from Template

```swift
// Access the configuration manager
let configManager = QEMUVMConfigurationManager.shared

// Browse available templates
let templates = configManager.availableTemplates

// Launch Android VM
let androidTemplate = templates.first { $0.osType == .android }
if let template = androidTemplate {
    Task {
        let vmService = UTMEnhancedVirtualMachineService.shared
        let instance = try await vmService.launchEnhancedVM(configId: template.configuration.id)
        print("VM launched: \\(instance.id)")
    }
}
```

### 3. Custom VM Configuration

```swift
// Create custom Android configuration
let customConfig = UTMEnhancedVMConfig(
    id: UUID().uuidString,
    name: "Custom Enterprise Android",
    architecture: .aarch64,
    target: "virt",
    memorySize: 4096,
    cpuCount: 4,
    hasHypervisor: true,
    hasUefiBoot: true,
    hasTPMDevice: true,
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
    networks: [...],
    drives: [...],
    serials: [...],
    sound: [...],
    sharing: UTMEnhancedVMConfig.SharingConfig(...),
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

// Save custom configuration
configManager.saveCustomConfiguration(customConfig)
    .sink(
        receiveCompletion: { completion in
            if case .failure(let error) = completion {
                print("Failed to save config: \\(error)")
            }
        },
        receiveValue: {
            print("Configuration saved successfully")
        }
    )
    .store(in: &cancellables)
```

### 4. VM Viewer Integration

```swift
// Display VM in enhanced viewer
NavigationLink(destination: EnhancedVMViewer(vmInstance: vmInstance)) {
    Text("Open VM")
}
```

## Key Components

### UTMEnhancedVirtualMachineService
- **Primary VM management service**
- Handles VM lifecycle (start, pause, resume, stop)
- Performance monitoring and optimization
- Supabase integration for session tracking

### QEMUVMConfigurationManager
- **Configuration management and validation**
- Predefined templates for quick setup
- Custom configuration persistence
- QEMU command line generation

### EnhancedVMViewer
- **High-performance VM display interface**
- SPICE protocol integration
- Touch input handling
- Virtual keyboard and Android controls

### EnhancedVMManagementView
- **Modern SwiftUI management interface**
- Real-time performance dashboards
- Template gallery and VM wizard
- Configuration management

## Advanced Features

### 1. Performance Monitoring

```swift
// Access real-time performance metrics
let vmService = UTMEnhancedVirtualMachineService.shared
for (vmId, instance) in vmService.activeVMs {
    print("VM \\(vmId):")
    print("  CPU: \\(instance.performance.cpuUsage)%")
    print("  Memory: \\(instance.performance.memoryUsage)%")
    print("  FPS: \\(instance.performance.frameRate)")
    print("  Latency: \\(instance.performance.latency)ms")
}
```

### 2. Snapshot Management

```swift
// Take VM snapshot
Task {
    let snapshotId = try await vmService.takeSnapshot(
        instanceId: vmInstance.id,
        name: "Pre-Update Snapshot"
    )
    print("Snapshot created: \\(snapshotId)")
}

// Restore from snapshot
Task {
    try await vmService.restoreSnapshot(
        instanceId: vmInstance.id,
        snapshotId: snapshotId
    )
    print("VM restored from snapshot")
}
```

### 3. Configuration Validation

```swift
// Validate VM configuration
configManager.validateConfiguration(customConfig)
    .sink { result in
        if result.isValid {
            print("Configuration is valid")
        } else {
            print("Validation errors: \\(result.errors)")
            print("Warnings: \\(result.warnings)")
        }
    }
    .store(in: &cancellables)
```

## Security Features

### Enterprise Security Configuration

```swift
let enterpriseConfig = UTMEnhancedVMConfig.SecurityConfig(
    hasSecureBoot: true,        // UEFI Secure Boot
    hasEncryption: true,        // Full disk encryption
    isolationLevel: "maximum",  // Complete isolation
    networkIsolation: true     // No network access
)
```

### Available Isolation Levels
- **low**: Basic VM isolation
- **medium**: Network restrictions
- **high**: Complete network isolation except essential services
- **maximum**: Full isolation (air-gapped)

## Integration with Existing Features

### Supabase Integration
All VM operations are automatically logged to Supabase:
- VM session tracking
- User activity logging
- Performance metrics
- Security events

### Authentication
VM access is controlled by existing Supabase authentication:
```swift
// Only authenticated users can access VMs
if SupabaseAuthService.shared.isAuthenticated {
    // Launch VM
}
```

## Troubleshooting

### Common Issues

1. **VM fails to start**
   - Check device memory availability
   - Verify configuration validation
   - Review error logs in Supabase

2. **Poor performance**
   - Reduce memory allocation
   - Disable GPU acceleration if unsupported
   - Lower CPU core count

3. **Display issues**
   - Check SPICE connection
   - Verify display configuration
   - Try disabling OpenGL acceleration

### Debug Mode

```swift
// Enable debug logging
vmService.isDebugging = true
configManager.isDebugging = true
```

## Best Practices

1. **Resource Management**
   - Monitor device memory usage
   - Limit concurrent VMs
   - Use appropriate VM sizes

2. **Security**
   - Enable TPM for enterprise VMs
   - Use encryption for sensitive data
   - Configure appropriate isolation levels

3. **Performance**
   - Optimize configurations for device capabilities
   - Use snapshots for quick testing
   - Monitor performance metrics

## Example: Complete VM Setup

```swift
import SwiftUI
import Combine

struct VMSetupExample: View {
    @StateObject private var vmService = UTMEnhancedVirtualMachineService.shared
    @StateObject private var configManager = QEMUVMConfigurationManager.shared
    @State private var vmInstance: UTMEnhancedVirtualMachineService.VMInstance?
    
    var body: some View {
        VStack {
            if let instance = vmInstance {
                NavigationLink(destination: EnhancedVMViewer(vmInstance: instance)) {
                    Text("Open VM")
                }
            } else {
                Button("Launch Android VM") {
                    launchAndroidVM()
                }
            }
        }
    }
    
    private func launchAndroidVM() {
        // Get Android template
        guard let androidTemplate = configManager.availableTemplates.first(where: { $0.osType == .android }) else {
            return
        }
        
        // Launch VM
        Task {
            do {
                let instance = try await vmService.launchEnhancedVM(configId: androidTemplate.configuration.id)
                DispatchQueue.main.async {
                    self.vmInstance = instance
                }
            } catch {
                print("Failed to launch VM: \\(error)")
            }
        }
    }
}
```

This setup provides a complete enterprise-grade virtual machine infrastructure with advanced security, performance monitoring, and user-friendly management interfaces.
