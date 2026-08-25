import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

import 'package:flutter/foundation.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  static BiometricService get instance => _instance;

  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAvailable = false;
  List<BiometricType> _availableBiometrics = [];

  Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS) {
      print('🔐 Biometric Service: Bypassed on Desktop/Web');
      _isAvailable = false;
      return;
    }

    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      _isAvailable = canCheck && isSupported; // Both must be true
      
      print('🔐 Biometric Service Initialization:');
      print('   - Can check biometrics: $canCheck');
      print('   - Device supported: $isSupported');
      print('   - Is available: $_isAvailable');
      
      if (_isAvailable) {
        _availableBiometrics = await _localAuth.getAvailableBiometrics();
        print('   - Available biometrics: $_availableBiometrics');
        
        // Check if user has enrolled biometrics
        if (_availableBiometrics.isEmpty) {
          print('   ⚠️ No biometrics enrolled!');
          _isAvailable = false;
        }
      }
    } catch (e) {
      print('❌ Error initializing biometric service: $e');
      _isAvailable = false;
      _availableBiometrics = [];
    }
  }

  /// Check if biometric authentication is available
  bool get isAvailable => _isAvailable;

  /// Get available biometric types
  List<BiometricType> get availableBiometrics => _availableBiometrics;

  /// Check if device has fingerprint sensor
  bool get hasFingerprint => _availableBiometrics.contains(BiometricType.fingerprint);

  /// Check if device has face recognition
  bool get hasFaceRecognition => _availableBiometrics.contains(BiometricType.face);

  /// Authenticate user with biometrics
  Future<bool> authenticate({
    String localizedReason = 'Please authenticate to access your passwords',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    if (!_isAvailable) {
      print('⚠️ Biometric not available');
      return false;
    }

    if (_availableBiometrics.isEmpty) {
      print('⚠️ No biometrics enrolled');
      return false;
    }

    try {
      print('🔐 Attempting biometric authentication...');
      print('   Available biometrics: $_availableBiometrics');
      
      final result = await _localAuth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true, // Only use biometrics (fingerprint/face)
        sensitiveTransaction: false, // Less restrictive for better compatibility
      );
      print('✅ Biometric auth result: $result');
      return result;
    } on PlatformException catch (e) {
      print('❌ Biometric authentication error:');
      print('   Code: ${e.code}');
      print('   Message: ${e.message}');
      print('   Details: ${e.details}');
      
      // Common error codes:
      // NotAvailable: Biometric is not available on device
      // NotEnrolled: User hasn't enrolled any biometrics
      // LockedOut: Too many failed attempts
      // PermanentlyLockedOut: User must use device credentials
      // PasscodeNotSet: Device doesn't have a passcode/PIN set
      
      return false;
    } catch (e) {
      print('❌ Unexpected biometric error: $e');
      return false;
    }
  }

  /// Get biometric type name for display
  String getBiometricTypeName() {
    if (hasFingerprint) return 'Fingerprint';
    if (hasFaceRecognition) return 'Face Recognition';
    return 'Biometric';
  }

  /// Stop authentication (if in progress)
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      print('Error stopping authentication: $e');
    }
  }
}
