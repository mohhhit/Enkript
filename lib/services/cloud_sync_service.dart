// import 'package:cloud_firestore/cloud_firestore.dart'; // Commented out for local testing
// import 'package:firebase_auth/firebase_auth.dart'; // Commented out for local testing
import '../models/credential.dart';

class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  static CloudSyncService get instance => _instance;

  // final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Commented out for local testing
  // final FirebaseAuth _auth = FirebaseAuth.instance; // Commented out for local testing

  /// Get user's credentials collection reference
  // CollectionReference? _getUserCredentialsCollection() { // Commented out for local testing
  //   final user = _auth.currentUser;
  //   if (user == null) return null;
  //   return _firestore.collection('users').doc(user.uid).collection('credentials');
  // }

  /// Sync a single credential to cloud (disabled for local testing)
  Future<void> syncCredential(Credential credential) async {
    // Cloud sync disabled for local testing
    print('Cloud sync disabled - credential saved locally only');
    return;
  }

  /// Delete credential from cloud (disabled for local testing)
  Future<void> deleteCredential(String id) async {
    // Cloud sync disabled for local testing
    print('Cloud sync disabled - credential deleted locally only');
    return;
  }

  /// Sync all local credentials to cloud (disabled for local testing)
  Future<void> syncAll(List<Credential> credentials) async {
    // Cloud sync disabled for local testing
    print('Cloud sync disabled - ${credentials.length} credentials stored locally');
    return;
  }

  /// Download all credentials from cloud (disabled for local testing)
  Future<List<Credential>> downloadAll() async {
    // Cloud sync disabled for local testing
    print('Cloud sync disabled - no cloud credentials to download');
    return [];
  }

  /// Listen to real-time changes (disabled for local testing)
  Stream<List<Credential>>? watchCredentials() {
    // Cloud sync disabled for local testing
    return null;
  }
}
