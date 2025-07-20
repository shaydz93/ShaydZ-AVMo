#!/bin/bash

# 🚀 ShaydZ AVMo Supabase Auto-Setup Script
# This script helps set up full Supabase integration

echo "🚀 ShaydZ AVMo - Full Supabase Integration Setup"
echo "================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Step 1: Check prerequisites
print_step "Step 1: Checking prerequisites..."

if command -v curl &> /dev/null; then
    print_success "curl is available"
else
    print_error "curl is required but not installed"
    exit 1
fi

if command -v jq &> /dev/null; then
    print_success "jq is available"
else
    print_warning "jq not found - installing for JSON parsing"
    # Try to install jq if possible
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y jq
    elif command -v brew &> /dev/null; then
        brew install jq
    else
        print_warning "Please install jq manually for better experience"
    fi
fi

echo ""

# Step 2: Prompt for Supabase configuration
print_step "Step 2: Supabase Configuration"
echo "If you don't have a Supabase project yet:"
echo "1. Go to https://supabase.com"
echo "2. Create a new project"
echo "3. Copy your project URL and anon key"
echo ""

read -p "Enter your Supabase Project URL (e.g., https://abc123.supabase.co): " SUPABASE_URL
read -p "Enter your Supabase Anon Key: " SUPABASE_KEY

if [[ -z "$SUPABASE_URL" || -z "$SUPABASE_KEY" ]]; then
    print_warning "Using demo configuration for local testing"
    SUPABASE_URL="http://localhost:8080"
    SUPABASE_KEY="demo_key_123"
else
    print_success "Using your Supabase project configuration"
fi

echo ""

# Step 3: Update configuration files
print_step "Step 3: Updating configuration files..."

# Create backup of current config
cp ShaydZ-AVMo/Services/SupabaseConfig.swift ShaydZ-AVMo/Services/SupabaseConfig.swift.backup

# Update SupabaseConfig.swift
cat > ShaydZ-AVMo/Services/SupabaseConfig.swift << EOF
import Foundation

/// Supabase configuration settings
struct SupabaseConfig {
    /// Your Supabase project URL
    static let supabaseURL = "$SUPABASE_URL"
    
    /// Your Supabase anon/public key  
    static let supabaseAnonKey = "$SUPABASE_KEY"
    
    /// API endpoints
    static var authURL: String {
        return "\\(supabaseURL)/auth/v1"
    }
    
    static var restURL: String {
        return "\\(supabaseURL)/rest/v1"
    }
    
    static var realtimeURL: String {
        return "\\(supabaseURL)/realtime/v1"
    }
    
    /// Headers for API requests
    static var defaultHeaders: [String: String] {
        return [
            "apikey": supabaseAnonKey,
            "Authorization": "Bearer \\(supabaseAnonKey)",
            "Content-Type": "application/json",
            "Prefer": "return=minimal"
        ]
    }
    
    /// Headers for authenticated requests
    static func authHeaders(token: String) -> [String: String] {
        var headers = defaultHeaders
        headers["Authorization"] = "Bearer \\(token)"
        return headers
    }
}
EOF

print_success "SupabaseConfig.swift updated"

# Step 4: Test connection (if real Supabase URL provided)
if [[ "$SUPABASE_URL" != "http://localhost:8080" ]]; then
    echo ""
    print_step "Step 4: Testing Supabase connection..."
    
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "apikey: $SUPABASE_KEY" \
        -H "Authorization: Bearer $SUPABASE_KEY" \
        "$SUPABASE_URL/rest/v1/")
    
    if [[ "$HTTP_STATUS" == "200" ]]; then
        print_success "✅ Supabase connection successful!"
        
        # Test if app_catalog table exists
        APP_CATALOG_TEST=$(curl -s \
            -H "apikey: $SUPABASE_KEY" \
            -H "Authorization: Bearer $SUPABASE_KEY" \
            "$SUPABASE_URL/rest/v1/app_catalog?limit=1" 2>/dev/null)
        
        if echo "$APP_CATALOG_TEST" | grep -q "\\[\\]\\|name"; then
            print_success "Database schema appears to be set up"
        else
            print_warning "Database schema not detected - you may need to run the SQL setup"
            echo "📝 Run this in your Supabase SQL Editor:"
            echo "   Copy contents from: SUPABASE_RLS_SETUP.sql"
        fi
    else
        print_warning "Connection test returned HTTP $HTTP_STATUS"
        print_warning "Please verify your URL and API key"
    fi
fi

echo ""

# Step 5: Generate environment file
print_step "Step 5: Creating environment configuration..."

cat > .env.supabase << EOF
# Supabase Configuration for ShaydZ AVMo
SUPABASE_URL=$SUPABASE_URL
SUPABASE_ANON_KEY=$SUPABASE_KEY

# Usage:
# export \$(cat .env.supabase | xargs)
# Then run your iOS app
EOF

print_success "Environment file created: .env.supabase"

echo ""

# Step 6: Show next steps
print_step "🎉 Setup Complete! Next Steps:"
echo ""
echo "📱 For iOS Development:"
echo "   1. Open ShaydZ-AVMo.xcodeproj in Xcode"
echo "   2. Build and run the project"
echo "   3. Test authentication features"
echo ""

if [[ "$SUPABASE_URL" != "http://localhost:8080" ]]; then
    echo "🗄️  Database Setup (if not done yet):"
    echo "   1. Go to your Supabase dashboard"
    echo "   2. Open SQL Editor" 
    echo "   3. Copy and paste contents from: SUPABASE_RLS_SETUP.sql"
    echo "   4. Click 'RUN' to create all tables"
    echo ""
    
    echo "🔐 Authentication Setup:"
    echo "   1. Go to Authentication → Settings"
    echo "   2. Set Site URL: com.shaydz.avmo://"
    echo "   3. Disable email confirmations for testing"
    echo ""
fi

echo "🧪 Testing:"
echo "   Run: bash test_supabase.sh"
echo ""

echo "📚 Documentation:"
echo "   • SUPABASE_FULL_INTEGRATION.md - Complete guide"
echo "   • SUPABASE_SETUP.md - Detailed setup"
echo "   • TESTING_GUIDE.md - Testing procedures"
echo ""

print_success "🎯 Your ShaydZ AVMo app is ready for full Supabase integration!"

echo ""
echo "💡 Pro Tips:"
echo "   • Keep your API keys secure"
echo "   • Enable Row Level Security (RLS) in production"
echo "   • Monitor usage in Supabase dashboard"
echo "   • Set up backups for production use"
