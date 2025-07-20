#!/bin/bash

# ShaydZ AVMo - Mac Quick Setup Script
# Run this script on your Mac after extracting the project

echo "🍎 ShaydZ AVMo - Mac Setup Script"
echo "================================="
echo ""

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script is designed for macOS"
    exit 1
fi

echo "🔍 Checking prerequisites..."

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "⚠️  Xcode not found. Please install Xcode from the App Store"
    echo "   Then run: xcode-select --install"
else
    echo "✅ Xcode found"
fi

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo "⚠️  Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "✅ Homebrew found"
fi

# Install dependencies
echo ""
echo "📦 Installing dependencies..."
brew install node python3 || echo "⚠️  Some dependencies may already be installed"

# Optional: Install Docker for backend development
read -p "🐳 Install Docker for backend development? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    brew install --cask docker
    echo "✅ Docker installed. Please start Docker.app from Applications"
fi

echo ""
echo "🚀 Setup complete! Next steps:"
echo ""
echo "1. 📱 iOS Development:"
echo "   open ShaydZ-AVMo.xcodeproj"
echo ""
echo "2. 🌐 Demo Dashboard:"
echo "   python3 -m http.server 3001"
echo "   # Then open: http://localhost:3001/demo-dashboard.html"
echo ""
echo "3. 🐳 Backend Services (optional):"
echo "   cd demo-production"
echo "   docker-compose up -d"
echo ""
echo "🎉 Your ShaydZ AVMo project is ready for Mac development!"

# Make the script executable
chmod +x "$0"
