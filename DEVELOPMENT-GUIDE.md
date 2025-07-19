# ShaydZ AVMo Development Guide

## 🎯 Current Project Status

### ✅ Completed
- Backend microservices architecture (API Gateway, Auth, App Catalog, VM Orchestrator)
- MongoDB database with demo data (12 apps, 2 VMs, demo user)
- Docker containerization and demo production environment
- Comprehensive test suites (unit, integration, performance)
- iOS integration code generation (Swift/SwiftUI)
- Development environment setup

### 🚧 In Progress
- iOS app integration with backend services
- Xcode project configuration
- UI/UX improvements

### 📋 Planned
- Advanced iOS features (offline mode, push notifications)
- Production deployment pipeline
- App Store preparation

## 🛠️ Development Environment

### Backend Services
```bash
# Start all services
cd demo-production
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs -f [service-name]

# Stop services
docker-compose down
```

### iOS Development
```bash
# Test backend integration
cd ios-integration
npm run test:integration

# Generate Swift code
npm run generate:swift

# Setup Xcode integration
npm run setup:xcode

# Complete setup
npm run setup:complete
```

## 📱 iOS App Architecture

### Core Components
- **NetworkService** - HTTP client with Combine publishers
- **ViewModels** - Authentication, App Catalog, VM Management
- **Views** - SwiftUI interfaces with backend integration
- **APIConfig** - Centralized configuration management

### Data Flow
1. User interaction → ViewModel
2. ViewModel → NetworkService
3. NetworkService → Backend API
4. Response → ViewModel (via Combine)
5. ViewModel → SwiftUI View (automatic UI update)

### Authentication Flow
1. Login credentials → AuthenticationViewModel
2. POST /login → Auth Service (port 8081)
3. JWT token received and stored
4. Token included in subsequent API requests
5. Automatic logout on token expiry

## 🔧 API Endpoints

### Authentication Service (port 8081)
- `POST /login` - User authentication
- `GET /health` - Service health check
- `GET /profile` - User profile (authenticated)

### App Catalog Service (port 8083)
- `GET /apps` - List all apps (authenticated)
- `GET /apps/search?q=query` - Search apps
- `GET /apps/:id` - App details

### VM Orchestrator Service (port 8082)
- `GET /vms` - List virtual machines (authenticated)
- `POST /vms/:id/start` - Start VM
- `POST /vms/:id/stop` - Stop VM
- `GET /vms/:id/status` - VM status

### API Gateway (port 8080)
- Proxy for all backend services
- Request routing and load balancing
- Centralized logging and monitoring

## 🧪 Testing Strategy

### Backend Testing
```bash
# Unit tests
cd backend/[service]
npm test

# Integration tests
cd ios-integration
npm run test:integration

# Performance tests
npm run test:performance
```

### iOS Testing
```bash
# API connectivity
npm run test:integration

# UI testing in Xcode
# Unit tests: ⌘+U
# UI tests: Configure test targets
```

## 🚀 Deployment Guide

### Development
1. Start backend services: `docker-compose up -d`
2. Open Xcode project: `open ShaydZ-AVMo.xcodeproj`
3. Build and run iOS app
4. Test with demo credentials (demo/password)

### Production
1. Update API endpoints in APIConfig.swift
2. Configure production backend infrastructure
3. Set up CI/CD pipeline
4. Prepare App Store build

## 🔍 Troubleshooting

### Common Issues

**Backend Services Not Starting**
- Check Docker daemon is running
- Verify port availability (8080-8083, 27017)
- Review docker-compose logs

**iOS Build Errors**
- Clean build folder (⌘+Shift+K)
- Verify all Swift files added to target
- Check Info.plist network permissions

**API Connection Issues**
- Verify backend services are running
- Check network permissions in Info.plist
- Test with integration scripts first

**Authentication Failures**
- Verify demo credentials (demo/password)
- Check token expiry (1 hour default)
- Review auth service logs

### Debug Commands
```bash
# Check service health
curl http://localhost:8081/health
curl http://localhost:8082/health
curl http://localhost:8083/health

# Test authentication
curl -X POST http://localhost:8081/login \
  -H "Content-Type: application/json" \
  -d '{"username":"demo","password":"password"}'

# Test API endpoints
npm run test:integration
```

## 📊 Performance Metrics

### Current Benchmarks
- Authentication: ~3ms response time
- App Catalog: ~5ms response time
- VM Management: ~3ms response time
- Database queries: <10ms average

### Optimization Targets
- API response time: <100ms (95th percentile)
- iOS app launch time: <3 seconds
- UI responsiveness: <16ms frame time

## 🔐 Security Considerations

### Development
- JWT tokens with 1-hour expiry
- HTTP-only for development (localhost)
- Demo credentials for testing

### Production
- HTTPS enforced
- Token refresh mechanism
- Secure credential storage
- API rate limiting
- Input validation and sanitization

## 🎨 UI/UX Guidelines

### Design Principles
- Native iOS design patterns
- Consistent navigation
- Clear feedback for user actions
- Accessibility compliance

### SwiftUI Best Practices
- Use @StateObject for ViewModels
- Implement proper error handling
- Optimize for different screen sizes
- Follow iOS Human Interface Guidelines

## 📈 Next Development Milestones

### Week 1: Core Integration
- [ ] Complete Xcode setup
- [ ] Test basic app functionality
- [ ] Verify all API integrations

### Week 2: UI Polish
- [ ] Implement custom UI themes
- [ ] Add loading animations
- [ ] Improve error handling

### Week 3: Advanced Features
- [ ] Offline data caching
- [ ] Push notifications
- [ ] Biometric authentication

### Week 4: Production Prep
- [ ] Production API configuration
- [ ] Performance optimization
- [ ] App Store submission prep

## 🆘 Getting Help

### Resources
- Generated integration instructions
- API documentation in backend services
- iOS integration test results
- Development logs and metrics

### Commands for Assistance
```bash
# Check current status
npm run test:integration

# View backend logs
npm run logs:backend

# Regenerate iOS code
npm run generate:swift
```
