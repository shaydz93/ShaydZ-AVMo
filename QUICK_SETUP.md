# Quick Supabase Setup Guide

Your Supabase project is configured with the API key! Follow these steps to complete the setup:

## 🚀 Your Configuration
- **Project URL**: `https://qnzskbfqqzxuikjyzqdp.supabase.co`
- **API Key**: Already configured in `SupabaseConfig.swift`

## ⚡ Quick Setup Steps

### 1. Set Up Database Schema
1. Go to your Supabase dashboard: https://supabase.com/dashboard/project/qnzskbfqqzxuikjyzqdp
2. Navigate to **SQL Editor**
3. Copy and paste the contents of `SUPABASE_RLS_SETUP.sql`
4. Click **Run** to execute all the database setup commands

### 2. Configure Authentication
1. Go to **Authentication** → **Settings**
2. Set **Site URL** to: `com.shaydz.avmo://`
3. Make sure **Enable email confirmations** is **disabled** for testing (you can enable it later)

### 3. Test the Integration
1. Build and run your iOS app in Xcode
2. Try the demo account: `demo` / `password` (this will still work)
3. Try creating a new account with a real email
4. Test the VM functionality
5. Check the app catalog

## 🔍 Verify RLS is Working

After running the SQL setup, you can verify RLS is properly configured:

1. In Supabase SQL Editor, run:
```sql
-- Check RLS status
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND rowsecurity = true;
```

2. You should see all these tables with RLS enabled:
   - `user_profiles`
   - `vm_sessions` 
   - `app_catalog`
   - `user_app_installations`
   - `user_activities`

## 📱 Features Now Available

### Authentication
- ✅ User registration with email/password
- ✅ Secure login/logout
- ✅ Password reset (email-based)
- ✅ User profile management
- ✅ Automatic user profile creation

### Data Management
- ✅ VM session tracking and history
- ✅ App installation management
- ✅ User activity logging
- ✅ Real-time data synchronization

### Security
- ✅ Row Level Security (RLS) enabled
- ✅ Users can only access their own data
- ✅ Secure JWT token authentication
- ✅ Encrypted API communications

## 🛠️ Troubleshooting

### If you get authentication errors:
1. Check the Site URL in Authentication settings
2. Make sure email confirmations are disabled for testing
3. Verify the API key is correctly set in `SupabaseConfig.swift`

### If you get database errors:
1. Make sure you ran the complete SQL setup from `SUPABASE_RLS_SETUP.sql`
2. Check that RLS policies are created correctly
3. Verify all tables exist in the **Table Editor**

### If the app won't build:
1. Make sure all new Supabase files are added to your Xcode project
2. Check that the target membership is correct for all files
3. Clean and rebuild the project

## 📊 Monitor Your Database

You can monitor your app's usage in the Supabase dashboard:

1. **Table Editor**: View and edit your data
2. **Authentication**: See registered users
3. **API Logs**: Monitor API requests
4. **Database**: Check performance and usage

## 🎯 Next Steps

Once everything is working:

1. **Enable Email Confirmations**: In Authentication → Settings
2. **Add Custom Domains**: For production deployment
3. **Set Up Backup**: Configure automated backups
4. **Monitor Performance**: Set up alerts and monitoring

Your app now has a production-ready backend! 🎉
