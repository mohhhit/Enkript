# Enkript Authentication Flow

## 📱 Android / iOS / Web (Cloud Enabled)

### First Time User:
1. **Splash Screen** → Checks Firebase auth status
2. **Cloud Auth Screen** ✨ NEW
   - Create account with email & password
   - OR Sign in if already have account
   - OR Skip to use offline mode
3. **Setup Screen** (after cloud sign in/up)
   - Create master password for local encryption
   - Enable biometric (optional)
4. **Home Screen** → Password vault

### Returning User:
1. **Splash Screen** → Detects signed-in user
2. **Login Screen** → Enter master password to unlock
3. **Home Screen** → Password vault

### Features:
- ✅ Email/Password authentication via Firebase
- ✅ Cloud sync to Firestore (automatic)
- ✅ Real-time sync across devices
- ✅ Master password for local AES-256 encryption
- ✅ Sign out option in Settings

---

## 💻 Windows / Linux (Offline Mode)

### First Time User:
1. **Splash Screen** → Skips cloud auth
2. **Setup Screen** → Create master password
3. **Home Screen** → Password vault

### Returning User:
1. **Splash Screen** → Checks master password exists
2. **Login Screen** → Enter master password
3. **Home Screen** → Password vault

### Features:
- ✅ Local storage only (Hive database)
- ✅ Master password for AES-256 encryption
- ✅ No cloud account needed
- ✅ No internet required

---

## 🔐 Two-Layer Security

**Layer 1: Cloud Account (Android/iOS/Web)**
- Email/Password via Firebase Authentication
- Required to sync data across devices
- Prevents unauthorized cloud access

**Layer 2: Master Password (All Platforms)**
- Encrypts ALL credentials locally with AES-256
- Never sent to cloud
- Required to unlock vault on device
- Different from cloud account password

---

## 🔧 Build & Test on Android

### Build APK:
```powershell
cd C:\Enkript
flutter build apk
```

### Install on Device:
```powershell
# APK location: build\app\outputs\flutter-apk\app-release.apk
# Transfer to phone and install
```

### Expected Flow:
1. Open app → See "Create Cloud Account" screen
2. Enter email (e.g., test@example.com) and password
3. Tap "Create Account"
4. See "Welcome to Enkript" → Create master password
5. Tap "Complete Setup"
6. Start adding passwords!

### Verify Cloud Sync:
1. Add a password in the app
2. Go to [Firebase Console](https://console.firebase.google.com/project/enkript-8fab5/firestore)
3. Navigate to: Firestore → users → [your-user-id] → credentials
4. See your encrypted passwords synced! ✅

---

## 📋 Settings Screen Features

**Cloud Account Section:**
- Shows signed-in email address
- Green checkmark if connected
- "Offline Mode" if on Windows

**Sign Out:**
- Signs out from both cloud and local vault
- Returns to cloud auth screen on Android
- Returns to login screen on Windows

---

## ⚠️ Important Notes

1. **Different Passwords:**
   - Cloud password = Access your account on any device
   - Master password = Decrypt data on current device
   - Use different, strong passwords for both!

2. **Master Password Lost?**
   - Cannot be recovered (security by design)
   - No one can decrypt your data, including you
   - Will need to clear data and start fresh

3. **Cloud Account Lost?**
   - Can reset via Firebase password reset (future feature)
   - Local data remains safe with master password
   - Can create new cloud account and re-sync

---

## 🚀 Next Build

```powershell
flutter clean
flutter build apk
```

Rebuild the APK and install on your Android device - you'll now see the cloud authentication screen! 🎉
