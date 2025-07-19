# ShaydZ AVMo - Demos

This directory contains demonstration files and interactive showcases for the ShaydZ AVMo virtual mobile infrastructure platform.

## 🎯 Purpose

The demos are **separate from the main application** but showcase its capabilities:
- Interactive iOS app simulation
- Backend service monitoring
- Live API demonstrations
- Architecture visualization

## 📁 Structure

```
demos/
├── package.json           # Demo-specific dependencies
├── scripts/              # Demo server and utilities
│   ├── simple-server.js  # Web server for demos
│   ├── demo-server.js    # Advanced demo server
│   ├── show-running-app.js
│   └── success-message.js
├── web-demos/            # Web-based demonstrations
│   ├── app-demo.html     # Interactive iOS app simulator
│   ├── backend-status.html
│   └── live-backend-demo.html
└── README.md             # This file
```

## 🚀 Running Demos

### Quick Start
```bash
cd demos
npm install
npm start
```

### Available Commands
```bash
npm run demo     # Start demo web server
npm run status   # Show running app status
npm run success  # Display success message
```

## 🌐 Demo URLs

When running the demo server:
- **iOS App Demo**: http://localhost:3000/app-demo.html
- **Backend Status**: http://localhost:3000/backend-status.html
- **Live Backend**: http://localhost:3000/live-backend-demo.html

## 📱 iOS App Demo Features

- Authentic iOS interface design
- Working login system (demo/password)
- Interactive app catalog with 12 apps
- Virtual machine management
- Tab navigation (Apps, VMs, Profile)
- Real-time UI updates

## 📊 Backend Demo Features

- Live service health monitoring
- API response examples
- Performance metrics display
- Architecture visualization
- Real data from backend services

## 🔗 Integration with Main App

These demos connect to the actual ShaydZ AVMo backend services:
- Authentication Service (port 8081)
- App Catalog Service (port 8083)
- VM Orchestrator Service (port 8082)
- API Gateway (port 8080)

## ⚠️ Note

**These are demonstration files only.** The actual ShaydZ AVMo application code is located in:
- `../ShaydZ-AVMo/` - iOS app source code
- `../backend/` - Backend services
- `../ios-integration/` - iOS-backend integration tools

## 🎯 Use Cases

- **Development**: Visualize app behavior during development
- **Testing**: Interactive testing of backend services
- **Demonstration**: Show app capabilities to stakeholders
- **Documentation**: Visual reference for app features
