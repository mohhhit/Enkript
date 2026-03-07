# Enkript 🔐

A secure, cross-platform password manager with auto-fill capabilities, built with Flutter.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows-brightgreen)
![License](https://img.shields.io/badge/License-MIT-blue)

## ✨ Features

- 🔒 **Strong Encryption**: AES-256 encryption for all stored credentials
- 🔑 **Password Generator**: Customizable strong password generation (8-32 characters)
- 📱 **Cross-Platform**: Runs on Android and Windows (with Linux/macOS/iOS support)
- ☁️ **Cloud Sync**: Secure cloud backup with Firebase
- 👆 **Biometric Auth**: Fingerprint/Face unlock support
- 🔍 **Smart Search**: Quick filtering and search across all credentials
- 📊 **Multiple Profiles**: Support for multiple accounts per app
- 🎨 **Modern UI**: Sleek, polished interface with dark mode support
- 💾 **Auto-fill Ready**: Framework for password auto-fill integration
- 📂 **Categories**: Organize credentials by type (Social, Banking, Email, etc.)

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0+)
- Dart SDK (3.0+)
- Android Studio / VS Code
- Firebase account (for cloud sync)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/enkript.git
   cd enkript
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Hive models**
   ```bash
   flutter pub run build_runner build
   ```

4. **Setup Firebase**
   - Follow the detailed guide in [FIREBASE_SETUP.md](FIREBASE_SETUP.md)
   - Add your `google-services.json` for Android
   - Update `lib/firebase_options.dart` with your config

5. **Run the app**
   ```bash
   # For Android
   flutter run

   # For Windows
   flutter run -d windows

   # For development (hot reload)
   flutter run --debug
   ```

## 📁 Project Structure

```
lib/
├── config/              # App configuration (themes, constants)
├── models/              # Data models (Credential)
├── providers/           # State management (Auth, Vault, Theme)
├── screens/             # UI screens
│   ├── auth/           # Login & setup screens
│   ├── home/           # Home screen
│   ├── credentials/    # Add/edit credential screens
│   └── settings/       # Settings screen
├── services/           # Business logic services
│   ├── biometric_service.dart
│   ├── encryption_service.dart
│   ├── password_generator_service.dart
│   └── cloud_sync_service.dart
├── widgets/            # Reusable UI components
└── main.dart           # App entry point
```

## 🔧 Technologies Used

- **Framework**: Flutter & Dart
- **State Management**: Provider
- **Local Storage**: Hive + flutter_secure_storage
- **Encryption**: AES-256 (encrypt package)
- **Cloud Backend**: Firebase (Auth + Firestore)
- **Biometric Auth**: local_auth
- **UI**: Material Design 3

## 🔐 Security Features

1. **End-to-End Encryption**: All passwords encrypted before storage
2. **Master Password**: Required for app access
3. **Biometric Lock**: Optional fingerprint/face authentication
4. **Secure Storage**: Encrypted local database
5. **Cloud Security**: Firebase security rules protect user data
6. **No Plain Text**: Passwords never stored in plain text

## 📱 Platform-Specific Features

### Android
- Biometric authentication (fingerprint/face)
- AutofillService integration (framework ready)
- Material 3 design

### Windows
- Native Windows look and feel
- Clipboard integration
- Desktop-optimized layout

## 🛠️ Build for Production

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### Windows
```bash
flutter build windows --release
```

## 🎯 Roadmap

- [ ] Auto-fill service implementation for Android
- [ ] Browser extension support
- [ ] Secure password sharing
- [ ] Import from other password managers
- [ ] Two-factor authentication (2FA) support
- [ ] Password breach monitoring
- [ ] Offline mode improvements
- [ ] iOS support
- [ ] macOS support

## 🧪 Testing

Run tests:
```bash
flutter test
```

Generate coverage:
```bash
flutter test --coverage
```

## 📝 Usage

### First Time Setup
1. Launch the app
2. Create a strong master password
3. Enable biometric authentication (optional)
4. Start adding credentials

### Adding a Credential
1. Tap the **+** button
2. Fill in app name, profile, username
3. Use the password generator or enter your own
4. Select a category
5. Save

### Viewing/Editing Credentials
1. Tap any credential card
2. Authenticate with biometrics to view password
3. Copy credentials with one tap
4. Edit or delete as needed

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

This is a personal project for educational purposes. While it implements strong encryption and security practices, please use at your own risk. Always keep backups of your important credentials.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for cloud infrastructure
- All open-source package contributors

## 📧 Contact

For questions or support, please open an issue on GitHub.

---

**Made with ❤️ using Flutter**
