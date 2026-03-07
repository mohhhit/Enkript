# Enkript - Local Development Setup (No Flutter Installation)
# This script checks prerequisites and provides installation guidance

Write-Host "🔐 Enkript - Development Environment Check" -ForegroundColor Cyan
Write-Host "=========================================`n" -ForegroundColor Cyan

# Check if Flutter is installed
Write-Host "[1/4] Checking Flutter installation..." -ForegroundColor Yellow
$flutterInstalled = Get-Command flutter -ErrorAction SilentlyContinue

if ($flutterInstalled) {
    Write-Host "✓ Flutter is installed!" -ForegroundColor Green
    $flutterVersion = flutter --version | Select-Object -First 1
    Write-Host "  $flutterVersion" -ForegroundColor Gray
} else {
    Write-Host "✗ Flutter is NOT installed" -ForegroundColor Red
    Write-Host "`nTo install Flutter:" -ForegroundColor Yellow
    Write-Host "  Option 1 - Manual Install:" -ForegroundColor White
    Write-Host "    1. Download: https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Gray
    Write-Host "    2. Extract to C:\flutter" -ForegroundColor Gray
    Write-Host "    3. Add C:\flutter\bin to PATH" -ForegroundColor Gray
    Write-Host "    4. Restart this terminal`n" -ForegroundColor Gray
    
    Write-Host "  Option 2 - Using winget (Windows 10+):" -ForegroundColor White
    Write-Host "    winget install --id Google.Flutter -e`n" -ForegroundColor Gray
    
    Write-Host "After installing Flutter, run this script again!`n" -ForegroundColor Cyan
    exit 1
}

# Check Git
Write-Host "`n[2/4] Checking Git installation..." -ForegroundColor Yellow
$gitInstalled = Get-Command git -ErrorAction SilentlyContinue

if ($gitInstalled) {
    Write-Host "✓ Git is installed!" -ForegroundColor Green
} else {
    Write-Host "✗ Git is NOT installed" -ForegroundColor Red
    Write-Host "  Install from: https://git-scm.com/download/win" -ForegroundColor Gray
}

# Check Android Studio (optional)
Write-Host "`n[3/4] Checking Android Studio..." -ForegroundColor Yellow
$androidStudioPath = "C:\Program Files\Android\Android Studio"
if (Test-Path $androidStudioPath) {
    Write-Host "✓ Android Studio found!" -ForegroundColor Green
} else {
    Write-Host "⚠ Android Studio not found (optional for Windows-only dev)" -ForegroundColor Yellow
    Write-Host "  Download: https://developer.android.com/studio" -ForegroundColor Gray
}

# Check if project dependencies are installed
Write-Host "`n[4/4] Checking project setup..." -ForegroundColor Yellow
$pubspecLock = "pubspec.lock"
if (Test-Path $pubspecLock) {
    Write-Host "✓ Dependencies already installed" -ForegroundColor Green
} else {
    Write-Host "⚠ Dependencies not installed yet" -ForegroundColor Yellow
}

# Run Flutter doctor
Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "Running Flutter Doctor..." -ForegroundColor Cyan
Write-Host "=========================================`n" -ForegroundColor Cyan
flutter doctor

# Next steps
Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Green
Write-Host "=========================================`n" -ForegroundColor Cyan

Write-Host "1. Install dependencies:" -ForegroundColor Yellow
Write-Host "   flutter pub get`n" -ForegroundColor White

Write-Host "2. Generate code:" -ForegroundColor Yellow
Write-Host "   flutter pub run build_runner build --delete-conflicting-outputs`n" -ForegroundColor White

Write-Host "3. Run the app:" -ForegroundColor Yellow
Write-Host "   For Windows: flutter run -d windows" -ForegroundColor White
Write-Host "   For Android: flutter run`n" -ForegroundColor White

Write-Host "Quick command to run all at once:" -ForegroundColor Cyan
Write-Host "   flutter pub get; flutter pub run build_runner build --delete-conflicting-outputs; flutter run -d windows`n" -ForegroundColor White

Write-Host "Happy coding! 🚀`n" -ForegroundColor Green
