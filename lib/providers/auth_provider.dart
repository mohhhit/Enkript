import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Commented out for local testing
import '../services/encryption_service.dart';

class AuthProvider extends ChangeNotifier {
  // final FirebaseAuth _auth = FirebaseAuth.instance; // Commented out for local testing
  // User? _user; // Commented out for local testing
  bool _isAuthenticated = false;
  bool _isBiometricEnabled = false;

  // User? get user => _user; // Commented out for local testing
  bool get isAuthenticated => _isAuthenticated;
  bool get isBiometricEnabled => _isBiometricEnabled;

  AuthProvider() {
    _init();
  }

  void _init() {
    // _auth.authStateChanges().listen((User? user) { // Commented out for local testing
    //   _user = user;
    //   _isAuthenticated = user != null;
    //   notifyListeners();
    // });
    // For local testing, mark as authenticated
    _isAuthenticated = true;
  }

  /// Sign up with email and password
  Future<bool> signUp(String email, String password) async {
    // For local testing, always return true
    return true;
    // try {
    //   await _auth.createUserWithEmailAndPassword(
    //     email: email,
    //     password: password,
    //   );
    //   return true;
    // } catch (e) {
    //   print('Sign up error: $e');
    //   return false;
    // }
  }

  /// Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    // For local testing, always return true
    return true;
    // try {
    //   await _auth.signInWithEmailAndPassword(
    //     email: email,
    //     password: password,
    //   );
    //   return true;
    // } catch (e) {
    //   print('Sign in error: $e');
    //   return false;
    // }
  }

  /// Sign out
  Future<void> signOut() async {
    // await _auth.signOut(); // Commented out for local testing
    await EncryptionService.instance.clearKeys();
    _isAuthenticated = false;
    notifyListeners();
  }

  /// Set master password
  Future<void> setMasterPassword(String password) async {
    await EncryptionService.instance.storeMasterPasswordHash(password);
  }

  /// Verify master password
  Future<bool> verifyMasterPassword(String password) async {
    return await EncryptionService.instance.verifyMasterPassword(password);
  }

  /// Check if master password is set
  Future<bool> isMasterPasswordSet() async {
    return await EncryptionService.instance.isMasterPasswordSet();
  }

  /// Toggle biometric authentication
  void toggleBiometric(bool enabled) {
    _isBiometricEnabled = enabled;
    notifyListeners();
  }
}
