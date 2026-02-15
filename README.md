# ShaydZ AVMo - Virtual Mobile Infrastructure Platform

<div align="center">
  <h3>🚀 Revolutionary Virtual iOS App Environment</h3>
  <p>Experience iOS apps in containerized virtual machines with full backend integration</p>
  
  ![Platform](https://img.shields.io/badge/Platform-iOS-blue)
  ![Backend](https://img.shields.io/badge/Backend-Node.js-green)
  ![Database](https://img.shields.io/badge/Database-MongoDB-brightgreen)
  ![Container](https://img.shields.io/badge/Container-Docker-blue)
  ![License](https://img.shields.io/badge/License-MIT-yellow)
</div>

## 🎯 Overview

ShaydZ AVMo is a cutting-edge virtual mobile infrastructure platform that enables users to run iOS applications in isolated virtual machine environments. Built with a modern microservices architecture, it provides seamless app deployment, management, and execution capabilities.

### ✨ Key Features

- 📱 **Virtual iOS Environment**: Run iOS apps in containerized virtual machines
- 🔐 **Secure Authentication**: JWT-based authentication with role management
- 📊 **App Catalog Management**: Comprehensive app library with metadata
- 🖥️ **VM Orchestration**: Automated virtual machine lifecycle management
- 🌐 **RESTful API Gateway**: Unified API access with load balancing
- 🎮 **Interactive Demos**: Web-based app simulation and monitoring

## 🏗️ Architecture

### Microservices Backend
- **API Gateway** (Port 8080): Request routing and load balancing
- **Authentication Service** (Port 8081): User management and JWT tokens
- **VM Orchestrator** (Port 8082): Virtual machine lifecycle management
- **App Catalog Service** (Port 8083): Application metadata and library

### Frontend Applications
- **iOS App**: Native SwiftUI application with Combine framework
- **Web Demos**: Interactive demonstrations and monitoring tools

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose
- Node.js 18+ 
- Python 3.8+
- Xcode (for iOS development)

### ⚠️ Security Configuration (IMPORTANT!)

**Before running the application, you MUST configure environment variables:**

1. **Backend Services**: Each backend service requires environment variables. Copy the example files:
   ```bash
   # For each backend service directory:
   cp backend/api-gateway/.env.example backend/api-gateway/.env
   cp backend/auth-service/.env.example backend/auth-service/.env
   cp backend/ai-service/.env.example backend/ai-service/.env
   cp backend/vm-orchestrator/.env.example backend/vm-orchestrator/.env
   ```

2. **Set Strong Secrets**: Edit each `.env` file and replace placeholder values:
   - `JWT_SECRET`: Use a strong random string (minimum 32 characters)
   - `MONGO_URI` / `DB_CONNECTION_STRING`: Your MongoDB connection string
   - `SUPABASE_URL` and `SUPABASE_ANON_KEY`: From your Supabase project

3. **iOS App**: Copy and configure Supabase credentials:
   ```bash
   cp .env.supabase.example .env.supabase
   # Edit .env.supabase with your actual Supabase credentials
   ```

**⚠️ WARNING**: Never commit `.env` files or `.env.supabase` to git. These files contain secrets!

### 🔐 Generating a Secure JWT Secret
```bash
# Use openssl to generate a secure secret
openssl rand -base64 32
```

### 1. Clone Repository
```bash
git clone https://github.com/shaydz93/ShaydZ-AVMo.git
cd ShaydZ-AVMo
```

### 2. Start Backend Services
```bash
cd demo-production
docker-compose up -d
```

### 3. Run Interactive Demos
```bash
cd demos
npm install
npm start
```

Open http://localhost:3000/app-demo.html for the iOS app simulation.

### 4. iOS Development
```bash
cd ios-integration
node scripts/check-backend.js  # Verify backend connectivity
```

Open `ShaydZ-AVMo.xcodeproj` in Xcode to build the iOS app.

## 📁 Project Structure

```
ShaydZ-AVMo/
├── 📱 ShaydZ-AVMo/              # iOS app source code
│   ├── Services/                # Network and API services
│   ├── ViewModels/              # MVVM view models
│   ├── Views/                   # SwiftUI views
│   └── Models/                  # Data models
├── 🔧 backend/                  # Microservices backend
│   ├── api-gateway/             # Request routing service
│   ├── auth-service/            # Authentication service
│   ├── app-catalog/             # App management service
│   └── vm-orchestrator/         # VM lifecycle service
├── 🎮 demos/                    # Interactive demonstrations
│   ├── web-demos/               # HTML/CSS/JS demos
│   └── scripts/                 # Demo server utilities
├── 🔗 ios-integration/          # iOS-backend integration tools
│   ├── generated-swift/         # Swift integration code
│   └── scripts/                 # Integration utilities
├── 🐳 demo-production/          # Production-ready deployment
└── 📋 docs/                     # Documentation
```

## 🧪 Testing

### Backend Testing
```bash
npm test                    # Run all backend tests
npm run test:integration    # Integration tests
npm run test:performance    # Performance benchmarks
```

### iOS Integration Testing
```bash
cd ios-integration
node scripts/test-integration.js
```

### Results
- ✅ **45/45** backend tests passing
- ✅ **4/4** integration tests passing  
- ✅ **100%** backend service availability

## 🎮 Interactive Demos

Live demonstrations available at:

- 📱 **iOS App Simulator**: Interactive iOS interface with working login and navigation
- 📊 **Backend Monitor**: Real-time service health and API status
- 🔗 **Live API Demo**: Interactive backend service exploration

```bash
cd demos
npm start
# Visit http://localhost:3000/app-demo.html
```

## 📱 iOS App Features

- **SwiftUI Interface**: Modern iOS design with tab navigation
- **Authentication**: Secure login with JWT token management
- **App Library**: Browse and launch virtual applications
- **VM Management**: Monitor and control virtual machines
- **Real-time Updates**: Live data synchronization with backend

### Demo Credentials
- **Username**: `demo`
- **Password**: `password`

## 🔧 Development

### Backend Development
```bash
cd backend/[service-name]
npm install
npm run dev
```

### iOS Development
1. Open `ShaydZ-AVMo.xcodeproj` in Xcode
2. Configure API endpoints in `APIConfig.swift`
3. Build and run on simulator or device

### Integration Development
```bash
cd ios-integration
node scripts/check-backend.js      # Health check
node scripts/sync-services.js      # Data sync
node scripts/test-integration.js   # Full integration test
```

## 🐳 Deployment

### Development Environment
```bash
docker-compose up -d
```

### Production Deployment
```bash
cd demo-production
./deploy-production.sh
```

See [Production Deployment Guide](docs/PRODUCTION_DEPLOYMENT.md) for detailed instructions.

## 📊 API Documentation

### Authentication Endpoints
- `POST /api/login` - User authentication
- `GET /api/profile` - User profile data
- `POST /api/refresh` - Token refresh

### App Catalog Endpoints  
- `GET /api/apps` - List available applications
- `GET /api/apps/:id` - Get application details
- `POST /api/apps` - Create new application

### VM Management Endpoints
- `GET /api/vms` - List virtual machines
- `POST /api/vms/create` - Create new VM
- `POST /api/vms/:id/start` - Start VM
- `POST /api/vms/:id/stop` - Stop VM

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- SwiftUI framework for iOS development
- Docker for containerization
- Express.js for backend services
- MongoDB for data persistence

## 📞 Support

- **Documentation**: [docs/](docs/)
- **Issues**: GitHub Issues
- **Discussions**: GitHub Discussions

---

<div align="center">
  <p>Built with ❤️ by the ShaydZ AVMo Team</p>
  <p>🌟 Star this repo if you find it helpful!</p>
</div>
