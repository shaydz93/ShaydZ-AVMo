#!/bin/bash

echo "🚀 ShaydZ-AVMo Debug Build (No Auth Required)"
echo "=============================================="

# Set debug environment
export DEBUG_MODE=true
export SKIP_AUTH=true

echo ""
echo "📱 Building iOS app in debug mode..."

# Check if we're on macOS (required for iOS builds)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "✅ macOS detected - proceeding with iOS build"
    
    # Build the iOS project
    cd /workspaces/ShaydZ-AVMo
    
    echo "🔧 Building Xcode project..."
    xcodebuild -project ShaydZ-AVMo.xcodeproj \
               -scheme ShaydZ-AVMo \
               -configuration Debug \
               -destination 'platform=iOS Simulator,name=iPhone 15' \
               build
    
    if [ $? -eq 0 ]; then
        echo "✅ Build successful!"
        echo ""
        echo "🎯 Starting iOS Simulator..."
        
        # Open the simulator
        open -a Simulator
        
        echo ""
        echo "📲 Installing app on simulator..."
        xcodebuild -project ShaydZ-AVMo.xcodeproj \
                   -scheme ShaydZ-AVMo \
                   -configuration Debug \
                   -destination 'platform=iOS Simulator,name=iPhone 15' \
                   install
        
        echo ""
        echo "🎉 DEBUG MODE READY!"
        echo "Features available:"
        echo "  - ✅ No authentication required"
        echo "  - ✅ UTM-enhanced VM controls"
        echo "  - ✅ QEMU virtualization demo"
        echo "  - ✅ Performance monitoring UI"
        echo "  - ✅ Debug information panel"
        echo ""
        echo "🚀 Launch the ShaydZ-AVMo app from the simulator!"
        
    else
        echo "❌ Build failed. Check Xcode logs for details."
        exit 1
    fi
    
else
    echo "⚠️  Not running on macOS - iOS build not possible"
    echo ""
    echo "🔧 Alternative: Test backend services..."
    
    # Test backend without iOS
    echo "🌐 Starting backend services for testing..."
    
    cd backend
    if [ -f docker-compose.yml ]; then
        echo "🐳 Starting Docker services..."
        docker-compose up -d
        
        echo ""
        echo "🧪 Testing API endpoints..."
        sleep 5
        
        # Test auth service
        echo "Testing auth service..."
        curl -s http://localhost:3001/health && echo " ✅ Auth service" || echo " ❌ Auth service"
        
        # Test app catalog
        echo "Testing app catalog..."
        curl -s http://localhost:3002/health && echo " ✅ App catalog" || echo " ❌ App catalog"
        
        # Test VM orchestrator
        echo "Testing VM orchestrator..."
        curl -s http://localhost:3003/health && echo " ✅ VM orchestrator" || echo " ❌ VM orchestrator"
        
        echo ""
        echo "🎯 Backend services running!"
        echo "API Gateway: http://localhost:3000"
        echo ""
        echo "📱 Transfer to macOS for iOS app testing."
        
    else
        echo "❌ Docker Compose file not found"
        exit 1
    fi
fi

echo ""
echo "🔍 Debug build complete!"
