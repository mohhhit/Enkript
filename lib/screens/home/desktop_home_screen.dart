import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/vault_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/credential.dart';
import '../credentials/add_credential_screen.dart';
import '../credentials/credential_detail_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/credential_card.dart';
import '../../widgets/desktop_credential_card.dart';
import '../../widgets/empty_state.dart';
import '../../utils/platform_utils.dart';

class DesktopHomeScreen extends StatefulWidget {
  const DesktopHomeScreen({super.key});

  @override
  State<DesktopHomeScreen> createState() => _DesktopHomeScreenState();
}

class _DesktopHomeScreenState extends State<DesktopHomeScreen> {
  final _searchController = TextEditingController();
  int _selectedIndex = 0;

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
      body: Row(
        children: [
          // Sidebar Navigation
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              if (index == 1) {
                // Navigate to Settings without changing selectedIndex
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              } else {
                setState(() => _selectedIndex = index);
              }
            },
            labelType: NavigationRailLabelType.all,
            indicatorColor: Colors.transparent,
            selectedIconTheme: IconThemeData(
              color: Theme.of(context).colorScheme.primary,
            ),
            selectedLabelTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
            leading: Column(
              children: [
                const SizedBox(height: 16),
                Icon(
                  Icons.lock,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enkript',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 32),
              ],
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddCredentialScreen()),
                      );
                    },
                    child: const Icon(Icons.add),
                  ),
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Vault'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          
          // Vertical Divider
          const VerticalDivider(thickness: 1, width: 1),
          
          // Main Content
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                _buildQuickFilters(),
                Expanded(child: _buildCredentialsList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Vault',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Consumer<VaultProvider>(
                  builder: (context, vault, _) => Text(
                    '${vault.credentials.length} credentials stored securely',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ),
              ],
            ),
          ),
          // Cloud Sync Button
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (!auth.isAuthenticated) return const SizedBox.shrink();
              
              return OutlinedButton.icon(
                onPressed: () {
                  context.read<VaultProvider>().syncWithCloud();
                },
                icon: const Icon(Icons.cloud_sync),
                label: const Text('Sync with Cloud'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
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
            filled: true,
          ),
          onChanged: (value) {
            context.read<VaultProvider>().searchCredentials(value);
          },
        ),
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
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
    return FilterChip(
      label: Text(label),
      selected: false,
      onSelected: (selected) {
        context.read<VaultProvider>().filterByCategory(category);
      },
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
            message: 'Click the + button to add your first credential',
          );
        }

        // Group credentials by app name
        final groupedCredentials = <String, List<Credential>>{};
        for (var credential in vaultProvider.credentials) {
          groupedCredentials.putIfAbsent(credential.appName, () => []).add(credential);
        }

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: PlatformUtils.maxContentWidth),
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: groupedCredentials.length,
              itemBuilder: (context, index) {
                final appName = groupedCredentials.keys.elementAt(index);
                final credentials = groupedCredentials[appName]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          Text(
                            appName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${credentials.length}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...credentials.map((credential) => DesktopCredentialCard(
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
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
