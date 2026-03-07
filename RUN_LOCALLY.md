# 🎯 Run Enkript Locally - Step by Step

## Prerequisites Installation

### Step 1: Install Flutter (Required)

**Method 1 - Using winget (Easiest for Windows 10/11):**
```powershell
# Install Git first (if not already installed)
winget install --id Git.Git -e

# Install Flutter
winget install --id Google.Flutter -e

# Close and reopen PowerShell, then verify:
flutter --version
```

**Method 2 - Manual Installation:**
1. Download Flutter SDK: https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.19.0-stable.zip
2. Extract to `C:\flutter` (avoid paths with spaces or special characters)
3. Add `C:\flutter\bin` to Windows PATH:
   - Press `Win + X` → System → Advanced system settings
   - Click "Environment Variables"
   - Under "System Variables", find "Path" → Edit
   - Click "New" → Add `C:\flutter\bin`
   - Click OK on all windows
4. Restart PowerShell/Terminal
5. Verify: `flutter --version`

### Step 2: Run Flutter Doctor (Optional but Recommended)
```powershell
# This checks your setup
flutter doctor

# Accept Android licenses if using Android
flutter doctor --android-licenses
```

---

## Running Enkript App

### Quick Setup (After Flutter is Installed)

Run this script to check your setup:
```powershell
.\check-setup.ps1
```

OR manually run these commands:

```powershell
# 1. Install project dependencies
flutter pub get

# 2. Generate Hive database models
flutter pub run build_runner build --delete-conflicting-outputs

# 3. Run on Windows (NO Firebase setup needed!)
flutter run -d windows
```

### One-Line Command (After Flutter is installed):
```powershell
flutter pub get; flutter pub run build_runner build --delete-conflicting-outputs; flutter run -d windows
```

---

## What to Expect

### First Run:
1. **Master Password Setup**: You'll create a master password
2. **Biometric Option**: Choose to enable/disable fingerprint (if available)
3. **Main Screen**: Empty vault ready for credentials

### Testing the App:
1. Click the **+** button to add a credential
2. Fill in:
   - App Name: "Test App"
   - Profile: "Personal"
   - Username: "test@example.com"
   - Click ⚡ icon to generate a password
3. Save and explore features!

---

## Common Issues & Solutions

### ❌ "flutter: command not found"
**Solution**: Flutter not in PATH. Restart terminal after installation or manually add to PATH.

### ❌ Build errors
**Solution**: 
```powershell
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### ❌ "No devices available"
**Solution**: 
```powershell
# See available devices
flutter devices

# Run specifically on Windows
flutter run -d windows
```

### ❌ Firebase errors
**Solution**: The app will work locally without Firebase. Cloud sync won't work but all local features will.

---

## Supported Platforms

✅ **Windows** (Recommended for first test)
```powershell
flutter run -d windows
```

✅ **Android** (Requires USB device or emulator)
```powershell
# List connected devices
flutter devices

# Run on connected Android device
flutter run
```

⚠️ **Linux/macOS** (Code is ready but may need platform-specific setup)

---

## Build Release Version

After testing, build production version:

```powershell
# Windows executable
flutter build windows --release
# Output: build\windows\runner\Release\enkript.exe

# Android APK
flutter build apk --release
# Output: build\app\outputs\flutter-apk\app-release.apk
```

---

## Need Help?

1. Run the setup checker: `.\check-setup.ps1`
2. Check Flutter installation: `flutter doctor -v`
3. See error logs in the terminal
4. Check DEV_NOTES.md for troubleshooting

---

**Ready to start? Run this now:**
```powershell
.\check-setup.ps1
```
