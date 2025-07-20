#!/bin/bash

# 🔍 ShaydZ AVMo Comprehensive Debug Tool
# This script performs detailed analysis and debugging of the project

echo "🔍 ShaydZ AVMo - Comprehensive Debug Analysis"
echo "============================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
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

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Debug Analysis Functions

check_project_structure() {
    print_header "1. Project Structure Analysis"
    
    # Check main directories
    if [ -d "ShaydZ-AVMo" ]; then
        print_success "Main iOS project directory exists"
    else
        print_error "Main iOS project directory missing"
        return 1
    fi
    
    # Check Xcode project
    if [ -f "ShaydZ-AVMo.xcodeproj/project.pbxproj" ]; then
        print_success "Xcode project file exists"
    else
        print_error "Xcode project file missing"
    fi
    
    # Check key files
    local key_files=(
        "ShaydZ-AVMo/ShaydZAVMoApp.swift"
        "ShaydZ-AVMo/ContentView.swift"
        "ShaydZ-AVMo/Info.plist"
    )
    
    for file in "${key_files[@]}"; do
        if [ -f "$file" ]; then
            print_success "Found: $(basename $file)"
        else
            print_error "Missing: $(basename $file)"
        fi
    done
    
    echo ""
}

check_swift_files() {
    print_header "2. Swift Files Analysis"
    
    local swift_count=$(find ShaydZ-AVMo -name "*.swift" | wc -l)
    print_info "Total Swift files: $swift_count"
    
    # Check for empty files
    local empty_files=$(find ShaydZ-AVMo -name "*.swift" -size 0)
    if [ -z "$empty_files" ]; then
        print_success "No empty Swift files found"
    else
        print_error "Empty Swift files detected:"
        echo "$empty_files"
    fi
    
    # Check file sizes
    print_info "Largest Swift files:"
    find ShaydZ-AVMo -name "*.swift" -exec wc -l {} + | sort -nr | head -5
    
    echo ""
}

check_services() {
    print_header "3. Services Analysis"
    
    # Check Supabase services
    local supabase_services=(
        "SupabaseConfig.swift"
        "SupabaseAuthService.swift"
        "SupabaseNetworkService.swift"
        "SupabaseDatabaseService.swift"
        "SupabaseIntegrationManager.swift"
        "SupabaseDemoService.swift"
    )
    
    print_info "Supabase Services:"
    for service in "${supabase_services[@]}"; do
        if [ -f "ShaydZ-AVMo/Services/$service" ]; then
            local lines=$(wc -l < "ShaydZ-AVMo/Services/$service")
            print_success "$service ($lines lines)"
        else
            print_error "$service missing"
        fi
    done
    
    # Check other key services
    local core_services=(
        "AuthenticationService.swift"
        "AppCatalogService.swift"
        "VirtualMachineService.swift"
        "NetworkService.swift"
    )
    
    echo ""
    print_info "Core Services:"
    for service in "${core_services[@]}"; do
        if [ -f "ShaydZ-AVMo/Services/$service" ]; then
            local lines=$(wc -l < "ShaydZ-AVMo/Services/$service")
            print_success "$service ($lines lines)"
        else
            print_error "$service missing"
        fi
    done
    
    echo ""
}

check_backend_services() {
    print_header "4. Backend Services Status"
    
    # Check Docker services
    if command -v docker-compose &> /dev/null; then
        print_info "Docker Compose services:"
        docker-compose -f demo-production/docker-compose.yml ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || print_warning "Docker services not running"
    else
        print_warning "Docker Compose not available"
    fi
    
    # Test backend endpoints
    local endpoints=(
        "http://localhost:8080/health:API Gateway"
        "http://localhost:8081/health:Auth Service"
        "http://localhost:8082/health:VM Orchestrator"
        "http://localhost:8083/health:App Catalog"
    )
    
    echo ""
    print_info "Backend Health Check:"
    for endpoint in "${endpoints[@]}"; do
        local url=$(echo $endpoint | cut -d: -f1)
        local name=$(echo $endpoint | cut -d: -f2)
        
        if curl -s "$url" >/dev/null 2>&1; then
            print_success "$name responding"
        else
            print_warning "$name not responding"
        fi
    done
    
    echo ""
}

check_configuration() {
    print_header "5. Configuration Analysis"
    
    # Check Supabase config
    if [ -f "ShaydZ-AVMo/Services/SupabaseConfig.swift" ]; then
        print_info "Supabase Configuration:"
        local url=$(grep "supabaseURL" ShaydZ-AVMo/Services/SupabaseConfig.swift | head -1)
        echo "  $url"
        
        local key=$(grep "supabaseAnonKey" ShaydZ-AVMo/Services/SupabaseConfig.swift | head -1)
        echo "  $key"
        
        if grep -q "localhost" ShaydZ-AVMo/Services/SupabaseConfig.swift; then
            print_info "Using local/demo configuration"
        else
            print_info "Using production Supabase configuration"
        fi
    else
        print_error "SupabaseConfig.swift not found"
    fi
    
    # Check environment files
    if [ -f ".env.supabase" ]; then
        print_success "Supabase environment file exists"
    else
        print_info "No Supabase environment file (optional)"
    fi
    
    echo ""
}

check_integration_health() {
    print_header "6. Integration Health Check"
    
    # Check for potential issues
    print_info "Checking for common issues:"
    
    # Check for import conflicts
    local import_conflicts=$(grep -r "import.*Supabase" ShaydZ-AVMo --include="*.swift" | wc -l)
    if [ $import_conflicts -gt 0 ]; then
        print_warning "Found $import_conflicts Supabase imports - verify compatibility"
    fi
    
    # Check for missing dependencies
    if grep -q "Combine" ShaydZ-AVMo/ShaydZAVMoApp.swift; then
        print_success "Combine framework imported"
    else
        print_warning "Combine framework not imported in main app"
    fi
    
    # Check for error handling
    local error_handlers=$(grep -r "mapSupabaseError\|ErrorMappingExtensions" ShaydZ-AVMo --include="*.swift" | wc -l)
    if [ $error_handlers -gt 0 ]; then
        print_success "Error handling utilities in use ($error_handlers references)"
    else
        print_warning "Error handling utilities not being used"
    fi
    
    echo ""
}

check_debug_capabilities() {
    print_header "7. Debug Capabilities"
    
    # Check debug utilities
    if [ -f "ShaydZ-AVMo/Services/DebugModeHelper.swift" ]; then
        print_success "Debug utilities available"
    else
        print_warning "Debug utilities missing"
    fi
    
    # Check demo service
    if [ -f "ShaydZ-AVMo/Services/SupabaseDemoService.swift" ]; then
        local demo_tests=$(grep -c "TestResult\|addTestResult" ShaydZ-AVMo/Services/SupabaseDemoService.swift)
        print_success "Demo service with $demo_tests test capabilities"
    else
        print_warning "Demo service not available"
    fi
    
    # Check integration dashboard
    if [ -f "ShaydZ-AVMo/Views/SupabaseIntegrationDashboard.swift" ]; then
        print_success "Integration dashboard available"
    else
        print_warning "Integration dashboard missing"
    fi
    
    echo ""
}

generate_debug_summary() {
    print_header "8. Debug Summary & Recommendations"
    
    local total_files=$(find ShaydZ-AVMo -name "*.swift" | wc -l)
    local service_files=$(find ShaydZ-AVMo/Services -name "*.swift" | wc -l)
    local view_files=$(find ShaydZ-AVMo/Views -name "*.swift" | wc -l)
    local viewmodel_files=$(find ShaydZ-AVMo/ViewModels -name "*.swift" | wc -l)
    
    print_info "Project Statistics:"
    echo "  📁 Total Swift files: $total_files"
    echo "  🔧 Service files: $service_files"
    echo "  📱 View files: $view_files"
    echo "  🧠 ViewModel files: $viewmodel_files"
    
    echo ""
    print_info "Health Status:"
    
    # Overall health assessment
    local health_score=0
    local max_score=7
    
    # Check critical components
    [ -f "ShaydZ-AVMo.xcodeproj/project.pbxproj" ] && ((health_score++))
    [ -f "ShaydZ-AVMo/ShaydZAVMoApp.swift" ] && ((health_score++))
    [ -f "ShaydZ-AVMo/Services/SupabaseConfig.swift" ] && ((health_score++))
    [ -f "ShaydZ-AVMo/Services/AuthenticationService.swift" ] && ((health_score++))
    [ -f "ShaydZ-AVMo/Services/AppCatalogService.swift" ] && ((health_score++))
    [ -f "ShaydZ-AVMo/Views/SupabaseIntegrationDashboard.swift" ] && ((health_score++))
    [ $(find ShaydZ-AVMo -name "*.swift" -size 0 | wc -l) -eq 0 ] && ((health_score++))
    
    local health_percentage=$((health_score * 100 / max_score))
    
    if [ $health_percentage -ge 90 ]; then
        print_success "Project Health: Excellent ($health_percentage%)"
        echo "  🎉 Ready for development and deployment"
    elif [ $health_percentage -ge 70 ]; then
        print_success "Project Health: Good ($health_percentage%)"
        echo "  ✅ Minor issues may need attention"
    elif [ $health_percentage -ge 50 ]; then
        print_warning "Project Health: Fair ($health_percentage%)"
        echo "  ⚠️  Several issues need to be resolved"
    else
        print_error "Project Health: Poor ($health_percentage%)"
        echo "  🚨 Major issues need immediate attention"
    fi
    
    echo ""
    print_info "Next Steps:"
    echo "  1. 🍎 Open project in Xcode on macOS"
    echo "  2. 🔨 Build and test the project"
    echo "  3. 🧪 Use SupabaseIntegrationDashboard for testing"
    echo "  4. 🚀 Deploy to device or simulator"
    
    echo ""
}

# Main execution
main() {
    check_project_structure
    check_swift_files
    check_services
    check_backend_services
    check_configuration
    check_integration_health
    check_debug_capabilities
    generate_debug_summary
    
    echo -e "${GREEN}🎯 Debug analysis complete!${NC}"
    echo ""
}

# Run the debug analysis
main
