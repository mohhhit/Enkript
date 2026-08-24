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

  late Box _secureBox;
  late Encrypter _encrypter;
  late IV _iv;
  bool _isInitialized = false;
  bool _encryptionKeyGeneratedThisSession = false;

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
      _encryptionKeyGeneratedThisSession = true;
    } else {
      _encryptionKeyGeneratedThisSession = false;
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

  String? _getStoredEncryptionKey() {
    return _secureBox.get('encryption_key') as String?;
  }

  Future<void> _storeEncryptionKey(String keyString) async {
    await _secureBox.put('encryption_key', keyString);
  }

  Future<Map<String, dynamic>> _buildVaultMetadata(String password) async {
    final keyString = _getStoredEncryptionKey();
    if (keyString == null) {
      throw StateError('Encryption key missing');
    }

    final ivString = _secureBox.get('encryption_iv') as String?;

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
    await _secureBox.put('master_password_hash', metadata['masterPasswordHash']);
    await _secureBox.put('vault_key_wrap_salt', metadata['vaultKeyWrapSalt']);
    await _secureBox.put('vault_key_wrap_iv', metadata['vaultKeyWrapIv']);
    await _secureBox.put('wrapped_encryption_key', metadata['wrappedEncryptionKey']);
    if (metadata['vaultIv'] != null) {
      await _secureBox.put('encryption_iv', metadata['vaultIv']);
    }

    if (userId != null) {
      await CloudSyncService.instance.saveVaultMetadata(userId, metadata);
    }
  }

  /// Bind the current vault key to a master password and back it up.
  Future<void> bindMasterPassword(String password, {String? userId}) async {
    if (!_isInitialized) {
      await initialize();
    }

    final metadata = await _buildVaultMetadata(password);
    await _persistVaultMetadata(metadata, userId: userId);
  }

  /// Restore the vault encryption key from a password-wrapped backup.
  Future<bool> restoreEncryptionKey(String password, {String? userId}) async {
    if (!_isInitialized) {
      _secureBox = await Hive.openBox('secure_storage');
    }

    final storedKey = _secureBox.get('encryption_key') as String?;
    if (storedKey != null && !_encryptionKeyGeneratedThisSession) {
      if (!_isInitialized) {
        await initialize();
      }
      
      // We have a valid local key. 
      // Force an update to the cloud metadata to ensure the IV is backed up properly 
      // (and to overwrite any corrupt metadata from web app).
      if (userId != null) {
        await bindMasterPassword(password, userId: userId);
      }
      
      return true;
    }

    Map<String, dynamic>? metadata = {
      'masterPasswordHash': _secureBox.get('master_password_hash'),
      'vaultKeyWrapSalt': _secureBox.get('vault_key_wrap_salt'),
      'vaultKeyWrapIv': _secureBox.get('vault_key_wrap_iv'),
      'wrappedEncryptionKey': _secureBox.get('wrapped_encryption_key'),
    };

    if (metadata['wrappedEncryptionKey'] == null && userId != null) {
      metadata = await CloudSyncService.instance.fetchVaultMetadata(userId);
    }

    final wrappedKey = metadata?['wrappedEncryptionKey'] as String?;
    final wrapSalt = metadata?['vaultKeyWrapSalt'] as String?;
    final wrapIvString = metadata?['vaultKeyWrapIv'] as String?;

    if (wrappedKey == null || wrapSalt == null || wrapIvString == null) {
      return false;
    }

    final wrapKeyBytes = base64Decode(await deriveKeyFromPassword(password, wrapSalt));
    final wrapEncrypter = Encrypter(AES(Key(wrapKeyBytes), mode: AESMode.cbc));
    final unwrappedKey = wrapEncrypter.decrypt64(
      wrappedKey,
      iv: IV(base64Decode(wrapIvString)),
    );

    await _storeEncryptionKey(unwrappedKey);
    
    final vaultIv = metadata?['vaultIv'] as String?;
    if (vaultIv != null) {
      await _secureBox.put('encryption_iv', vaultIv);
      _iv = IV(base64Decode(vaultIv));
    }
    
    final key = Key(base64Decode(unwrappedKey));
    _encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    
    _encryptionKeyGeneratedThisSession = false;
    _isInitialized = true;
    
    return true;
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

  /// Try to decrypt a string without throwing.
  String? tryDecrypt(String encryptedText) {
    try {
      return decrypt(encryptedText);
    } catch (e) {
      print('❌ Decryption error: $e');
      return null;
    }
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
    _encryptionKeyGeneratedThisSession = false;
  }

  /// Store master password hash
  Future<void> storeMasterPasswordHash(String password) async {
    await _secureBox.put('master_password_hash', hash(password));
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
