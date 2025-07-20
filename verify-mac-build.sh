#!/bin/bash

echo "🍎 ShaydZ AVMo - Mac Build Verification Script"
echo "=============================================="
echo ""

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "⚠️  This script is designed for macOS"
    echo "   Running basic checks anyway..."
    echo ""
fi

# Check Xcode availability
echo "🔍 Checking Xcode..."
if command -v xcodebuild >/dev/null 2>&1; then
    xcodebuild -version
    echo "✅ Xcode is available"
else
    echo "❌ Xcode not found"
    echo "   Install Xcode from the App Store"
fi
echo ""

# Check project structure
echo "🏗️  Verifying project structure..."
if [ -f "ShaydZ-AVMo.xcodeproj/project.pbxproj" ]; then
    echo "✅ Xcode project found"
else
    echo "❌ Xcode project not found"
    exit 1
fi

# Key files check
echo ""
echo "📋 Checking key Swift files..."
key_files=(
    "ShaydZ-AVMo/ShaydZAVMoApp.swift"
    "ShaydZ-AVMo/ContentView.swift"
    "ShaydZ-AVMo/Services/AppCatalogService.swift"
    "ShaydZ-AVMo/ViewModels/AppLibraryViewModel.swift"
    "ShaydZ-AVMo/Views/HomeView.swift"
    "ShaydZ-AVMo/Info.plist"
)

for file in "${key_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file missing"
    fi
done

echo ""
echo "🔧 Recent compilation fixes applied:"
echo "   • AppCatalogService: Added missing service definitions"
echo "   • AppLibraryViewModel: Fixed type annotations"
echo "   • ContentView: Updated to use HomeView"
echo "   • ShaydZAVMoApp: Simplified initialization"
echo "   • Info.plist: Updated TLS version to 1.2"
echo ""

# Try to build if on macOS
if [[ "$OSTYPE" == "darwin"* ]] && command -v xcodebuild >/dev/null 2>&1; then
    echo "🔨 Attempting build..."
    echo "   (This may take a few minutes)"
    echo ""
    
    if xcodebuild -project ShaydZ-AVMo.xcodeproj -scheme ShaydZ-AVMo -configuration Debug clean build 2>&1 | tee build.log; then
        echo ""
        echo "🎉 BUILD SUCCESSFUL!"
        echo "   The project compiles cleanly"
    else
        echo ""
        echo "❌ Build failed - check build.log for details"
        echo ""
        echo "📋 Common next steps:"
        echo "   1. Open Xcode and check the Issues navigator"
        echo "   2. Look for missing imports or dependencies"
        echo "   3. Verify iOS deployment target (15.0+)"
        echo "   4. Check signing & capabilities"
    fi
else
    echo "⏭️  Skipping build test (Xcode required)"
fi

echo ""
echo "📱 To open in Xcode:"
echo "   open ShaydZ-AVMo.xcodeproj"
echo ""
echo "🚀 To run on simulator:"
echo "   1. Select iPhone simulator in Xcode"
echo "   2. Press Cmd+R to build and run"
echo ""
