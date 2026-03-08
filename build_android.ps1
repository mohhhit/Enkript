# Build script for Android (with cloud sync)
# This ensures Firebase packages are enabled

Write-Host "Preparing Android build (with cloud sync)..." -ForegroundColor Cyan

Write-Host "Running flutter pub get..." -ForegroundColor Yellow
flutter pub get

Write-Host "Building Android APK..." -ForegroundColor Green
flutter build apk --release

Write-Host "Android build complete!" -ForegroundColor Green
Write-Host "Location: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor White
Write-Host ""
Write-Host "Features enabled:" -ForegroundColor Cyan
Write-Host "   - Cloud sync via Firebase" -ForegroundColor White
Write-Host "   - Biometric authentication" -ForegroundColor White
Write-Host "   - Per-user cloud databases" -ForegroundColor White
Write-Host "   - Multi-device synchronization" -ForegroundColor White
