#!/bin/bash
# Production Deployment Script for ShaydZ AVMo
# This script prepares and deploys the ShaydZ AVMo application to production

set -e # Exit on error

# Display ASCII art banner
echo "================================================="
echo "     ____  _                     _  __________    "
echo "    / ___|| |__   __ _ _   _  __| |/ ____/ __/ "
echo "    \___ \| '_ \ / _\` | | | |/ _\` /___ \/ _/  "
echo "     ___) | | | | (_| | |_| | (_| |___) / /___  "
echo "    |____/|_| |_|\__,_|\__, |\__,_|____/_____/  "
echo "                       |___/                   "
echo "     _    __     __  __                        "
echo "    / \   \ \   / / |  \/  | ___              "
echo "   / _ \   \ \ / /  | |\/| |/ _ \             "
echo "  / ___ \   \ V /   | |  | | (_) |            "
echo " /_/   \_\   \_/    |_|  |_|\___/             "
echo "================================================="
echo "Production Deployment Script - $(date)"
echo "================================================="

# Check for required tools
echo "[1/10] Checking required tools..."
command -v docker >/dev/null 2>&1 || { echo "Docker is required but not installed. Aborting."; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { echo "Docker Compose is required but not installed. Aborting."; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "Warning: kubectl not found. Kubernetes deployment will be skipped."; }

# Check environment variables
echo "[2/10] Checking environment variables..."
if [ -z "$SHAYDZ_ENV" ]; then
  echo "SHAYDZ_ENV not set, using 'production'"
  export SHAYDZ_ENV="production"
fi

if [ -z "$DOCKER_REGISTRY" ]; then
  echo "DOCKER_REGISTRY not set, using default registry"
  export DOCKER_REGISTRY="shaydz"
fi

# Create production config files
echo "[3/10] Creating production configuration files..."
mkdir -p config/production

# Backend configuration
if [ ! -f "backend/api-gateway/.env.production" ]; then
  echo "Creating API Gateway production config..."
  cat > backend/api-gateway/.env.production << EOL
NODE_ENV=production
PORT=8080
JWT_SECRET=${JWT_SECRET:-$(openssl rand -hex 32)}
LOG_LEVEL=info
AUTH_SERVICE_URL=http://auth-service:8081
VM_ORCHESTRATOR_URL=http://vm-orchestrator:8082
APP_CATALOG_URL=http://app-catalog:8083
EOL
fi

if [ ! -f "backend/auth-service/.env.production" ]; then
  echo "Creating Auth Service production config..."
  cat > backend/auth-service/.env.production << EOL
NODE_ENV=production
PORT=8081
JWT_SECRET=${JWT_SECRET:-$(openssl rand -hex 32)}
JWT_EXPIRATION=3600
REFRESH_TOKEN_EXPIRATION=2592000
DB_CONNECTION_STRING=${MONGO_AUTH_URI:-mongodb://mongo:27017/auth}
LOG_LEVEL=info
EOL
fi

if [ ! -f "backend/app-catalog/.env.production" ]; then
  echo "Creating App Catalog production config..."
  cat > backend/app-catalog/.env.production << EOL
NODE_ENV=production
PORT=8083
JWT_SECRET=${JWT_SECRET:-$(openssl rand -hex 32)}
DB_CONNECTION_STRING=${MONGO_APPS_URI:-mongodb://mongo:27017/apps}
STORAGE_BUCKET=${STORAGE_BUCKET:-shaydz-app-catalog}
LOG_LEVEL=info
EOL
fi

if [ ! -f "backend/vm-orchestrator/.env.production" ]; then
  echo "Creating VM Orchestrator production config..."
  cat > backend/vm-orchestrator/.env.production << EOL
FLASK_ENV=production
FLASK_APP=app.py
PORT=8082
JWT_SECRET=${JWT_SECRET:-$(openssl rand -hex 32)}
DB_CONNECTION_STRING=${MONGO_VMS_URI:-mongodb://mongo:27017/vms}
VM_STORAGE_PATH=/data/vms
LOG_LEVEL=INFO
EOL
fi

# Create production docker-compose file
echo "[4/10] Creating production Docker Compose file..."
cat > docker-compose.production.yml << EOL
version: '3.8'

services:
  api-gateway:
    image: ${DOCKER_REGISTRY}/shaydz-api-gateway:${IMAGE_TAG:-latest}
    env_file: ./backend/api-gateway/.env.production
    deploy:
      replicas: ${API_GATEWAY_REPLICAS:-2}
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
    restart: always
    networks:
      - avmo-network
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  auth-service:
    image: ${DOCKER_REGISTRY}/shaydz-auth-service:${IMAGE_TAG:-latest}
    env_file: ./backend/auth-service/.env.production
    deploy:
      replicas: ${AUTH_SERVICE_REPLICAS:-2}
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
    restart: always
    networks:
      - avmo-network
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  vm-orchestrator:
    image: ${DOCKER_REGISTRY}/shaydz-vm-orchestrator:${IMAGE_TAG:-latest}
    env_file: ./backend/vm-orchestrator/.env.production
    deploy:
      replicas: ${VM_ORCHESTRATOR_REPLICAS:-2}
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
    restart: always
    privileged: true
    networks:
      - avmo-network
    volumes:
      - vm_data:/data/vms
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  app-catalog:
    image: ${DOCKER_REGISTRY}/shaydz-app-catalog:${IMAGE_TAG:-latest}
    env_file: ./backend/app-catalog/.env.production
    deploy:
      replicas: ${APP_CATALOG_REPLICAS:-2}
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
    restart: always
    networks:
      - avmo-network
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

networks:
  avmo-network:
    driver: overlay

volumes:
  vm_data:
    driver: local
EOL

# Build docker images
echo "[5/10] Building Docker images..."
services=("api-gateway" "auth-service" "vm-orchestrator" "app-catalog")

for service in "${services[@]}"; do
  echo "Building $service..."
  docker build -t ${DOCKER_REGISTRY}/shaydz-${service}:${IMAGE_TAG:-latest} -f backend/${service}/Dockerfile backend/${service}
done

# Push docker images
echo "[6/10] Pushing Docker images to registry..."
if [ -n "$PUSH_IMAGES" ]; then
  for service in "${services[@]}"; do
    echo "Pushing ${DOCKER_REGISTRY}/shaydz-${service}:${IMAGE_TAG:-latest}..."
    docker push ${DOCKER_REGISTRY}/shaydz-${service}:${IMAGE_TAG:-latest}
  done
else
  echo "Skipping image push (set PUSH_IMAGES=1 to enable)"
fi

# Kubernetes deployment
echo "[7/10] Preparing Kubernetes manifests..."
if command -v kubectl >/dev/null 2>&1 && [ -n "$DEPLOY_K8S" ]; then
  if command -v kompose >/dev/null 2>&1; then
    kompose convert -f docker-compose.production.yml -o k8s/
    echo "Kubernetes manifests generated in k8s/ directory"
  else
    echo "kompose not found. Please install it to generate Kubernetes manifests."
  fi
else
  echo "Skipping Kubernetes deployment"
fi

# Update iOS app configuration
echo "[8/10] Updating iOS app configuration..."
if [ -f "ShaydZ-AVMo/ShaydZ-AVMo/Services/APIConfig.swift" ]; then
  cat > ShaydZ-AVMo/ShaydZ-AVMo/Services/APIConfig.swift << EOL
import Foundation

/// Central place to manage API configuration
struct APIConfig {
    /// The base URL for all API requests
    #if DEBUG
    static let baseURL = "http://localhost:8080/v1"
    #else
    static let baseURL = "${API_BASE_URL:-https://api.shaydz-avmo.io/v1}"
    #endif
    
    /// The endpoint for authentication
    static let authEndpoint = "\(baseURL)/auth"
    
    /// The endpoint for virtual machine operations
    static let vmEndpoint = "\(baseURL)/vm"
    
    /// The endpoint for app catalog operations
    static let appsEndpoint = "\(baseURL)/catalog"
    
    /// The WebSocket endpoint for VM streaming
    #if DEBUG
    static let wsEndpoint = "ws://localhost:8082/ws"
    #else
    static let wsEndpoint = "${WS_ENDPOINT:-wss://api.shaydz-avmo.io/ws}"
    #endif
    
    /// API request timeout in seconds
    static let requestTimeout: TimeInterval = ${REQUEST_TIMEOUT:-30.0}
    
    /// Token refresh threshold in seconds (refresh when less than this time remaining)
    static let tokenRefreshThreshold: TimeInterval = ${TOKEN_REFRESH_THRESHOLD:-300}
}
EOL
  echo "iOS API configuration updated"
else
  echo "iOS configuration file not found. Skipping update."
fi

# Set up monitoring
echo "[9/10] Setting up monitoring..."
if [ -n "$SETUP_MONITORING" ]; then
  echo "Setting up monitoring stack..."
  # This would deploy Prometheus, Grafana, etc.
  # Implementation depends on the deployment platform
else
  echo "Skipping monitoring setup (set SETUP_MONITORING=1 to enable)"
fi

# Deploy to production
echo "[10/10] Deploying to production..."
if [ -n "$DEPLOY_DOCKER" ]; then
  echo "Deploying with Docker Compose..."
  docker-compose -f docker-compose.production.yml up -d
elif [ -n "$DEPLOY_K8S" ] && command -v kubectl >/dev/null 2>&1; then
  echo "Deploying to Kubernetes..."
  kubectl apply -f k8s/
else
  echo "Skipping deployment (set DEPLOY_DOCKER=1 or DEPLOY_K8S=1 to enable)"
fi

echo "================================================="
echo "Deployment completed successfully!"
echo "================================================="
