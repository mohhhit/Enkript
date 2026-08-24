import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/credential.dart';

class VaultProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Credential> _credentials = [];
  List<Credential> _filteredCredentials = [];
  String _searchQuery = '';
  String? _selectedCategory;
  bool _isLoading = false;

  List<Credential> get credentials => _filteredCredentials;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  // Helper to get the correct user's credentials collection
  CollectionReference? get _credentialsRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('credentials');
  }

  /// Initialize and load credentials from Cloud Firestore
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final ref = _credentialsRef;
      if (ref != null) {
        final snapshot = await ref.get();
        _credentials = snapshot.docs.map((doc) {
          return Credential.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
        _filteredCredentials = List.from(_credentials);
        print('✅ Loaded ${_credentials.length} credentials from Firestore');
      } else {
        print('⚠️ User not authenticated. Cannot load credentials.');
      }
    } catch (e) {
      print('❌ Error loading credentials: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Add a new credential to Firestore
  Future<void> addCredential(Credential credential) async {
    try {
      final ref = _credentialsRef;
      if (ref == null) throw Exception("User not authenticated");

      await ref.doc(credential.id).set(credential.toMap());
      
      _credentials.add(credential);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      print('❌ Error adding credential: $e');
      rethrow;
    }
  }

  /// Update an existing credential in Firestore
  Future<void> updateCredential(Credential credential) async {
    try {
      final ref = _credentialsRef;
      if (ref == null) throw Exception("User not authenticated");

      await ref.doc(credential.id).update(credential.toMap());
      
      final index = _credentials.indexWhere((c) => c.id == credential.id);
      if (index != -1) {
        _credentials[index] = credential;
      }
      
      _applyFilters();
      notifyListeners();
    } catch (e) {
      print('❌ Error updating credential: $e');
      rethrow;
    }
  }

  /// Delete a credential from Firestore
  Future<void> deleteCredential(String id) async {
    try {
      final ref = _credentialsRef;
      if (ref == null) throw Exception("User not authenticated");

      await ref.doc(id).delete();
      _credentials.removeWhere((c) => c.id == id);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      print('❌ Error deleting credential: $e');
      rethrow;
    }
  }

  /// Search credentials
  void searchCredentials(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  /// Filter by category
  void filterByCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  /// Get credentials for a specific app
  List<Credential> getCredentialsForApp(String appName) {
    return _credentials.where((c) => c.appName == appName).toList();
  }

  /// Get all unique app names
  List<String> getUniqueAppNames() {
    return _credentials.map((c) => c.appName).toSet().toList()..sort();
  }

  /// Get favorite credentials
  List<Credential> getFavorites() {
    return _credentials.where((c) => c.isFavorite).toList();
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String id) async {
    final credential = _credentials.firstWhere((c) => c.id == id);
    final updated = credential.copyWith(
      isFavorite: !credential.isFavorite,
      updatedAt: DateTime.now(),
    );
    await updateCredential(updated);
  }

  /// Sync with cloud (Now redundant, just refreshes the list)
  Future<void> syncWithCloud() async {
    await initialize();
  }

  /// Download credentials (Now redundant, just refreshes the list)
  Future<void> downloadFromCloud() async {
    await initialize();
  }

  /// Clear all credentials from Firestore
  Future<void> clearAllCredentials() async {
    try {
      final ref = _credentialsRef;
      if (ref == null) throw Exception("User not authenticated");

      final snapshot = await ref.get();
      
      // Batch delete all documents
      final batch = _db.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      _credentials.clear();
      _filteredCredentials.clear();
      notifyListeners();
      print('✅ All credentials cleared from Firestore');
    } catch (e) {
      print('❌ Error clearing credentials: $e');
      rethrow;
    }
  }

  /// Remove duplicate credentials
  Future<int> removeDuplicates() async {
    try {
      final ref = _credentialsRef;
      if (ref == null) throw Exception("User not authenticated");

      final Map<String, List<Credential>> groups = {};
      for (final cred in _credentials) {
        final key = '${cred.appName}|${cred.username}|${cred.profileName}'.toLowerCase();
        groups.putIfAbsent(key, () => []).add(cred);
      }
      
      int removedCount = 0;
      final batch = _db.batch();
      
      for (final group in groups.values) {
        if (group.length > 1) {
          group.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          
          for (int i = 1; i < group.length; i++) {
            batch.delete(ref.doc(group[i].id));
            _credentials.removeWhere((c) => c.id == group[i].id);
            removedCount++;
          }
        }
      }
      
      if (removedCount > 0) {
        await batch.commit();
      }
      
      _applyFilters();
      notifyListeners();
      
      print('✅ Removed $removedCount duplicate credentials');
      return removedCount;
    } catch (e) {
      print('❌ Error removing duplicates: $e');
      rethrow;
    }
  }

  /// Apply filters to credentials
  void _applyFilters() {
    _filteredCredentials = _credentials.where((credential) {
      final matchesSearch = _searchQuery.isEmpty ||
          credential.appName.toLowerCase().contains(_searchQuery) ||
          credential.username.toLowerCase().contains(_searchQuery) ||
          credential.profileName.toLowerCase().contains(_searchQuery);

      final matchesCategory = _selectedCategory == null ||
          credential.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }
}