# Development Notes

## Build Commands

### Initial Setup
```bash
# Get dependencies
flutter pub get

# Generate code for Hive models
flutter pub run build_runner build

# Clean and regenerate if needed
flutter pub run build_runner build --delete-conflicting-outputs
```

### Running the App
```bash
# Debug mode with hot reload
flutter run

# Release mode
flutter run --release

# Specific device
flutter run -d windows
flutter run -d android
```

### Building Release
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# Windows
flutter build windows --release
```

## Common Issues & Solutions

### Issue: Hive type adapter error
**Solution**: Run `flutter pub run build_runner build`

### Issue: Firebase not initialized
**Solution**: 
1. Check `google-services.json` is in `android/app/`
2. Verify `firebase_options.dart` has correct config
3. Ensure Firebase.initializeApp() is called in main()

### Issue: Biometric auth not working
**Solution**:
- Android: Check minSdkVersion is 23+
- Windows: Biometric auth requires Windows Hello setup
- Check permissions in AndroidManifest.xml

### Issue: Build errors after dependency update
**Solution**:
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

## Testing Credentials

For development testing:
- **App**: Gmail
- **Profile**: Personal
- **Username**: test@example.com
- **Password**: Use generator

## Firebase Security Rules

Production rules are in FIREBASE_SETUP.md. For development, you can temporarily use test mode, but **NEVER** deploy test mode to production.

## Code Quality

Before committing:
```bash
# Format code
dart format .

# Analyze
flutter analyze

# Run tests
flutter test
```

## Performance Tips

1. Use `const` constructors where possible
2. Avoid rebuilding entire widget trees
3. Use `ListView.builder` for long lists
4. Profile with `flutter run --profile`

## Auto-fill Implementation (TODO)

### Android AutofillService
Framework is ready. To implement:
1. Create `AutofillService` in `android/app/src/main/kotlin/`
2. Add service to AndroidManifest.xml
3. Implement method channel in Flutter
4. Connect to VaultProvider

### Windows
Use clipboard monitoring and accessibility API
