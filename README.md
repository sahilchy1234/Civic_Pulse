
# Civic Pulse 🏛️

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge" alt="License">
</div>

<div align="center">
  <h3>A community-driven platform for reporting civic problems and tracking their resolution</h3>
  <p>Built with Flutter and Firebase, CiviPulse empowers citizens to report issues in their communities and track the progress of solutions.</p>
</div>

<div align="center">
  
  [Features](#-features) -  
  [Screenshots](#-screenshots) -  
  [Installation](#-installation) -  
  [Contributing](#-contributing) -  
  [License](#-license)
  
</div>

---


## 🚀 Try Civic Pulse

### 📱 Download Mobile App
Get the Android app to report civic issues in your community.

**[Download APK](https://drive.google.com/file/d/1OqR9PclEfYGUq4BRX7cO2SU3QNSB9-WV/view?usp=sharing)**

### 🛠️ Admin Dashboard
Access the web-based admin panel to manage reports and analytics.

**[Open Admin Panel](https://civicsense-cca11.web.app/)**

ADMIN CREDIANTALS
Email: admin@civicsense.com Password: Admin@Civic2024
<img width="1531" height="161" alt="image" src="https://github.com/user-attachments/assets/d9a97d6f-cc04-4609-b00e-44d6608a7eb4" />


---

**Quick Start:** Download the app → Install → Create account → Start reporting issues in your area!

The mobile app lets you report problems with photos and location, while the admin dashboard provides tools for managing and tracking issue resolution progress.

## 🌟 Features

<table>
<tr>
<td>

### 📱 For Citizens
- **Report Issues** - Submit civic problems with photos and location
- **Real-time Tracking** - Monitor resolution progress 
- **Interactive Maps** - Visualize community issues
- **Leaderboard** - Gamified participation system

</td>
<td>

### 🛠️ For Administrators  
- **Admin Dashboard** - Comprehensive management interface
- **Report Management** - Update status and assign tasks
- **User Management** - Handle user accounts and permissions
- **Analytics** - Detailed insights and reporting

</td>
</tr>
</table>

## 📱 Screenshots

### Mobile Application
<div align="center">
<table>
<tr>
<td align="center">
<img src="https://github.com/user-attachments/assets/ad4344b7-4dd3-4c43-8d39-47cd0cd93947" width="200"/>
<br><b>Home Screen</b>
</td>
<td align="center">
<img src="https://github.com/user-attachments/assets/3d5f8a93-6c59-4d7f-be08-9b60f431580e" width="200"/>
<br><b>Report Issue</b>
</td>
<td align="center">
<img src="https://github.com/user-attachments/assets/31d5044e-ed0a-4c46-a62e-031b2fd8c910" width="200"/>
<br><b>Map View</b>
</td>
</tr>
<tr>
<td align="center">
<img src="https://github.com/user-attachments/assets/10f9426f-192a-44df-ba80-1adcce9b6e29" width="200"/>
<br><b>Issue Details</b>
</td>
<td align="center">
<img src="https://github.com/user-attachments/assets/fba7fa5c-00a4-48ee-ac98-63f999dc6d3a" width="200"/>
<br><b>Profile</b>
</td>
<td align="center">
<img src="https://github.com/user-attachments/assets/530327dd-16f2-404b-883c-4c495393d22b" width="200"/>
<br><b>Leaderboard</b>
</td>
</tr>
</table>
</div>

### Admin Panel
<div align="center">
<table>
<tr>
<td align="center">
<img src="https://github.com/user-attachments/assets/2e5e6f1b-431d-4f59-a274-62300cd80a73" width="400"/>
<br><b>Dashboard Overview</b>
</td>
<td align="center">
<img src="https://github.com/user-attachments/assets/a30703e7-b611-4e4f-9a23-552b0c56657f" width="400"/>
<br><b>Report Management</b>
</td>
</tr>
<tr>
<td align="center">
<img src="https://github.com/user-attachments/assets/b49015a7-475e-475a-a7ce-f9b07cf904c6" width="400"/>
<br><b>Analytics Dashboard</b>
</td>
<td align="center">
<img src="https://github.com/user-attachments/assets/5451e575-2301-4836-bef7-fdd435aad331" width="400"/>
<br><b>User Management</b>
</td>
</tr>
<tr>
<td align="center" colspan="2">
<img src="https://github.com/user-attachments/assets/b6f93eda-187b-437c-b9a1-d3f9c214fa2e" width="500"/>
<br><b>Interactive Map Overview</b>
</td>
</tr>
</table>
</div>

## 🚀 Installation

### Prerequisites
- Flutter SDK (>=3.0.0)
- Firebase project
- Android Studio / VS Code
- Git

### Quick Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/sahilchy1234/Civic_Pulse.git
   cd Civic_Pulse
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   ```bash
   # Create Firebase project at https://console.firebase.google.com/
   # Enable: Authentication, Firestore, Storage
   # Download config files:
   # - android/app/google-services.json
   # - ios/Runner/GoogleService-Info.plist
   ```

4. **Environment Setup**
   ```bash
   # Create .env file
   echo "FIREBASE_API_KEY=your_api_key
   FIREBASE_PROJECT_ID=your_project_id" > .env
   ```

5. **Run the application**
   ```bash
   flutter run
   ```

## 🏗️ Project Architecture

```
📦 Civic_Pulse
├── 📂 lib/
│   ├── 📂 config/          # App configuration
│   ├── 📂 models/          # Data models
│   ├── 📂 screens/         # UI screens
│   ├── 📂 services/        # Business logic & APIs
│   ├── 📂 utils/           # Helper functions
│   └── 📂 widgets/         # Reusable components
├── 📂 admin-panel/         # Web admin interface
│   ├── 📂 public/          # Static assets
│   ├── 📄 styles.css       # Styling
│   └── 📄 app.js          # Admin logic
├── 📂 android/             # Android-specific files
├── 📂 ios/                 # iOS-specific files
└── 📄 pubspec.yaml        # Dependencies
```

## 🔧 Technology Stack

<div align="center">

| Category | Technology |
|----------|------------|
| **Frontend** | Flutter, Dart (72.5%) |
| **Backend** | Firebase (Auth, Firestore, Storage) |
| **Web** | JavaScript (10.3%), HTML (7.5%), CSS (4.8%) |
| **Maps** | Google Maps API |
| **Admin Panel** | HTML, CSS, JavaScript |
| **Authentication** | Google Sign-In |
| **Native** | C++ (2.4%), CMake (1.9%) |

</div>

## 🚀 Deployment

<table>
<tr>
<th>Platform</th>
<th>Command</th>
<th>Output</th>
</tr>
<tr>
<td><b>Android</b></td>
<td><code>flutter build apk --release</code></td>
<td>APK file for distribution</td>
</tr>
<tr>
<td><b>iOS</b></td>
<td><code>flutter build ios --release</code></td>
<td>iOS build for App Store</td>
</tr>
<tr>
<td><b>Web</b></td>
<td><code>flutter build web</code></td>
<td>Web application</td>
</tr>
<tr>
<td><b>Admin Panel</b></td>
<td>Deploy to Netlify/Vercel</td>
<td>Web dashboard</td>
</tr>
</table>

## 📊 Project Stats

<div align="center">
  <img src="https://github-readme-stats.vercel.app/api/pin/?username=sahilchy1234&repo=Civic_Pulse&theme=radical" />
</div>

<div align="center">
  <img src="https://img.shields.io/github/stars/sahilchy1234/Civic_Pulse?style=social" alt="GitHub Stars">
  <img src="https://img.shields.io/github/forks/sahilchy1234/Civic_Pulse?style=social" alt="GitHub Forks">
  <img src="https://img.shields.io/github/watchers/sahilchy1234/Civic_Pulse?style=social" alt="GitHub Watchers">
</div>

## 🗺️ Roadmap

### Upcoming Features
- [ ] 🤖 AI-powered issue categorization
- [ ] 🏛️ Integration with local government APIs
- [ ] 📊 Advanced analytics dashboard
- [ ] 🌍 Multi-language support
- [ ] 📱 Offline mode support
- [ ] 📢 Social media integration

## 🤝 Contributing

<div align="center">
  <img src="https://contrib.rocks/image?repo=sahilchy1234/Civic_Pulse" />
</div>

We welcome contributions! Here's how you can help:

1. **🍴 Fork** the repository
2. **🌿 Create** a feature branch (`git checkout -b feature/AmazingFeature`)
3. **💾 Commit** your changes (`git commit -m 'Add some AmazingFeature'`)
4. **📤 Push** to the branch (`git push origin feature/AmazingFeature`)
5. **🔀 Open** a Pull Request

### Development Guidelines
- Follow Flutter best practices
- Write comprehensive tests
- Update documentation
- Ensure code quality with `flutter analyze`

## 🆘 Support & Documentation

<table>
<tr>
<td>

### 📚 Resources
- [📖 Comprehensive Documentation](COMPREHENSIVE_DOCUMENTATION.md)
- [🔧 Troubleshooting Guide](TROUBLESHOOTING_GUIDE.md)
- [🎯 API Reference](API_REFERENCE.md)

</td>
<td>

### 💬 Get Help
- [🐛 Report Issues](https://github.com/sahilchy1234/Civic_Pulse/issues)
- [💡 Feature Requests](https://github.com/sahilchy1234/Civic_Pulse/discussions)
- [📧 Contact Support](mailto:sahilalomchoudhury031@gmail.com)

</td>
</tr>
</table>

## 📝 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.[1]

```
MIT License - feel free to use this project for personal and commercial purposes.
```



<div align="center">
  <h3>🏛️ Building Better Communities Together 🏛️</h3>
  <p><i>Made with ❤️ by developers who care about civic engagement</i></p>
  
  **[⭐ Star this repo](https://github.com/sahilchy1234/Civic_Pulse) | [🔄 Fork it](https://github.com/sahilchy1234/Civic_Pulse/fork) | [📢 Share it](https://twitter.com/intent/tweet?text=Check%20out%20CiviPulse%20-%20A%20community-driven%20platform%20for%20civic%20engagement!&url=https://github.com/sahilchy1234/Civic_Pulse)**
</div>

