# Enkript - Cross-Platform Password Manager

## 🌐 Platform Support

### ✅ Android (Full Features)
- ✅ Cloud synchronization via Firebase
- ✅ Biometric authentication (fingerprint/face)
- ✅ Per-user cloud databases
- ✅ Multi-device sync
- ✅ Offline-first with automatic sync

### ✅ Windows (Offline Mode)
- ✅ Local encrypted storage (Hive + AES-256)
- ✅ All password management features
- ✅ Strong password generator
- ✅ Multiple profiles support
- ❌ Cloud sync (not available)
- ❌ Biometric auth (local_auth has limited Windows support)

---

## 🏗️ Building the App

### For Android (with Cloud Sync):
```powershell
.\build_android.ps1
```
**Output**: `build\app\outputs\flutter-apk\app-release.apk`

### For Windows (Offline Only):
```powershell
.\build_windows.ps1
```
**Output**: `build\windows\x64\runner\Release\`

### Manual Build Commands:
```powershell
# Android
flutter build apk --release

# Windows (requires temporary Firebase removal)
# Use build_windows.ps1 script instead
```

---

## ⚙️ Architecture

### Platform-Conditional Firebase
The app intelligently detects the platform and enables/disables Firebase:

**Android/iOS/Web**: Firebase enabled (cloud sync works)  
**Windows/Linux**: Firebase disabled (offline-only mode)

### Code Implementation:
```dart
// main.dart - Conditional initialization
if (kIsWeb || (!Platform.isWindows && !Platform.isLinux)) {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
```

### Build System Limitation:
While the **code** is platform-conditional, Flutter's build system still tries to compile all dependencies for each platform. Firebase C++ SDK has compatibility issues with Windows builds, so we temporarily exclude Firebase packages when building for Windows.

---

## 📦 Why Two Build Scripts?

**Problem**: Firebase packages cause C++ compilation errors on Windows  
**Solution**: Temporarily comment out Firebase in `pubspec.yaml` during Windows builds

`build_windows.ps1`:
1. Backs up `pubspec.yaml`
2. Comments out Firebase packages
3. Runs `flutter build windows`
4. Restores original `pubspec.yaml`

`build_android.ps1`:
1. Ensures Firebase packages are present
2. Runs `flutter build apk`

---

## 🔐 Security

- **Encryption**: AES-256 encryption for all stored credentials
- **Master Password**: Required on all platforms
- **Biometric**: Fingerprint/Face ID on Android (optional)
- **Cloud Security**: Per-user Firestore rules prevent data leaks
- **Local Storage**: Encrypted Hive database

---

## 🚀 Firebase Setup (Required for Android)

1. **Enable Firestore**: https://console.firebase.google.com/project/enkript-8fab5
   - Click "Firestore Database"
   - Click "Create database"
   - Choose "Start in test mode"
   - Select location (e.g., us-central)

2. **Set Security Rules**:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

3. **Publish rules**

---

## 📱 Installation

### Android:
1. Enable "Unknown Sources" in Android settings
2. Install `app-release.apk`
3. Grant permissions when prompted
4. Sign up or sign in
5. Create master password
6. Enable biometric (optional)

### Windows:
1. Run `build_windows.ps1`
2. Navigate to `build\windows\x64\runner\Release\`
3. Run `enkript.exe`
4. Create master password
5. Start using offline

---

## 🔄 Cross-Platform Data Sync

### Scenario: Using on both Android and Windows

**On Android** (with cloud sync):
- Add/edit credentials → automatically syncs to cloud
- Data backed up to Firebase

**On Windows** (offline):
- Completely separate local database
- No automatic sync with Android

**Workaround for Manual Sync**:
1. Export from Android → Settings → Export Data (if implemented)
2. Import to Windows → Settings → Import Data (if implemented)

*Note: Real-time sync between Android and Windows requires a different cloud provider that supports desktop (e.g., Supabase, AWS Amplify)*

---

## 🛠️ Development

### Run in Development Mode:

**Android**:
```powershell
flutter run -d <device-id>
```

**Windows**:
```powershell
# Temporarily comment out Firebase packages in pubspec.yaml first
flutter run -d windows
```

### Project Structure:
```
lib/
├── main.dart                  # Entry point, platform-conditional Firebase
├── models/                    # Credential model
├── providers/                 # State management (Auth, Vault, Theme)
├── services/                  # Business logic (Encryption, Cloud, Biometric)
├── screens/                   # UI screens
│   ├── auth/                  # Setup, Login, Cloud Auth
│   ├── credentials/           # List, Add, Edit
│   └── settings/             # Settings, Export
└── widgets/                   # Reusable components
```

---

## ⚡ Performance

- **Local-first**: All operations instant, cloud sync in background (Android)
- **Encrypted**: AES-256 encryption with minimal performance impact
- **Optimized builds**: Tree-shaken fonts (99.6% reduction)

---

## 📋 Features

✅ Filtered app list from installed apps  
✅ Multiple accounts per app  
✅ Custom apps/websites support  
✅ Strong password generator (8-32 chars)  
✅ Cross-platform (Android + Windows)  
✅ Cloud storage (Android only)  
✅ Biometric authentication (Android only)  
✅ Master password protection  
✅ AES-256 encryption  
✅ Material Design 3 UI  
✅ Dark/Light theme  
✅ Profile management  

---

## 🐛 Known Limitations

1. **Windows cloud sync**: Not available due to Firebase Windows SDK issues
2. **Windows biometric**: Limited support, not recommended
3. **No real-time sync**: Between Android ↔ Windows (by design)
4. **Build scripts required**: For Windows builds (temporary Firebase removal)

---

## 📄 License

This is a personal project. Use at your own risk.

---

## 🙋 Support

For issues related to:
- **Android builds**: Ensure Firebase is properly configured
- **Windows builds**: Use `build_windows.ps1` script
- **Cloud sync**: Enable Firestore in Firebase Console
- **Biometric**: Ensure device has fingerprint/face recognition enrolled
