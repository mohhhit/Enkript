# Build script for Windows (offline-only version)
# This temporarily removes Firebase packages to allow Windows build

Write-Host "Preparing Windows build (offline mode)..." -ForegroundColor Cyan

# Backup original pubspec.yaml
Copy-Item pubspec.yaml pubspec.yaml.backup

# Read pubspec.yaml
$content = Get-Content pubspec.yaml -Raw

# Comment out Firebase packages for Windows build
$content = $content -replace '  firebase_core:', '  # firebase_core:'
$content = $content -replace '  firebase_auth:', '  # firebase_auth:'
$content = $content -replace '  cloud_firestore:', '  # cloud_firestore:'

# Save modified pubspec.yaml
Set-Content pubspec.yaml $content

Write-Host "Running flutter pub get..." -ForegroundColor Yellow
flutter pub get

Write-Host "Building Windows application..." -ForegroundColor Green
flutter build windows --release

# Restore original pubspec.yaml
Write-Host "Restoring original pubspec.yaml..." -ForegroundColor Cyan
Copy-Item pubspec.yaml.backup pubspec.yaml -Force
Remove-Item pubspec.yaml.backup

Write-Host "Windows build complete!" -ForegroundColor Green
Write-Host "Location: build\windows\x64\runner\Release\" -ForegroundColor White
Write-Host "" 
Write-Host "NOTE: Windows version is OFFLINE-ONLY (no cloud sync)" -ForegroundColor Yellow
Write-Host "      All data stored locally in Hive database" -ForegroundColor Yellow
