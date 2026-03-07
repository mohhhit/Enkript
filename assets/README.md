# Assets Directory

This directory contains app assets like images and icons.

## Structure

```
assets/
├── images/           # App images (logo, splash, etc.)
└── icons/           # Custom icons
```

## Adding Assets

1. Place files in appropriate subdirectory
2. Update `pubspec.yaml` if needed
3. Reference in code: `Image.asset('assets/images/logo.png')`

## Image Requirements

- **App Icon**: 1024x1024 PNG
- **Splash Screen**: Various sizes for different devices
- **Icons**: SVG preferred for scalability

## Generating App Icons

Use flutter_launcher_icons package:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/app_icon.png"
```

Run: `flutter pub run flutter_launcher_icons`
