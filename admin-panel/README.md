# CivicSense Admin Panel

A modern, responsive admin panel for managing civic issues reported through the CivicSense mobile app.

## ✨ Features

- **Dashboard Overview**: Real-time statistics and analytics
- **Issue Management**: View, filter, and manage all reported issues
- **Status Updates**: Change issue status (Pending, In Progress, Resolved)
- **Authority Notes**: Add notes to issues for internal tracking
- **Real-time Updates**: Automatic updates when new issues are reported
- **Map Integration**: View issue locations on an interactive map
- **Responsive Design**: Works on desktop, tablet, and mobile devices
- **Easy Authentication**: Firebase Authentication integration

## 🚀 Quick Start

### Option 1: Deploy to Firebase Hosting (Recommended)

1. **Install Firebase CLI** (if not already installed)
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**
   ```bash
   firebase login
   ```

3. **Initialize Firebase Hosting**
   ```bash
   cd admin-panel
   firebase init hosting
   ```
   - Select your existing Firebase project: `civicsense-cca11`
   - Set public directory to: `.` (current directory)
   - Configure as single-page app: `Yes`
   - Don't overwrite existing files

4. **Deploy**
   ```bash
   firebase deploy --only hosting
   ```

5. **Access Your Admin Panel**
   - Your admin panel will be available at: `https://civicsense-cca11.web.app`
   - Or your custom domain if configured

### Option 2: Deploy to Netlify

1. **Install Netlify CLI**
   ```bash
   npm install -g netlify-cli
   ```

2. **Deploy**
   ```bash
   cd admin-panel
   netlify deploy --prod
   ```
   - Select "Create & configure a new site"
   - Follow the prompts
   - Set the deploy path to current directory (.)

3. **Your site is live!**
   - Netlify will provide you with a URL

### Option 3: Deploy to Vercel

1. **Install Vercel CLI**
   ```bash
   npm install -g vercel
   ```

2. **Deploy**
   ```bash
   cd admin-panel
   vercel --prod
   ```

3. **Your site is live!**
   - Vercel will provide you with a URL

### Option 4: Local Development/Testing

Simply open `index.html` in your web browser:

```bash
cd admin-panel
# On Windows
start index.html

# On Mac
open index.html

# On Linux
xdg-open index.html
```

Or use a simple local server:

```bash
# Python 3
python -m http.server 8000

# Python 2
python -m SimpleHTTPServer 8000

# Node.js (if you have http-server installed)
npx http-server -p 8000
```

Then open `http://localhost:8000` in your browser.

## 🔐 Setting Up Admin Users

To create admin users for the panel:

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. Navigate to your project: `civicsense-cca11`
3. Go to **Authentication** → **Users**
4. Click **Add User**
5. Enter email and password for the admin
6. Click **Add User**

Now you can login to the admin panel with these credentials!

## 📁 File Structure

```
admin-panel/
├── index.html          # Main HTML structure
├── styles.css          # All styling and responsive design
├── app.js             # Firebase integration and functionality
├── README.md          # This file
└── firebase.json      # Firebase hosting configuration
```

## 🎨 Features in Detail

### Dashboard
- **Statistics Cards**: See counts of pending, in-progress, and resolved issues at a glance
- **Issue Types Chart**: Visual breakdown of issues by category
- **Recent Activity**: Latest reported issues

### Issue Management
- **Search**: Find issues by title or description
- **Filter by Status**: View only pending, in-progress, or resolved issues
- **Filter by Type**: Filter issues by category
- **Sort Options**: Sort by newest, oldest, or most upvoted

### Issue Details
- **Full Information**: View all issue details including images, location, and description
- **Interactive Map**: See exact location of the issue on a map
- **Status Management**: Update issue status with one click
- **Authority Notes**: Add internal notes that are only visible to admins
- **Image Gallery**: View before and after images

## 🔒 Security

- Firebase Authentication ensures only authorized users can access the panel
- All data operations are secured by Firebase Security Rules
- No sensitive credentials are exposed in the client code

## 🎨 Customization

### Change Colors
Edit the CSS variables in `styles.css`:

```css
:root {
    --primary-color: #4F46E5;  /* Change this to your brand color */
    --secondary-color: #10B981;
    --danger-color: #EF4444;
    /* ... more colors */
}
```

### Modify Firebase Configuration
If you need to change Firebase settings, edit the `firebaseConfig` object in `app.js` (lines 2-11).

## 📱 Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)
- Mobile browsers (iOS Safari, Chrome Mobile)

## 🐛 Troubleshooting

### Login Issues
- Ensure you've created a user in Firebase Authentication
- Check that your Firebase API key is correct in `app.js`
- Check browser console for error messages

### Issues Not Loading
- Verify your Firestore database has an `issues` collection
- Check Firebase Security Rules allow read access
- Open browser DevTools and check the Console for errors

### Deployment Issues
- Ensure Firebase CLI is properly installed
- Verify you're logged into the correct Google account
- Check that you have the correct permissions for the Firebase project

## 💡 Tips

1. **Create a dedicated admin email**: Use something like admin@civicsense.com
2. **Regular backups**: Use Firebase's export features to backup your data
3. **Monitor usage**: Check Firebase Console for usage statistics
4. **Set up alerts**: Configure Firebase alerts for unusual activity

## 📄 License

This admin panel is part of the CivicSense project.

## 🤝 Support

For issues or questions:
1. Check the Troubleshooting section above
2. Review Firebase Console for errors
3. Check browser DevTools console for client-side errors

---

Made with ❤️ for CivicSense

