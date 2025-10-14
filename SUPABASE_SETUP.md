# Supabase Storage Setup Guide

## 🚀 Quick Setup Steps

### 1. Get Your Supabase Credentials

You have **two methods** to use Supabase Storage:

#### Method 1: Supabase SDK (Recommended - Easier)
1. Go to your Supabase project dashboard
2. Navigate to **Settings** → **API**
3. Copy your **Project URL** and **anon public** key

#### Method 2: S3-Compatible API (Already Configured!)
Your S3-compatible credentials are already configured:
- **Access Key**: `13d3957a4f2fc977b04f9ac0400f7ea3`
- **Secret Key**: `1d4057858d258b91d52e35ff5e3fcf413b95307894847d5237f3d173354ce6a5`
- **Endpoint**: `https://hfvgwhczmyuqjynhwxne.storage.supabase.co/storage/v1/s3`
- **Region**: `us-east-1`

### 2. Update Configuration

Edit `lib/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  // For Supabase SDK method (if you want to use it)
  static const String supabaseUrl = 'https://hfvgwhczmyuqjynhwxne.supabase.co';
  static const String supabaseAnonKey = 'YOUR_ACTUAL_SUPABASE_ANON_KEY_HERE'; // Only needed for SDK method
  
  // S3-compatible credentials (already configured!)
  static const String s3Endpoint = 'https://hfvgwhczmyuqjynhwxne.storage.supabase.co/storage/v1/s3';
  static const String s3Region = 'us-east-1';
  static const String s3AccessKey = '13d3957a4f2fc977b04f9ac0400f7ea3';
  static const String s3SecretKey = '1d4057858d258b91d52e35ff5e3fcf413b95307894847d5237f3d173354ce6a5';
  
  static const String storageBucket = 'images';
}
```

### 3. Create Storage Bucket

In your Supabase dashboard:

1. Go to **Storage** → **Buckets**
2. Click **New Bucket**
3. Name it `images` (or update the config to match your bucket name)
4. Set it to **Public** for now (you can restrict later)

### 4. Set Storage Policies

In Supabase Storage → Policies, add these policies:

**Policy 1: Allow public uploads**
```sql
CREATE POLICY "Allow public uploads" ON storage.objects
FOR INSERT WITH CHECK (bucket_id = 'images');
```

**Policy 2: Allow public reads**
```sql
CREATE POLICY "Allow public reads" ON storage.objects
FOR SELECT USING (bucket_id = 'images');
```

### 5. Install Dependencies

Run this command to install Supabase:

```bash
flutter pub get
```

## 🧪 Testing

### Test Both Methods
1. Run your app
2. Go to Citizen Home screen
3. Click the bug icon (🐛) in the top-right
4. **Toggle between methods** using the switch:
   - **Supabase SDK**: Uses the official Supabase Flutter SDK
   - **S3 Compatible**: Uses your S3-compatible credentials (already configured!)

### Test Connection
1. Select your preferred method using the switch
2. Click **Test Connection** button
3. Should show success for both methods

### Test Upload
1. Take a photo
2. Click **Test Upload**
3. Check the console logs for progress
4. Try both methods to see which works better

## 📁 File Structure

Your uploaded files will be stored in:
```
images/
├── issue_images/
│   ├── user123_1234567890.jpg
│   └── user456_1234567891.png
├── test_uploads/
│   └── test_1234567890.jpg
└── profile_images/
    └── user123_profile.jpg
```

## 🔧 Troubleshooting

### Common Issues:

1. **"Invalid API key"**
   - Check your anon key in `supabase_config.dart`
   - Make sure there are no extra spaces

2. **"Bucket not found"**
   - Verify bucket name in Supabase dashboard
   - Update `storageBucket` in config if needed

3. **"Permission denied"**
   - Check storage policies in Supabase
   - Make sure bucket is set to public

4. **"Upload failed"**
   - Check file size (max 10MB)
   - Verify file format (jpg, png, etc.)

## 🎯 Next Steps

1. **Add your Supabase credentials** to the config file
2. **Create the storage bucket** in Supabase dashboard
3. **Set up storage policies** for public access
4. **Test the upload functionality** using the debug screen

## 📞 Support

If you encounter issues:
1. Check the console logs for detailed error messages
2. Verify your Supabase project settings
3. Test with the debug screen first
4. Make sure your internet connection is stable

---

**Ready to test!** 🚀

Once you've updated the config with your credentials, your image uploads should work perfectly with Supabase Storage!
