# Setup Script for Enkript
# Run this in PowerShell from the project root

Write-Host "🔐 Enkript Setup Script" -ForegroundColor Cyan
Write-Host "========================`n" -ForegroundColor Cyan

# Check Flutter installation
Write-Host "Checking Flutter installation..." -ForegroundColor Yellow
$flutterVersion = flutter --version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Flutter is installed" -ForegroundColor Green
} else {
    Write-Host "✗ Flutter is not installed. Please install Flutter first." -ForegroundColor Red
    Write-Host "Visit: https://flutter.dev/docs/get-started/install" -ForegroundColor Yellow
    exit 1
}

# Check Flutter doctor
Write-Host "`nRunning Flutter doctor..." -ForegroundColor Yellow
flutter doctor

# Get dependencies
Write-Host "`nInstalling dependencies..." -ForegroundColor Yellow
flutter pub get

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Dependencies installed successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to install dependencies" -ForegroundColor Red
    exit 1
}

# Generate Hive models
Write-Host "`nGenerating Hive models..." -ForegroundColor Yellow
flutter pub run build_runner build --delete-conflicting-outputs

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Hive models generated successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to generate Hive models" -ForegroundColor Red
    exit 1
}

# Check for Firebase configuration
Write-Host "`nChecking Firebase configuration..." -ForegroundColor Yellow
$firebaseConfigExists = Test-Path "lib/firebase_options.dart"
$androidConfigExists = Test-Path "android/app/google-services.json"

if ($firebaseConfigExists) {
    Write-Host "✓ Firebase options file found" -ForegroundColor Green
} else {
    Write-Host "⚠ firebase_options.dart not found" -ForegroundColor Yellow
    Write-Host "  Please follow FIREBASE_SETUP.md to configure Firebase" -ForegroundColor Yellow
}

if ($androidConfigExists) {
    Write-Host "✓ google-services.json found" -ForegroundColor Green
} else {
    Write-Host "⚠ google-services.json not found for Android" -ForegroundColor Yellow
    Write-Host "  Please add it to android/app/ directory" -ForegroundColor Yellow
}

# Create assets directories
Write-Host "`nCreating asset directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "assets/images" | Out-Null
New-Item -ItemType Directory -Force -Path "assets/icons" | Out-Null
Write-Host "✓ Asset directories created" -ForegroundColor Green

Write-Host "`n========================" -ForegroundColor Cyan
Write-Host "Setup Complete! 🎉" -ForegroundColor Green
Write-Host "========================`n" -ForegroundColor Cyan

Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Configure Firebase (see FIREBASE_SETUP.md)" -ForegroundColor White
Write-Host "2. Run: flutter run (for Android/connected device)" -ForegroundColor White
Write-Host "3. Run: flutter run -d windows (for Windows)" -ForegroundColor White
Write-Host "4. Read QUICK_START.md for usage guide`n" -ForegroundColor White

Write-Host "Available commands:" -ForegroundColor Yellow
Write-Host "  flutter run              - Run in debug mode" -ForegroundColor White
Write-Host "  flutter run --release    - Run in release mode" -ForegroundColor White
Write-Host "  flutter build apk        - Build Android APK" -ForegroundColor White
Write-Host "  flutter build windows    - Build Windows app" -ForegroundColor White

Write-Host "`nHappy coding! 🚀`n" -ForegroundColor Cyan
