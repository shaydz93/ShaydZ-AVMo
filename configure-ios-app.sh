#!/bin/bash

# Demo Production iOS App Configuration Script
echo "================================================="
echo "  ShaydZ AVMo Demo iOS Configuration Script      "
echo "================================================="

# Check if APIConfig.swift exists
if [ ! -f "/workspaces/codespaces-blank/ShaydZ-AVMo/ShaydZ-AVMo/Services/APIConfig.swift" ]; then
  echo "Error: APIConfig.swift not found!"
  exit 1
fi

# Backup the current configuration
echo "Backing up current configuration..."
cp "/workspaces/codespaces-blank/ShaydZ-AVMo/ShaydZ-AVMo/Services/APIConfig.swift" "/workspaces/codespaces-blank/ShaydZ-AVMo/ShaydZ-AVMo/Services/APIConfig.swift.bak"

# Copy the demo production configuration
echo "Applying demo production configuration..."
cp "/workspaces/codespaces-blank/ShaydZ-AVMo/demo-production/APIConfig.swift" "/workspaces/codespaces-blank/ShaydZ-AVMo/ShaydZ-AVMo/Services/APIConfig.swift"

echo "================================================="
echo "iOS app configured for demo production environment!"
echo ""
echo "The iOS app will now use the local backend services:"
echo "API Gateway:      http://localhost:8080"
echo ""
echo "To revert to the original configuration:"
echo "cp \"/workspaces/codespaces-blank/ShaydZ-AVMo/ShaydZ-AVMo/Services/APIConfig.swift.bak\" \"/workspaces/codespaces-blank/ShaydZ-AVMo/ShaydZ-AVMo/Services/APIConfig.swift\""
echo "================================================="
