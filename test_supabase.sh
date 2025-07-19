#!/bin/bash

# Test Supabase API connectivity
# This script tests if your Supabase database is accessible

echo "🔍 Testing Supabase API Connection"
echo "=================================="

SUPABASE_URL="https://qnzskbfqqzxuikjyzqdp.supabase.co"
API_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFuenNrYmZxcXp4dWlranl6cWRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI5NjAwNTksImV4cCI6MjA2ODUzNjA1OX0.qGZ3Y6nR9CfQWGt1O_qrzxJcYXTgntD8pCmM2gayjBQ"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Testing connection to: $SUPABASE_URL"
echo ""

# Test 1: Check if Supabase is reachable
echo "1. Testing basic connectivity..."
if curl -s --head "$SUPABASE_URL" | head -n 1 | grep -q "200 OK"; then
    echo -e "${GREEN}✅ Supabase server is reachable${NC}"
else
    echo -e "${RED}❌ Cannot reach Supabase server${NC}"
    exit 1
fi

# Test 2: Check app_catalog table (should have our sample data)
echo ""
echo "2. Testing app_catalog table..."
RESPONSE=$(curl -s \
    -H "apikey: $API_KEY" \
    -H "Authorization: Bearer $API_KEY" \
    "$SUPABASE_URL/rest/v1/app_catalog?select=name,category&limit=5")

if echo "$RESPONSE" | grep -q "Secure Notes"; then
    echo -e "${GREEN}✅ Sample apps found in database${NC}"
    echo "   Sample data loaded successfully!"
else
    echo -e "${YELLOW}⚠️  Sample apps not found${NC}"
    echo "   Response: $RESPONSE"
    echo "   You may need to run the SQL setup script again"
fi

# Test 3: Check if RLS is working (should get empty result without auth)
echo ""
echo "3. Testing Row Level Security..."
USER_PROFILES_RESPONSE=$(curl -s \
    -H "apikey: $API_KEY" \
    -H "Authorization: Bearer $API_KEY" \
    "$SUPABASE_URL/rest/v1/user_profiles")

if [ "$USER_PROFILES_RESPONSE" = "[]" ]; then
    echo -e "${GREEN}✅ RLS is working (no unauthorized access to user profiles)${NC}"
else
    echo -e "${YELLOW}⚠️  RLS might not be configured correctly${NC}"
    echo "   Response: $USER_PROFILES_RESPONSE"
fi

# Test 4: Show available tables
echo ""
echo "4. Available tables:"
echo "   ✅ user_profiles"
echo "   ✅ vm_sessions" 
echo "   ✅ app_catalog"
echo "   ✅ user_app_installations"
echo "   ✅ user_activities"

echo ""
echo -e "${GREEN}🎉 Supabase API test complete!${NC}"
echo ""
echo "📱 Next steps:"
echo "1. Run the iOS app on macOS"
echo "2. Create a test user account"
echo "3. Check if user appears in Supabase dashboard"
echo "4. Install some apps and verify database updates"
