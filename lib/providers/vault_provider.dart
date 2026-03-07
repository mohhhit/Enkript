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
      
      // Sync to cloud
      await CloudSyncService.instance.syncCredential(credential);
      
      notifyListeners();
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
      
      // Sync to cloud
      await CloudSyncService.instance.syncCredential(credential);
      
      notifyListeners();
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
      
      // Delete from cloud
      await CloudSyncService.instance.deleteCredential(id);
      
      notifyListeners();
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
