# Firebase Setup Instructions for Dummy Data Script

## 🚨 **IMPORTANT: You need to set up Firebase credentials first!**

### Step 1: Get Firebase Service Account Key

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com/
   - Select your project: **civicsense-cca11**

2. **Navigate to Service Accounts**
   - Click the gear icon (⚙️) in the top left
   - Select "Project settings"
   - Go to the "Service accounts" tab

3. **Generate Private Key**
   - Click "Generate new private key"
   - Confirm the action in the popup
   - A JSON file will be downloaded

4. **Set Up the Key File**
   - Rename the downloaded file to: `firebase-service-account-key.json`
   - Place it in the `admin-panel` directory (same folder as `add_dummy_data.js`)

### Step 2: Install Dependencies

```bash
cd admin-panel
npm install
```

### Step 3: Run the Script

```bash
npm run add-dummy-data
```

## ✅ **Expected Output**

If everything is set up correctly, you should see:

```
🔥 Starting to add dummy data to Firebase...
👥 Adding dummy users...
✅ Added user: John Smith
✅ Added user: Sarah Johnson
... (more users)
📝 Adding dummy issues...
✅ Added issue: Large Pothole on Main Street
✅ Added issue: Broken Street Light
... (more issues)
🎉 Successfully added all dummy data to Firebase!
📊 Added 12 users and 10 issues
```

## 🔒 **Security Note**

- **NEVER** commit the `firebase-service-account-key.json` file to version control
- Add it to your `.gitignore` file
- Keep it secure and private

## 🆘 **Troubleshooting**

### Error: "Cannot find module 'firebase-admin'"
```bash
npm install
```

### Error: "Cannot find module './firebase-service-account-key.json'"
- Follow Step 1 above to download and place the service account key

### Error: "Permission denied"
- Make sure your Firebase project has Firestore enabled
- Verify the service account has the correct permissions

## 📁 **File Structure Should Look Like:**

```
admin-panel/
├── add_dummy_data.js
├── firebase-service-account-key.json  ← This file is required!
├── package.json
├── SETUP_INSTRUCTIONS.md
└── node_modules/ (after npm install)
```

## 🎯 **What This Script Does**

- Adds 12 dummy users (10 citizens, 2 authorities)
- Adds 10 realistic civic issues with images
- Populates your Firebase Firestore database
- Creates a realistic testing environment for your app

---

**Need help?** Make sure you've completed all steps above before running the script!
