import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'cloud_sync_service.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  static EncryptionService get instance => _instance;

  Box? _secureBox;
  Encrypter? _encrypter;
  IV? _iv;
  bool _isInitialized = false;

  Future<Box> _getBox() async {
    if (_secureBox != null && _secureBox!.isOpen) return _secureBox!;
    _secureBox = await Hive.openBox('secure_storage');
    return _secureBox!;
  }

  /// Initialize: open the Hive box and load the existing key if this device
  /// was already set up. Does NOT generate a new key — key generation only
  /// happens in [bindMasterPassword] for brand-new accounts.
  Future<void> initialize() async {
    if (_isInitialized) return;

    final box = await _getBox();

    final keyString = box.get('encryption_key') as String?;
    final wrappedKey = box.get('wrapped_encryption_key') as String?;
    final ivString = box.get('encryption_iv') as String?;

    // Only mark as initialized if all three pieces exist locally.
    if (keyString != null && wrappedKey != null && ivString != null) {
      final key = Key(base64Decode(keyString));
      _iv = IV(base64Decode(ivString));
      _encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      _isInitialized = true;
      print('?? Encryption key loaded from local storage');
    } else {
      _isInitialized = false;
      print('?? No local vault key found — awaiting master password');
    }
  }

  Future<Map<String, dynamic>> _buildVaultMetadata(String password) async {
    final box = await _getBox();
    final keyString = box.get('encryption_key') as String?;
    if (keyString == null) throw StateError('Encryption key missing');

    final ivString = box.get('encryption_iv') as String?;

    final wrapSalt = base64Encode(IV.fromSecureRandom(16).bytes);
    final wrapIv = IV.fromSecureRandom(16);
    final wrapKeyBytes = base64Decode(await deriveKeyFromPassword(password, wrapSalt));
    final wrapEncrypter = Encrypter(AES(Key(wrapKeyBytes), mode: AESMode.cbc));
    final wrappedKey = wrapEncrypter.encrypt(keyString, iv: wrapIv).base64;

    return {
      'masterPasswordHash': hash(password),
      'vaultKeyWrapSalt': wrapSalt,
      'vaultKeyWrapIv': base64Encode(wrapIv.bytes),
      'wrappedEncryptionKey': wrappedKey,
      'vaultIv': ivString,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _persistVaultMetadata(Map<String, dynamic> metadata, {String? userId}) async {
    final box = await _getBox();
    await box.put('master_password_hash', metadata['masterPasswordHash']);
    await box.put('vault_key_wrap_salt', metadata['vaultKeyWrapSalt']);
    await box.put('vault_key_wrap_iv', metadata['vaultKeyWrapIv']);
    await box.put('wrapped_encryption_key', metadata['wrappedEncryptionKey']);
    if (metadata['vaultIv'] != null) {
      await box.put('encryption_iv', metadata['vaultIv']);
    }
    if (userId != null) {
      await CloudSyncService.instance.saveVaultMetadata(userId, metadata);
      print('?? Vault metadata pushed to Firestore');
    }
  }

  /// Bind a master password to the vault key and push to Firestore.
  /// For brand-new accounts this generates the Vault Key for the first time.
  Future<void> bindMasterPassword(String password, {String? userId}) async {
    final box = await _getBox();

    // Generate a new Vault Key only if one does not already exist.
    if (box.get('encryption_key') == null) {
      final key = Key.fromSecureRandom(32);
      final keyString = base64Encode(key.bytes);
      await box.put('encryption_key', keyString);

      final iv = IV.fromSecureRandom(16);
      final ivString = base64Encode(iv.bytes);
      await box.put('encryption_iv', ivString);

      _iv = iv;
      _encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      _isInitialized = true;
      print('?? New Vault Key generated (first account setup)');
    }

    final metadata = await _buildVaultMetadata(password);
    await _persistVaultMetadata(metadata, userId: userId);
    print('? Master password bound and vault metadata synced');
  }

  /// Restore the vault key from a password-wrapped backup.
  /// Priority: 1) Firestore (source of truth)  2) Local Hive (offline fallback)
  Future<bool> restoreEncryptionKey(String password, {String? userId}) async {
    final box = await _getBox();
    Map<String, dynamic>? metadata;

    // 1. Try Firestore first.
    if (userId != null) {
      try {
        final cloudMeta = await CloudSyncService.instance.fetchVaultMetadata(userId);
        if (cloudMeta != null && cloudMeta['wrappedEncryptionKey'] != null) {
          metadata = cloudMeta;
          print('?? Vault metadata fetched from Firestore');
        }
      } catch (e) {
        print('?? Could not reach Firestore, trying local fallback: $e');
      }
    }

    // 2. Fall back to local Hive.
    if (metadata == null) {
      final localWrapped = box.get('wrapped_encryption_key') as String?;
      if (localWrapped != null) {
        metadata = {
          'masterPasswordHash': box.get('master_password_hash'),
          'vaultKeyWrapSalt': box.get('vault_key_wrap_salt'),
          'vaultKeyWrapIv': box.get('vault_key_wrap_iv'),
          'wrappedEncryptionKey': localWrapped,
          'vaultIv': box.get('encryption_iv'),
        };
        print('?? Using local vault metadata (offline fallback)');
      }
    }

    final wrappedKey = metadata?['wrappedEncryptionKey'] as String?;
    final wrapSalt = metadata?['vaultKeyWrapSalt'] as String?;
    final wrapIvString = metadata?['vaultKeyWrapIv'] as String?;

    if (wrappedKey == null || wrapSalt == null || wrapIvString == null) {
      print('? No vault metadata found anywhere');
      return false;
    }

    try {
      final wrapKeyBytes = base64Decode(await deriveKeyFromPassword(password, wrapSalt));
      final wrapEncrypter = Encrypter(AES(Key(wrapKeyBytes), mode: AESMode.cbc));
      final unwrappedKey = wrapEncrypter.decrypt64(
        wrappedKey,
        iv: IV(base64Decode(wrapIvString)),
      );

      final vaultIvString = metadata?['vaultIv'] as String?; print("dY""? METADATA FETCHED: $metadata");
      final ivString = vaultIvString ?? base64Encode(IV.fromSecureRandom(16).bytes);

      // Cache everything locally for offline use.
      await box.put('encryption_key', unwrappedKey);
      await box.put('encryption_iv', ivString);
      await box.put('master_password_hash', metadata?['masterPasswordHash'] ?? hash(password));
      await box.put('vault_key_wrap_salt', wrapSalt);
      await box.put('vault_key_wrap_iv', wrapIvString);
      await box.put('wrapped_encryption_key', wrappedKey);

      _iv = IV(base64Decode(ivString));
      _encrypter = Encrypter(AES(Key(base64Decode(unwrappedKey)), mode: AESMode.cbc));
      _isInitialized = true;

      print('? Vault key restored successfully');
      return true;
    } catch (e) {
      print('? Failed to unwrap vault key (wrong master password?): $e');
      return false;
    }
  }

  /// Encrypt a string.
  String encrypt(String plainText) {
    if (!_isInitialized || _encrypter == null || _iv == null) {
      throw StateError('EncryptionService not initialized');
    }
    return _encrypter!.encrypt(plainText, iv: _iv!).base64;
  }

  /// Decrypt a string.
  String decrypt(String encryptedText) {
    if (!_isInitialized || _encrypter == null || _iv == null) {
      throw StateError('EncryptionService not initialized');
    }
    return _encrypter!.decrypt64(encryptedText, iv: _iv!);
  }

  /// Try to decrypt a string without throwing.
  String? tryDecrypt(String encryptedText) {
    try {
      return decrypt(encryptedText);
    } catch (e) {
      print('? Decryption error: $e');
      return null;
    }
  }

  /// Hash a string (for master password verification).
  String hash(String text) {
    final bytes = utf8.encode(text);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Derive a key from password + salt (SHA-256 based).
  Future<String> deriveKeyFromPassword(String password, String salt) async {
    final combined = password + salt;
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return base64Encode(digest.bytes);
  }

  /// Clear all encryption keys (for logout).
  Future<void> clearKeys() async {
    final box = await _getBox();
    await box.clear();
    _isInitialized = false;
    _encrypter = null;
    _iv = null;
  }

  /// Store master password hash.
  Future<void> storeMasterPasswordHash(String password) async {
    final box = await _getBox();
    await box.put('master_password_hash', hash(password));
  }

  /// Verify master password against locally stored hash.
  Future<bool> verifyMasterPassword(String password) async {
    final box = await _getBox();
    final storedHash = box.get('master_password_hash');
    if (storedHash == null) return false;
    return storedHash == hash(password);
  }

  /// Check if a master password has been set locally.
  Future<bool> isMasterPasswordSet() async {
    final box = await _getBox();
    final localHash = box.get('master_password_hash');
    return localHash != null;
  }
}
