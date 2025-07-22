#!/bin/bash

# Demo Production iOS App Configuration Script
echo "================================================="
echo "  ShaydZ AVMo Demo iOS Configuration Script      "
echo "================================================="

# Check if APIConfig.swift exists
if [ ! -f "ShaydZ-AVMo/Services/APIConfig.swift" ]; then
  echo "Error: APIConfig.swift not found!"
  exit 1
fi

# Backup the current configuration
echo "Backing up current configuration..."
cp "ShaydZ-AVMo/Services/APIConfig.swift" "ShaydZ-AVMo/Services/APIConfig.swift.bak"

# Copy the demo production configuration
echo "Applying demo production configuration..."
cp "demo-production/APIConfig.swift" "ShaydZ-AVMo/Services/APIConfig.swift"

echo "================================================="
echo "iOS app configured for demo production environment!"
echo ""
echo "The iOS app will now use the local backend services:"
echo "API Gateway:      http://localhost:8080"
echo ""
echo "To revert to the original configuration:"
echo "cp \"ShaydZ-AVMo/Services/APIConfig.swift.bak\" \"ShaydZ-AVMo/Services/APIConfig.swift\""
echo "================================================="
