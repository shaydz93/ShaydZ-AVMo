# ShaydZ AVMo - iOS Integration

This directory contains tools and utilities for integrating the iOS ShaydZ AVMo app with the backend services.

## 🎯 Purpose

**Integration-focused tools only** - no demo files here. For demonstrations, see `../demos/`.

## 📁 Structure

```
ios-integration/
├── README.md                    # This file
├── NetworkService.swift         # iOS network integration
├── IntegratedViewModels.swift   # iOS view models with backend
├── IntegratedViews.swift        # iOS views with live data
└── scripts/                     # Integration utilities
    ├── check-backend.js         # Backend health checker
    ├── sync-services.js         # Service synchronization
    └── test-integration.js      # Integration testing
```

## 🔗 Integration Components

### Swift Files
- **NetworkService.swift**: Complete iOS networking layer
- **IntegratedViewModels.swift**: Reactive view models using Combine
- **IntegratedViews.swift**: SwiftUI views with live backend data

### Scripts
- **check-backend.js**: Verify backend services are running
- **sync-services.js**: Synchronize iOS app with backend state
- **test-integration.js**: Test iOS-backend communication

## 📱 iOS App Integration

These files integrate directly with the main iOS app located at:
`../ShaydZ-AVMo/` (Xcode project)

To integrate:
1. Copy Swift files to your Xcode project
2. Update import statements as needed
3. Configure API endpoints in APIConfig.swift

## 🔧 Backend Connection

Connects to backend services:
- API Gateway: `http://localhost:8080`
- Auth Service: `http://localhost:8081`
- App Catalog: `http://localhost:8083`
- VM Orchestrator: `http://localhost:8082`

## 🎯 For Demos

**Looking for demos?** Visit `../demos/` for:
- Interactive iOS app simulator
- Backend status monitoring
- Live API demonstrations

## 📋 Integration Checklist

- [ ] Backend services running (use check-backend.js)
- [ ] iOS app configured with correct API endpoints
- [ ] NetworkService.swift added to Xcode project
- [ ] View models integrated with existing views
- [ ] Authentication flow tested
- [ ] Data synchronization working
