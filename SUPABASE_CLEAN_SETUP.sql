-- =================================================================
-- ShaydZ-AVMo Supabase Database Setup
-- Copy and paste this entire script into Supabase SQL Editor
-- =================================================================

-- 1. Create helper functions
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, username, first_name, last_name, display_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'username', NEW.email),
        NEW.raw_user_meta_data->>'first_name',
        NEW.raw_user_meta_data->>'last_name',
        COALESCE(
            NEW.raw_user_meta_data->>'display_name',
            CONCAT(NEW.raw_user_meta_data->>'first_name', ' ', NEW.raw_user_meta_data->>'last_name'),
            NEW.email
        )
    );
    RETURN NEW;
END;
$$ language 'plpgsql' SECURITY DEFINER;

-- 2. Create user_profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT,
    username TEXT UNIQUE,
    first_name TEXT,
    last_name TEXT,
    display_name TEXT,
    role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin', 'moderator')),
    subscription_tier TEXT DEFAULT 'free' CHECK (subscription_tier IN ('free', 'pro', 'enterprise')),
    max_vm_instances INTEGER DEFAULT 1,
    max_storage_gb INTEGER DEFAULT 10,
    preferences JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON user_profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON user_profiles;

CREATE POLICY "Users can view their own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Enable insert for authenticated users only" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 3. Create vm_sessions table
CREATE TABLE IF NOT EXISTS vm_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    vm_instance_id TEXT NOT NULL,
    status TEXT DEFAULT 'starting' CHECK (status IN ('starting', 'running', 'stopping', 'stopped', 'ended', 'error')),
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    ip_address TEXT,
    port INTEGER,
    connection_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE vm_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own VM sessions" ON vm_sessions;
DROP POLICY IF EXISTS "Users can create their own VM sessions" ON vm_sessions;
DROP POLICY IF EXISTS "Users can update their own VM sessions" ON vm_sessions;

CREATE POLICY "Users can view their own VM sessions" ON vm_sessions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own VM sessions" ON vm_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own VM sessions" ON vm_sessions
    FOR UPDATE USING (auth.uid() = user_id);

DROP TRIGGER IF EXISTS update_vm_sessions_updated_at ON vm_sessions;
CREATE TRIGGER update_vm_sessions_updated_at
    BEFORE UPDATE ON vm_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX IF NOT EXISTS idx_vm_sessions_user_id ON vm_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_vm_sessions_status ON vm_sessions(status);

-- 4. Create app_catalog table
CREATE TABLE IF NOT EXISTS app_catalog (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL,
    icon_url TEXT,
    version TEXT DEFAULT '1.0.0',
    is_active BOOLEAN DEFAULT true,
    required_permissions TEXT[],
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE app_catalog ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can view active apps" ON app_catalog;

CREATE POLICY "Authenticated users can view active apps" ON app_catalog
    FOR SELECT USING (auth.role() = 'authenticated' AND is_active = true);

DROP TRIGGER IF EXISTS update_app_catalog_updated_at ON app_catalog;
CREATE TRIGGER update_app_catalog_updated_at
    BEFORE UPDATE ON app_catalog
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX IF NOT EXISTS idx_app_catalog_category ON app_catalog(category);
CREATE INDEX IF NOT EXISTS idx_app_catalog_active ON app_catalog(is_active);

-- 5. Create user_app_installations table
CREATE TABLE IF NOT EXISTS user_app_installations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    app_id UUID REFERENCES app_catalog(id) ON DELETE CASCADE NOT NULL,
    installed_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    settings JSONB DEFAULT '{}',
    UNIQUE(user_id, app_id)
);

ALTER TABLE user_app_installations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own app installations" ON user_app_installations;
DROP POLICY IF EXISTS "Users can manage their own app installations" ON user_app_installations;

CREATE POLICY "Users can view their own app installations" ON user_app_installations
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own app installations" ON user_app_installations
    FOR ALL USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_user_app_installations_user_id ON user_app_installations(user_id);
CREATE INDEX IF NOT EXISTS idx_user_app_installations_app_id ON user_app_installations(app_id);

-- 6. Create user_activities table
CREATE TABLE IF NOT EXISTS user_activities (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    activity_type TEXT NOT NULL,
    description TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE user_activities ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own activities" ON user_activities;
DROP POLICY IF EXISTS "Users can create their own activities" ON user_activities;

CREATE POLICY "Users can view their own activities" ON user_activities
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own activities" ON user_activities
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_user_activities_user_id ON user_activities(user_id);
CREATE INDEX IF NOT EXISTS idx_user_activities_type ON user_activities(activity_type);
CREATE INDEX IF NOT EXISTS idx_user_activities_created_at ON user_activities(created_at DESC);

-- 7. Insert sample data
INSERT INTO app_catalog (name, description, category, version, is_active) 
SELECT * FROM (VALUES
    ('Secure Notes', 'Encrypted note-taking application with zero-knowledge architecture', 'Productivity', '1.0.0', true),
    ('Enterprise Email', 'Secure email client with advanced encryption and compliance features', 'Communication', '2.1.0', true),
    ('Code Editor Pro', 'Professional code editor with syntax highlighting and debugging tools', 'Development', '3.5.2', true),
    ('Financial Dashboard', 'Real-time financial data and analytics platform', 'Finance', '1.2.1', true),
    ('Team Chat', 'Secure team communication with file sharing and video calls', 'Communication', '4.0.0', true),
    ('Document Vault', 'Secure document storage with advanced sharing controls', 'Productivity', '2.0.3', true),
    ('Remote Desktop', 'Secure remote access to desktop environments', 'Productivity', '1.8.0', true),
    ('VPN Manager', 'Enterprise VPN management and monitoring tool', 'Security', '2.5.1', true),
    ('Password Manager', 'Secure password storage and generation tool', 'Security', '3.1.0', true),
    ('File Transfer', 'Secure file transfer with end-to-end encryption', 'Productivity', '2.2.0', true)
) AS v(name, description, category, version, is_active)
WHERE NOT EXISTS (
    SELECT 1 FROM app_catalog WHERE app_catalog.name = v.name
);

-- =================================================================
-- Setup Complete! 
-- 
-- Your database now has:
-- ✅ User profiles with automatic creation
-- ✅ VM session tracking
-- ✅ App catalog with sample apps
-- ✅ User app installations
-- ✅ Activity logging
-- ✅ Row Level Security (RLS) enabled
-- ✅ Performance indexes
-- 
-- Test by creating a user in your iOS app!
-- =================================================================
