import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../services/encryption_service.dart';
import '../services/cloud_sync_service.dart';

class AuthProvider extends ChangeNotifier {
  FirebaseAuth? _auth;
  User? _user;
  bool _isAuthenticated = false;
  bool _isBiometricEnabled = false;

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isBiometricEnabled => _isBiometricEnabled;
  String? get userEmail => _user?.email;
  String? get userId => _user?.uid;
  
  /// Check if Firebase is available on this platform
  bool get isFirebaseAvailable => true; // Firebase now supports all platforms
  
  /// Get Auth instance (lazy init)
  FirebaseAuth? get auth {
    if (!isFirebaseAvailable) return null;
    _auth ??= FirebaseAuth.instance;
    return _auth;
  }

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // Load biometric preference
    await _loadBiometricPreference();
    if (!isFirebaseAvailable) {
      // Offline mode - authenticate with master password only
      _isAuthenticated = true; // Will be verified with master password
      print('ℹ️ Running in offline mode - no cloud authentication');
      return;
    }
    
    final authInstance = auth;
    if (authInstance != null) {
      authInstance.authStateChanges().listen((User? user) {
        _user = user;
        _isAuthenticated = user != null;
        notifyListeners();
      });
    }
  }

  /// Sign up with email and password
  Future<bool> signUp(String email, String password) async {
    if (!isFirebaseAvailable) {
      print('ℹ️ Offline mode - no cloud account needed');
      return true; // In offline mode, just use master password
    }
    
    try {
      final authInstance = auth;
      if (authInstance == null) return false;
      
      await authInstance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      print('❌ Sign up error: $e');
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    if (!isFirebaseAvailable) {
      print('ℹ️ Offline mode - no cloud sign in needed');
      return true; // In offline mode, just use master password
    }
    
    try {
      final authInstance = auth;
      if (authInstance == null) return false;
      
      await authInstance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      print('❌ Sign in error: $e');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    if (isFirebaseAvailable) {
      final authInstance = auth;
      if (authInstance != null) {
        await authInstance.signOut();
      }
    }
    
    await EncryptionService.instance.clearKeys();
    _isAuthenticated = false;
    notifyListeners();
  }

  /// Set master password
  Future<void> setMasterPassword(String password) async {
    final encryptionService = EncryptionService.instance;
    await encryptionService.bindMasterPassword(password, userId: userId);
  }

  /// Verify master password
  Future<bool> verifyMasterPassword(String password) async {
    final encryptionService = EncryptionService.instance;

    if (await encryptionService.verifyMasterPassword(password)) {
      return await encryptionService.restoreEncryptionKey(password, userId: userId);
    }

    final currentUserId = userId;
    if (!isFirebaseAvailable || currentUserId == null) {
      return false;
    }

    final cloudMetadata = await CloudSyncService.instance.fetchVaultMetadata(currentUserId);
    final cloudHash = cloudMetadata?['masterPasswordHash'] as String?;
    if (cloudHash == null || cloudHash != encryptionService.hash(password)) {
      return false;
    }

    await encryptionService.storeMasterPasswordHash(password);
    return await encryptionService.restoreEncryptionKey(password, userId: currentUserId);
  }

  /// Check if master password is set
  Future<bool> isMasterPasswordSet() async {
    final encryptionService = EncryptionService.instance;
    if (await encryptionService.isMasterPasswordSet()) {
      return true;
    }

    final currentUserId = userId;
    if (!isFirebaseAvailable || currentUserId == null) {
      return false;
    }

    final cloudMetadata = await CloudSyncService.instance.fetchVaultMetadata(currentUserId);
    return cloudMetadata?['masterPasswordHash'] != null;
  }

  /// Load biometric preference from storage
  Future<void> _loadBiometricPreference() async {
    try {
      final box = await Hive.openBox('secure_storage');
      _isBiometricEnabled = box.get('biometric_enabled', defaultValue: false) as bool;
      notifyListeners();
    } catch (e) {
      print('Error loading biometric preference: $e');
      _isBiometricEnabled = false;
    }
  }

  /// Toggle biometric authentication
  Future<void> toggleBiometric(bool enabled) async {
    _isBiometricEnabled = enabled;
    try {
      final box = await Hive.openBox('secure_storage');
      await box.put('biometric_enabled', enabled);
      print('✅ Biometric preference saved: $enabled');
    } catch (e) {
      print('Error saving biometric preference: $e');
    }
    notifyListeners();
  }
}
