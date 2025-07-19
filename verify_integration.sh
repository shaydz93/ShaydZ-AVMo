#!/bin/bash

# ShaydZ-AVMo Integration Verification Script
# Run this on macOS to verify the setup

echo "🚀 ShaydZ-AVMo Integration Verification"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}❌ This script requires macOS to build iOS apps${NC}"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ Xcode is not installed or not in PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✅ macOS and Xcode detected${NC}"

# Check if project exists
if [ ! -f "ShaydZ-AVMo.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}❌ ShaydZ-AVMo.xcodeproj not found${NC}"
    echo "Please run this script from the project root directory"
    exit 1
fi

echo -e "${GREEN}✅ Project file found${NC}"

# Check Supabase configuration
if [ -f "ShaydZ-AVMo/Services/SupabaseConfig.swift" ]; then
    if grep -q "https://qnzskbfqqzxuikjyzqdp.supabase.co" "ShaydZ-AVMo/Services/SupabaseConfig.swift"; then
        echo -e "${GREEN}✅ Supabase configuration found${NC}"
    else
        echo -e "${YELLOW}⚠️  Supabase URL might not be configured${NC}"
    fi
else
    echo -e "${RED}❌ Supabase configuration not found${NC}"
    exit 1
fi

# Test build
echo ""
echo "🔨 Building iOS app..."
echo "======================"

xcodebuild -project ShaydZ-AVMo.xcodeproj \
    -scheme ShaydZ-AVMo \
    -configuration Debug \
    -destination "platform=iOS Simulator,name=iPhone 15" \
    build

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build successful!${NC}"
    echo ""
    echo "🎯 Next Steps:"
    echo "=============="
    echo "1. Open ShaydZ-AVMo.xcodeproj in Xcode"
    echo "2. Select iPhone 15 simulator"
    echo "3. Press ⌘+R to run the app"
    echo "4. Test sign up with: test@shaydz.com"
    echo "5. Check Supabase dashboard for new user"
    echo ""
    echo "📖 See TESTING_GUIDE.md for detailed testing steps"
else
    echo -e "${RED}❌ Build failed!${NC}"
    echo ""
    echo "🔧 Troubleshooting:"
    echo "==================="
    echo "1. Check that all Swift files compile"
    echo "2. Verify import statements are correct"
    echo "3. Ensure all dependencies are available"
    echo "4. Check Xcode build logs for specific errors"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Integration verification complete!${NC}"
echo "Your ShaydZ-AVMo app is ready for testing."
