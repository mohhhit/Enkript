// import 'package:local_auth/local_auth.dart'; // Commented out - causing symlink issues
// import 'package:flutter/services.dart'; // Commented out - causing symlink issues

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  static BiometricService get instance => _instance;

  // final LocalAuthentication _localAuth = LocalAuthentication(); // Commented out
  bool _isAvailable = false;
  List _availableBiometrics = []; // Changed type from List<BiometricType>

  Future<void> initialize() async {
    // Biometric authentication disabled for local testing
    _isAvailable = false;
    _availableBiometrics = [];
  }

  /// Check if biometric authentication is available
  bool get isAvailable => _isAvailable;

  /// Get available biometric types
  List get availableBiometrics => _availableBiometrics;

  /// Check if device has fingerprint sensor
  bool get hasFingerprint => false; // Disabled for local testing

  /// Check if device has face recognition
  bool get hasFaceRecognition => false; // Disabled for local testing

  /// Authenticate user with biometrics
  Future<bool> authenticate({
    String localizedReason = 'Please authenticate to access your passwords',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    // Biometric authentication disabled for local testing
    print('Biometric authentication disabled in local testing mode');
    return false;
  }

  /// Get biometric type name for display
  String getBiometricTypeName() {
    return 'Biometric'; // Generic name for local testing
  }

  /// Stop authentication (if in progress)
  Future<void> stopAuthentication() async {
    // Disabled for local testing
  }
}
