import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/vault_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/credential.dart';
import '../credentials/add_credential_screen.dart';
import '../credentials/credential_detail_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/credential_card.dart';
import '../../widgets/empty_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeVault();
  }

  Future<void> _initializeVault() async {
    await context.read<VaultProvider>().initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enkript'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_sync),
            onPressed: () {
              context.read<VaultProvider>().syncWithCloud();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildQuickFilters(),
          Expanded(child: _buildCredentialsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCredentialScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search credentials...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<VaultProvider>().searchCredentials('');
                  },
                )
              : null,
        ),
        onChanged: (value) {
          context.read<VaultProvider>().searchCredentials(value);
        },
      ),
    );
  }

  Widget _buildQuickFilters() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip('All', null),
          _buildFilterChip('Favorites', 'favorites'),
          _buildFilterChip('Social', 'social'),
          _buildFilterChip('Banking', 'banking'),
          _buildFilterChip('Email', 'email'),
          _buildFilterChip('Work', 'work'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? category) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: false,
        onSelected: (selected) {
          context.read<VaultProvider>().filterByCategory(category);
        },
      ),
    );
  }

  Widget _buildCredentialsList() {
    return Consumer<VaultProvider>(
      builder: (context, vaultProvider, _) {
        if (vaultProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vaultProvider.credentials.isEmpty) {
          return const EmptyState(
            icon: Icons.lock_open,
            title: 'No Credentials Yet',
            message: 'Tap the + button to add your first credential',
          );
        }

        // Group credentials by app name
        final groupedCredentials = <String, List<Credential>>{};
        for (var credential in vaultProvider.credentials) {
          groupedCredentials.putIfAbsent(credential.appName, () => []).add(credential);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groupedCredentials.length,
          itemBuilder: (context, index) {
            final appName = groupedCredentials.keys.elementAt(index);
            final credentials = groupedCredentials[appName]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        appName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${credentials.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...credentials.map((credential) => CredentialCard(
                      credential: credential,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CredentialDetailScreen(credential: credential),
                          ),
                        );
                      },
                    )),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }
}
