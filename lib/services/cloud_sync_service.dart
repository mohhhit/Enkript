import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/credential.dart';

class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  static CloudSyncService get instance => _instance;

  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;
  
  /// Check if Firebase is available on this platform
  bool get isFirebaseAvailable => true; // Firebase now supports all platforms
  
  /// Get Firestore instance (lazy init)
  FirebaseFirestore? get firestore {
    if (!isFirebaseAvailable) return null;
    _firestore ??= FirebaseFirestore.instance;
    return _firestore;
  }
  
  /// Get Auth instance (lazy init)
  FirebaseAuth? get auth {
    if (!isFirebaseAvailable) return null;
    _auth ??= FirebaseAuth.instance;
    return _auth;
  }

  /// Get user's credentials collection reference
  CollectionReference? _getUserCredentialsCollection() {
    if (!isFirebaseAvailable) return null;
    final authInstance = auth;
    final firestoreInstance = firestore;
    if (authInstance == null || firestoreInstance == null) return null;
    
    final user = authInstance.currentUser;
    if (user == null) return null;
    return firestoreInstance.collection('users').doc(user.uid).collection('credentials');
  }

  DocumentReference? _getVaultMetadataDocument(String userId) {
    final firestoreInstance = firestore;
    if (firestoreInstance == null) return null;
    // Store metadata inside the credentials collection using a special ID
    // This avoids "Missing or insufficient permissions" if rules only allow access to credentials collection
    return firestoreInstance.collection('users').doc(userId).collection('credentials').doc('vault_metadata');
  }

  /// Sync a single credential to cloud
  Future<void> syncCredential(Credential credential) async {
    try {
      if (!isFirebaseAvailable) {
        print('ℹ️ Cloud sync not available - stored locally only');
        return;
      }
      
      final collection = _getUserCredentialsCollection();
      if (collection == null) {
        print('⚠️ User not authenticated - cannot sync to cloud');
        return;
      }
      
      print('☁️ Syncing credential to cloud: ${credential.appName} for user ${auth?.currentUser?.uid}');
      await collection.doc(credential.id).set(credential.toMap());
      print('✅ Credential synced to cloud: ${credential.appName}');
    } catch (e) {
      print('❌ Cloud sync error: $e');
      // Don't rethrow - credential is still saved locally
    }
  }

  /// Store vault recovery metadata for the signed-in user.
  Future<void> saveVaultMetadata(String userId, Map<String, dynamic> metadata) async {
    try {
      if (!isFirebaseAvailable) {
        return;
      }

      final document = _getVaultMetadataDocument(userId);
      if (document == null) {
        print('⚠️ Unable to store vault metadata - Firestore unavailable');
        return;
      }

      await document.set(metadata, SetOptions(merge: true));
      print('✅ Vault metadata saved for user: $userId');
    } catch (e) {
      print('❌ Vault metadata save error: $e');
    }
  }

  /// Fetch vault recovery metadata for the signed-in user.
  Future<Map<String, dynamic>?> fetchVaultMetadata(String userId) async {
    try {
      if (!isFirebaseAvailable) {
        return null;
      }

      final document = _getVaultMetadataDocument(userId);
      if (document == null) {
        print('⚠️ Unable to fetch vault metadata - Firestore unavailable');
        return null;
      }

      final snapshot = await document.get();
      final data = snapshot.data();
      if (data is Map<String, dynamic>) {
        return data;
      }

      return null;
    } catch (e) {
      print('❌ Vault metadata fetch error: $e');
      return null;
    }
  }

  /// Delete credential from cloud
  Future<void> deleteCredential(String id) async {
    try {
      if (!isFirebaseAvailable) {
        print('ℹ️ Cloud sync not available - deleted locally only');
        return;
      }
      
      final collection = _getUserCredentialsCollection();
      if (collection == null) {
        print('User not authenticated - cannot delete from cloud');
        return;
      }
      
      await collection.doc(id).delete();
      print('✅ Credential deleted from cloud: $id');
    } catch (e) {
      print('⚠️ Cloud delete error (deleted locally): $e');
      // Don't rethrow - credential is still deleted locally
    }
  }

  /// Sync all local credentials to cloud
  Future<void> syncAll(List<Credential> credentials) async {
    try {
      if (!isFirebaseAvailable) {
        print('ℹ️ Cloud sync not available on this platform - stored locally');
        return;
      }
      
      final collection = _getUserCredentialsCollection();
      final firestoreInstance = firestore;
      if (collection == null || firestoreInstance == null) {
        print('User not authenticated - cannot sync to cloud');
        return;
      }
      
      final batch = firestoreInstance.batch();
      for (final credential in credentials) {
        final docRef = collection.doc(credential.id);
        batch.set(docRef, credential.toMap());
      }
      
      await batch.commit();
      print('✅ Synced ${credentials.length} credentials to cloud');
    } catch (e) {
      print('Error syncing all credentials to cloud: $e');
      rethrow;
    }
  }

  /// Download all credentials from cloud
  Future<List<Credential>> downloadAll() async {
    try {
      if (!isFirebaseAvailable) {
        print('ℹ️ Cloud sync not available - using local data only');
        return [];
      }
      
      final collection = _getUserCredentialsCollection();
      if (collection == null) {
        print('⚠️ User not authenticated - cannot download from cloud');
        return [];
      }
      
      final user = auth?.currentUser;
      print('📥 Downloading credentials for user: ${user?.uid}');
      
      final snapshot = await collection.get();
      print('📦 Firestore returned ${snapshot.docs.length} documents');
      
      final credentials = snapshot.docs
          .where((doc) => doc.id != 'vault_metadata')
          .map((doc) {
            try {
              return Credential.fromMap(doc.data() as Map<String, dynamic>);
            } catch (e) {
              print('⚠️ Error parsing credential ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Credential>() // Filter out nulls
          .toList();
      
      print('✅ Downloaded ${credentials.length} credentials from cloud');
      return credentials;
    } catch (e, stackTrace) {
      print('❌ Cloud download error: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Listen to real-time changes
  Stream<List<Credential>>? watchCredentials() {
    if (!isFirebaseAvailable) return null;
    
    final collection = _getUserCredentialsCollection();
    if (collection == null) return null;
    
    return collection.snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != 'vault_metadata')
          .map((doc) => Credential.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }
}
