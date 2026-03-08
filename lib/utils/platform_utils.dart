import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Utility class for platform detection and responsive design
class PlatformUtils {
  /// Check if running on desktop (Windows, macOS, Linux)
  static bool get isDesktop => 
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  
  /// Check if running on mobile (Android, iOS)
  static bool get isMobile => 
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  
  /// Check if running on web
  static bool get isWeb => kIsWeb;
  
  /// Check if running on Windows specifically
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  
  /// Check if running on Android specifically
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  
  /// Get appropriate padding for the platform
  static double get defaultPadding => isDesktop ? 24.0 : 16.0;
  
  /// Get appropriate font size multiplier for the platform
  static double get fontSizeMultiplier => isDesktop ? 1.1 : 1.0;
  
  /// Get appropriate card width for desktop layouts
  static double get maxCardWidth => isDesktop ? 800.0 : double.infinity;
  
  /// Get appropriate content width for desktop layouts
  static double get maxContentWidth => isDesktop ? 1200.0 : double.infinity;
}
