#!/bin/bash

# Demo Production Setup Script for ShaydZ AVMo
set -e

echo "================================================="
echo "      ShaydZ AVMo Demo Production Setup          "
echo "================================================="

# Check Docker is running
if ! docker info > /dev/null 2>&1; then
  echo "Docker is not running. Please start Docker and try again."
  exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
  echo "docker-compose is not installed or not in PATH"
  exit 1
fi

# Create local directory structure for MongoDB data
echo "Creating data directories..."
mkdir -p ./demo-production/data/mongo

# Build and run the demo production environment
echo "Building and starting services..."
cd ./demo-production
docker-compose up --build -d

# Wait for services to be available
echo "Waiting for services to start..."
sleep 5

# Check if services are running
echo "Checking services status..."

# Check API Gateway
if curl -s http://localhost:8080/health | grep -q "ok"; then
  echo "✅ API Gateway is running"
else
  echo "❌ API Gateway failed to start"
fi

# Check Auth Service
if curl -s http://localhost:8081/health | grep -q "ok"; then
  echo "✅ Auth Service is running"
else
  echo "❌ Auth Service failed to start"
fi

# Check VM Orchestrator
if curl -s http://localhost:8082/health | grep -q "ok"; then
  echo "✅ VM Orchestrator is running"
else
  echo "❌ VM Orchestrator failed to start"
fi

# Check App Catalog
if curl -s http://localhost:8083/health | grep -q "ok"; then
  echo "✅ App Catalog is running"
else
  echo "❌ App Catalog failed to start"
fi

echo "================================================="
echo "            Testing Authentication               "
echo "================================================="

# Test login
echo "Testing login with demo user..."
TOKEN=$(curl -s -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"demo","password":"password"}' | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -n "$TOKEN" ]; then
  echo "✅ Login successful! Token received:"
  echo "$TOKEN" > demo-token.txt
  echo "Token saved to demo-token.txt"
  
  # Test API calls with token
  echo "Testing API access with token..."
  
  # Check profile
  echo "Fetching user profile..."
  if curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/auth/profile | grep -q "username"; then
    echo "✅ Profile API works"
  else
    echo "❌ Profile API failed"
  fi
  
  # Check apps
  echo "Fetching apps..."
  if curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/catalog/apps | grep -q "Secure"; then
    echo "✅ App Catalog API works"
  else
    echo "❌ App Catalog API failed"
  fi
  
  # Check VMs
  echo "Fetching VMs..."
  if curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/vm/vms | grep -q "Android"; then
    echo "✅ VM Orchestrator API works"
  else
    echo "❌ VM Orchestrator API failed"
  fi
  
else
  echo "❌ Login failed"
fi

echo "================================================="
echo "Demo production environment is now running!"
echo ""
echo "API Gateway:      http://localhost:8080"
echo "Auth Service:     http://localhost:8081"
echo "VM Orchestrator:  http://localhost:8082"
echo "App Catalog:      http://localhost:8083"
echo ""
echo "Demo user credentials:"
echo "Username: demo"
echo "Password: password"
echo ""
echo "To stop the environment, run:"
echo "cd demo-production && docker-compose down"
echo "================================================="
