# iOS Integration Instructions

## Generated Files

This tool has generated the following Swift files for iOS integration:

1. **NetworkService.swift** - HTTP client for backend API communication
2. **IntegratedViewModels.swift** - View models with Combine publishers
3. **IntegratedViews.swift** - SwiftUI views integrated with backend services

## Integration Steps

### 1. Copy Files to Xcode Project

Copy the generated Swift files to your Xcode project:

```bash
# From your project root
cp ios-integration/generated-swift/*.swift ShaydZ-AVMo/Services/
```

### 2. Update Network Configuration

The generated code uses localhost URLs. For device testing, update the URLs in `NetworkService.swift`:

```swift
// Replace localhost with your development machine's IP
private let baseURL = "http://YOUR_LOCAL_IP:8080"
private let authServiceURL = "http://YOUR_LOCAL_IP:8081"
// ... etc
```

### 3. Add Required Dependencies

Ensure your project has the necessary frameworks:
- Combine (for reactive programming)
- SwiftUI (for modern UI)

### 4. Replace Existing Views

Update your main app structure to use the integrated views:

```swift
// In ShaydZAVMoApp.swift
var body: some Scene {
    WindowGroup {
        IntegratedAppView()
    }
}
```

### 5. Configure App Transport Security

Add this to your Info.plist for development (localhost access):

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## Testing Integration

1. **Start Backend Services**:
   ```bash
   cd demo-production
   docker-compose up -d
   ```

2. **Run Integration Test**:
   ```bash
   cd ios-integration
   npm run test:integration
   ```

3. **Build and Run iOS App**:
   - Open project in Xcode
   - Select simulator or device
   - Build and run (⌘R)

## Default Login Credentials

- Username: `demo`
- Password: `password`

## API Endpoints

The generated code connects to these services:
- **Auth Service**: http://localhost:8081
- **App Catalog**: http://localhost:8083
- **VM Orchestrator**: http://localhost:8082
- **API Gateway**: http://localhost:8080

## Troubleshooting

### Network Issues
- Ensure backend services are running
- Check firewall settings
- Verify IP addresses for device testing

### Authentication Issues
- Token expires in 1 hour
- App automatically handles re-authentication
- Check backend logs for auth errors

### Build Issues
- Clean build folder (⌘⇧K)
- Restart Xcode
- Verify all files are added to target

## Next Steps

1. Customize UI themes and styling
2. Add error handling improvements
3. Implement offline caching
4. Add push notifications
5. Configure production endpoints

For more help, check the backend API documentation and logs.
