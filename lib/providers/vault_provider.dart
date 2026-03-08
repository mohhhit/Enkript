import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/credential.dart';
import '../services/cloud_sync_service.dart';

class VaultProvider extends ChangeNotifier {
  List<Credential> _credentials = [];
  List<Credential> _filteredCredentials = [];
  String _searchQuery = '';
  String? _selectedCategory;
  bool _isLoading = false;

  List<Credential> get credentials => _filteredCredentials;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  /// Initialize and load credentials
  Future<void> initialize() async {
    _isLoading = true;

    try {
      // Open Hive box
      final box = await Hive.openBox<Credential>('credentials');
      _credentials = box.values.toList();
      _filteredCredentials = List.from(_credentials);
    } catch (e) {
      print('Error loading credentials: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Add a new credential
  Future<void> addCredential(Credential credential) async {
    try {
      final box = await Hive.openBox<Credential>('credentials');
      await box.put(credential.id, credential);
      _credentials.add(credential);
      _applyFilters();
      notifyListeners();
      
      // Sync to cloud in background (non-blocking)
      CloudSyncService.instance.syncCredential(credential).catchError((e) {
        print('Background sync error: $e');
      });
    } catch (e) {
      print('Error adding credential: $e');
      rethrow;
    }
  }

  /// Update an existing credential
  Future<void> updateCredential(Credential credential) async {
    try {
      final box = await Hive.openBox<Credential>('credentials');
      await box.put(credential.id, credential);
      
      final index = _credentials.indexWhere((c) => c.id == credential.id);
      if (index != -1) {
        _credentials[index] = credential;
      }
      
      _applyFilters();
      notifyListeners();
      
      // Sync to cloud in background (non-blocking)
      CloudSyncService.instance.syncCredential(credential).catchError((e) {
        print('Background sync error: $e');
      });
    } catch (e) {
      print('Error updating credential: $e');
      rethrow;
    }
  }

  /// Delete a credential
  Future<void> deleteCredential(String id) async {
    try {
      final box = await Hive.openBox<Credential>('credentials');
      await box.delete(id);
      _credentials.removeWhere((c) => c.id == id);
      _applyFilters();
      notifyListeners();
      
      // Delete from cloud in background (non-blocking)
      CloudSyncService.instance.deleteCredential(id).catchError((e) {
        print('Background delete error: $e');
      });
    } catch (e) {
      print('Error deleting credential: $e');
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

  /// Sync with cloud
  Future<void> syncWithCloud() async {
    _isLoading = true;
    notifyListeners();

    try {
      await CloudSyncService.instance.syncAll(_credentials);
      await initialize(); // Reload credentials
    } catch (e) {
      print('Error syncing with cloud: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Download credentials from cloud and merge with local
  Future<void> downloadFromCloud() async {
    _isLoading = true;
    notifyListeners();

    try {
      print('📥 Downloading credentials from cloud...');
      
      // Check if cloud is available
      if (!CloudSyncService.instance.isFirebaseAvailable) {
        print('ℹ️ Cloud sync not available - using local data only');
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Check authentication
      if (CloudSyncService.instance.auth?.currentUser == null) {
        print('⚠️ User not authenticated - cannot download from cloud');
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      final cloudCredentials = await CloudSyncService.instance.downloadAll();
      print('📦 Downloaded ${cloudCredentials.length} credentials from cloud');
      
      if (cloudCredentials.isEmpty) {
        print('ℹ️ No credentials found in cloud');
        _isLoading = false;
        notifyListeners();
        return;
      }

      final box = await Hive.openBox<Credential>('credentials');
      
      // Merge cloud credentials with local
      final Map<String, Credential> mergedMap = {};
      
      // Add all local credentials
      for (final cred in _credentials) {
        mergedMap[cred.id] = cred;
      }
      
      // Merge cloud credentials (newer ones override)
      for (final cloudCred in cloudCredentials) {
        final localCred = mergedMap[cloudCred.id];
        if (localCred == null) {
          // New credential from cloud
          mergedMap[cloudCred.id] = cloudCred;
        } else {
          // Keep the newer one
          if (cloudCred.updatedAt.isAfter(localCred.updatedAt)) {
            mergedMap[cloudCred.id] = cloudCred;
          }
        }
      }
      
      // Save merged credentials to local storage
      await box.clear();
      for (final cred in mergedMap.values) {
        await box.put(cred.id, cred);
      }
      
      _credentials = mergedMap.values.toList();
      _applyFilters();
      
      print('✅ Downloaded and merged ${cloudCredentials.length} credentials from cloud');
      print('✅ Total credentials after merge: ${_credentials.length}');
    } catch (e, stackTrace) {
      print('❌ Error downloading from cloud: $e');
      print('Stack trace: $stackTrace');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Clear all credentials
  Future<void> clearAllCredentials() async {
    try {
      final box = await Hive.openBox<Credential>('credentials');
      await box.clear();
      _credentials.clear();
      _filteredCredentials.clear();
      notifyListeners();
      print('✅ All credentials cleared');
    } catch (e) {
      print('Error clearing credentials: $e');
      rethrow;
    }
  }

  /// Remove duplicate credentials
  Future<int> removeDuplicates() async {
    try {
      final box = await Hive.openBox<Credential>('credentials');
      
      // Group credentials by app name, username, and profile name
      final Map<String, List<Credential>> groups = {};
      for (final cred in _credentials) {
        final key = '${cred.appName}|${cred.username}|${cred.profileName}'.toLowerCase();
        groups.putIfAbsent(key, () => []).add(cred);
      }
      
      int removedCount = 0;
      
      // For each group, keep the most recent one and delete the rest
      for (final group in groups.values) {
        if (group.length > 1) {
          // Sort by updatedAt, keep the newest
          group.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          
          // Delete all except the first (newest)
          for (int i = 1; i < group.length; i++) {
            await box.delete(group[i].id);
            _credentials.removeWhere((c) => c.id == group[i].id);
            removedCount++;
          }
        }
      }
      
      _applyFilters();
      notifyListeners();
      
      print('✅ Removed $removedCount duplicate credentials');
      return removedCount;
    } catch (e) {
      print('Error removing duplicates: $e');
      rethrow;
    }
  }

  /// Apply filters to credentials
  void _applyFilters() {
    _filteredCredentials = _credentials.where((credential) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          credential.appName.toLowerCase().contains(_searchQuery) ||
          credential.username.toLowerCase().contains(_searchQuery) ||
          credential.profileName.toLowerCase().contains(_searchQuery);

      // Category filter
      final matchesCategory = _selectedCategory == null ||
          credential.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }
}
