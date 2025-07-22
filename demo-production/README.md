# ShaydZ AVMo Demo Production Environment

This directory contains a simplified production-like environment for testing the ShaydZ AVMo application. It includes:

1. A full backend microservice architecture
2. MongoDB database
3. Configuration for iOS app integration

## Architecture

The demo production environment consists of the following components:

- **API Gateway**: Routes requests to the appropriate backend services (Port 8080)
- **Auth Service**: Handles authentication and user management (Port 8081)
- **VM Orchestrator**: Manages virtual machine instances (Port 8082)
- **App Catalog**: Provides app repository functionality (Port 8083)
- **MongoDB**: Database for storing user, VM, and app data (Port 27017)

## Running the Demo Production Environment

To start the demo production environment:

```bash
./run-demo-production.sh
```

This script will:
1. Build and start all Docker containers
2. Verify all services are running correctly
3. Test the API functionality with a demo user account
4. Save a valid authentication token for testing

## Connecting the iOS App to Demo Production

To configure the iOS app to use the demo production environment:

```bash
./configure-ios-app.sh
```

This will modify the `APIConfig.swift` file to point to your local demo production services.

## Demo User Credentials

The following credentials can be used to test the application:

- **Username**: demo
- **Password**: password

## Testing the API Directly

You can test the API endpoints using cURL:

```bash
# Login and get token
TOKEN=$(curl -s -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"demo","password":"password"}' | grep -o '"token":"[^"]*' | cut -d'"' -f4)

# Get user profile
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/auth/profile

# Get available apps
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/catalog/apps

# Get virtual machines
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/vm/vms
```

## Stopping the Environment

To stop the demo production environment:

```bash
cd demo-production && docker-compose down
```

## Production vs. Demo Differences

This demo environment is simplified compared to a real production deployment:

1. No SSL/TLS encryption
2. No horizontal scaling or high availability
3. Single MongoDB instance instead of a replica set
4. No monitoring or logging infrastructure
5. Uses embedded Docker volumes instead of persistent cloud storage

For a full production deployment, refer to the `/docs/PRODUCTION_DEPLOYMENT.md` guide.
