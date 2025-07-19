# Supabase Integration Setup Guide

This guide will help you set up Supabase for the ShaydZ AVMo iOS application.

## Prerequisites

1. A Supabase account (free tier available at [supabase.com](https://supabase.com))
2. Xcode 14.0 or later
3. iOS 15.0 or later

## Step 1: Create a Supabase Project

1. Sign up or log in to [Supabase](https://supabase.com)
2. Click "New Project"
3. Choose your organization
4. Enter project details:
   - Name: `ShaydZ-AVMo`
   - Database Password: (choose a strong password)
   - Region: (choose closest to your users)
5. Click "Create new project"

## Step 2: Database Schema Setup

Once your project is created, go to the SQL Editor and run these scripts to set up the database schema:

### User Profiles Table
```sql
-- Create user_profiles table
CREATE TABLE user_profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email TEXT,
    username TEXT UNIQUE,
    first_name TEXT,
    last_name TEXT,
    display_name TEXT,
    role TEXT DEFAULT 'user',
    is_active BOOLEAN DEFAULT true,
    biometric_enabled BOOLEAN DEFAULT false,
    last_login TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

-- Create trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### VM Sessions Table
```sql
-- Create vm_sessions table
CREATE TABLE vm_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    vm_instance_id TEXT NOT NULL,
    status TEXT DEFAULT 'starting',
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    ip_address TEXT,
    port INTEGER,
    connection_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE vm_sessions ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own VM sessions" ON vm_sessions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own VM sessions" ON vm_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own VM sessions" ON vm_sessions
    FOR UPDATE USING (auth.uid() = user_id);

-- Create trigger for updated_at
CREATE TRIGGER update_vm_sessions_updated_at
    BEFORE UPDATE ON vm_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### App Catalog Table
```sql
-- Create app_catalog table
CREATE TABLE app_catalog (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL,
    icon_url TEXT,
    version TEXT DEFAULT '1.0.0',
    is_active BOOLEAN DEFAULT true,
    required_permissions TEXT[],
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE app_catalog ENABLE ROW LEVEL SECURITY;

-- Create policy (apps are readable by all authenticated users)
CREATE POLICY "Authenticated users can view active apps" ON app_catalog
    FOR SELECT USING (auth.role() = 'authenticated' AND is_active = true);

-- Create trigger for updated_at
CREATE TRIGGER update_app_catalog_updated_at
    BEFORE UPDATE ON app_catalog
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### User App Installations Table
```sql
-- Create user_app_installations table
CREATE TABLE user_app_installations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    app_id UUID REFERENCES app_catalog(id) NOT NULL,
    installed_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    settings JSONB,
    UNIQUE(user_id, app_id)
);

-- Enable Row Level Security
ALTER TABLE user_app_installations ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own app installations" ON user_app_installations
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own app installations" ON user_app_installations
    FOR ALL USING (auth.uid() = user_id);
```

### User Activities Table
```sql
-- Create user_activities table
CREATE TABLE user_activities (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    activity_type TEXT NOT NULL,
    description TEXT NOT NULL,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE user_activities ENABLE ROW LEVEL SECURITY;

-- Create policy
CREATE POLICY "Users can view their own activities" ON user_activities
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own activities" ON user_activities
    FOR INSERT WITH CHECK (auth.uid() = user_id);
```

### Insert Sample Data
```sql
-- Insert sample apps
INSERT INTO app_catalog (name, description, category, version, is_active) VALUES
('Secure Notes', 'Encrypted note-taking application with zero-knowledge architecture', 'Productivity', '1.0.0', true),
('Enterprise Email', 'Secure email client with advanced encryption and compliance features', 'Communication', '2.1.0', true),
('Code Editor Pro', 'Professional code editor with syntax highlighting and debugging tools', 'Development', '3.5.2', true),
('Financial Dashboard', 'Real-time financial data and analytics platform', 'Finance', '1.2.1', true),
('Team Chat', 'Secure team communication with file sharing and video calls', 'Communication', '4.0.0', true),
('Document Vault', 'Secure document storage with advanced sharing controls', 'Productivity', '2.0.3', true),
('Remote Desktop', 'Secure remote access to desktop environments', 'Productivity', '1.8.0', true),
('VPN Manager', 'Enterprise VPN management and monitoring tool', 'Security', '2.5.1', true);
```

## Step 3: Configure Authentication

1. Go to Authentication → Settings in your Supabase dashboard
2. Configure the following settings:
   - **Site URL**: `com.shaydz.avmo://`
   - **Redirect URLs**: Add any additional URLs you need
3. Enable email authentication
4. Optional: Enable other providers (Google, Apple, etc.)

## Step 4: Get Your Project Keys

1. Go to Settings → API in your Supabase dashboard
2. Copy the following values:
   - **Project URL**: `https://your-project-id.supabase.co`
   - **Anon/Public Key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

## Step 5: Update iOS App Configuration

1. Open `/ShaydZ-AVMo/Services/SupabaseConfig.swift`
2. Replace the placeholder values:

```swift
struct SupabaseConfig {
    /// Your Supabase project URL
    static let supabaseURL = "https://your-project-id.supabase.co"
    
    /// Your Supabase anon/public key
    static let supabaseAnonKey = "your-anon-key-here"
    
    // ... rest of the configuration
}
```

## Step 6: Update Xcode Project

1. Open `ShaydZ-AVMo.xcodeproj` in Xcode
2. Add the new Supabase service files to your project:
   - `SupabaseConfig.swift`
   - `SupabaseModels.swift`
   - `SupabaseNetworkService.swift`
   - `SupabaseAuthService.swift`
   - `SupabaseDatabaseService.swift`

3. Make sure these files are added to the correct target and compile group

## Step 7: Test the Integration

1. Build and run the app
2. Try creating a new account
3. Sign in with the account
4. Test VM functionality
5. Test app catalog features

## Security Considerations

1. **Row Level Security (RLS)**: All tables have RLS enabled to ensure users can only access their own data
2. **API Keys**: The anon key is safe to use in client applications as it respects RLS policies
3. **HTTPS**: All communication with Supabase is encrypted via HTTPS
4. **JWT Tokens**: Authentication uses secure JWT tokens with automatic refresh

## Environment-Specific Configuration

For different environments (development, staging, production), you can:

1. Create separate Supabase projects for each environment
2. Use different configuration files or build configurations
3. Set up proper CI/CD with environment variables

## Troubleshooting

### Common Issues:

1. **Authentication errors**: Check your Site URL and Redirect URLs
2. **Database access errors**: Verify RLS policies are correctly set up
3. **Network errors**: Ensure your project URL and API key are correct
4. **Build errors**: Make sure all Supabase files are properly added to the Xcode project

### Debug Tips:

1. Check the Supabase dashboard logs for API errors
2. Use the Supabase SQL editor to test queries directly
3. Enable verbose logging in the iOS app for network requests
4. Use Xcode's Network debugging tools

## Next Steps

1. Set up real-time subscriptions for live updates
2. Implement push notifications via Supabase Edge Functions
3. Add file storage using Supabase Storage
4. Set up monitoring and analytics
5. Configure backup and disaster recovery

## Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase iOS Guide](https://supabase.com/docs/guides/getting-started/tutorials/with-ios)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Supabase CLI](https://supabase.com/docs/guides/cli)
