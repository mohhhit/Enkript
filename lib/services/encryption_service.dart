import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  static EncryptionService get instance => _instance;

  late Box _secureBox;
  late Encrypter _encrypter;
  late IV _iv;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Open Hive box for secure storage
    _secureBox = await Hive.openBox('secure_storage');

    // Get or create encryption key
    String? keyString = _secureBox.get('encryption_key');
    
    if (keyString == null) {
      // Generate new key
      final key = Key.fromSecureRandom(32);
      keyString = base64Encode(key.bytes);
      await _secureBox.put('encryption_key', keyString);
    }

    // Get or create IV
    String? ivString = _secureBox.get('encryption_iv');
    
    if (ivString == null) {
      // Generate new IV
      final iv = IV.fromSecureRandom(16);
      ivString = base64Encode(iv.bytes);
      await _secureBox.put('encryption_iv', ivString);
    }

    final key = Key(base64Decode(keyString));
    _iv = IV(base64Decode(ivString));
    _encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    _isInitialized = true;
  }

  /// Encrypt a string
  String encrypt(String plainText) {
    if (!_isInitialized) {
      throw StateError('EncryptionService not initialized');
    }
    return _encrypter.encrypt(plainText, iv: _iv).base64;
  }

  /// Decrypt a string
  String decrypt(String encryptedText) {
    if (!_isInitialized) {
      throw StateError('EncryptionService not initialized');
    }
    return _encrypter.decrypt64(encryptedText, iv: _iv);
  }

  /// Hash a string (for master password verification)
  String hash(String text) {
    final bytes = utf8.encode(text);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate a secure key from password using PBKDF2
  Future<String> deriveKeyFromPassword(String password, String salt) async {
    // Simple implementation - in production, use proper PBKDF2
    final combined = password + salt;
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return base64Encode(digest.bytes);
  }

  /// Clear all encryption keys (for logout)
  Future<void> clearKeys() async {
    await _secureBox.clear();
    _isInitialized = false;
  }

  /// Store master password hash
  Future<void> storeMasterPasswordHash(String password) async {
    final hashedPassword = hash(password);
    await _secureBox.put('master_password_hash', hashedPassword);
  }

  /// Verify master password
  Future<bool> verifyMasterPassword(String password) async {
    final storedHash = _secureBox.get('master_password_hash');
    if (storedHash == null) return false;
    return storedHash == hash(password);
  }

  /// Check if master password is set
  Future<bool> isMasterPasswordSet() async {
    final hash = _secureBox.get('master_password_hash');
    return hash != null;
  }
}
