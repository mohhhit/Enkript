import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vault_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/biometric_service.dart';
import '../auth/cloud_auth_screen.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Security'),
          _buildBiometricTile(context),
          const Divider(),
          _buildChangeMasterPasswordTile(context),
          const Divider(),
          
          const SizedBox(height: 16),
          _buildSectionHeader(context, 'Appearance'),
          _buildThemeTile(context),
          const Divider(),
          
          const SizedBox(height: 16),
          _buildSectionHeader(context, 'Data'),
          _buildSyncWithCloudTile(context),
          const Divider(),
          _buildRemoveDuplicatesTile(context),
          const Divider(),
          _buildExportDataTile(context),
          const Divider(),
          _buildImportDataTile(context),
          const Divider(),
          _buildClearDataTile(context),
          const Divider(),
          
          const SizedBox(height: 16),
          _buildSectionHeader(context, 'Account'),
          _buildCloudAccountTile(context),
          const Divider(),
          _buildSignOutTile(context),
          const Divider(),
          
          const SizedBox(height: 32),
          _buildAboutSection(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildBiometricTile(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return SwitchListTile(
          secondary: Icon(
            BiometricService.instance.hasFingerprint
                ? Icons.fingerprint
                : Icons.face,
          ),
          title: Text('${BiometricService.instance.getBiometricTypeName()} Login'),
          subtitle: const Text('Use biometric authentication to unlock'),
          value: authProvider.isBiometricEnabled,
          onChanged: BiometricService.instance.isAvailable
              ? (value) async => await authProvider.toggleBiometric(value)
              : null,
        );
      },
    );
  }

  Widget _buildChangeMasterPasswordTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.vpn_key),
      title: const Text('Change Master Password'),
      subtitle: const Text('Update your master password'),
      onTap: () {
        // TODO: Implement change master password
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feature coming soon')),
        );
      },
    );
  }

  Widget _buildThemeTile(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return ListTile(
          leading: Icon(
            themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
          ),
          title: const Text('Theme'),
          subtitle: Text(themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode'),
          trailing: Switch(
            value: themeProvider.isDarkMode,
            onChanged: (_) => themeProvider.toggleTheme(),
          ),
          onTap: () => themeProvider.toggleTheme(),
        );
      },
    );
  }

  Widget _buildExportDataTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.download),
      title: const Text('Export Data'),
      subtitle: const Text('Backup your credentials'),
      onTap: () {
        // TODO: Implement export
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feature coming soon')),
        );
      },
    );
  }

  Widget _buildImportDataTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.upload),
      title: const Text('Import Data'),
      subtitle: const Text('Restore from backup'),
      onTap: () {
        // TODO: Implement import
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feature coming soon')),
        );
      },
    );
  }

  Widget _buildSyncWithCloudTile(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Only show sync option if user is authenticated and Firebase is available
        if (!authProvider.isFirebaseAvailable || !authProvider.isAuthenticated) {
          return const SizedBox.shrink();
        }

        return ListTile(
          leading: const Icon(Icons.cloud_sync, color: Colors.blue),
          title: const Text('Sync with Cloud'),
          subtitle: const Text('Download and merge credentials from cloud'),
          onTap: () async {
            try {
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Syncing with cloud...'),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              // Download from cloud
              await context.read<VaultProvider>().downloadFromCloud();

              if (context.mounted) {
                Navigator.pop(context); // Close loading dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Credentials synced successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                Navigator.pop(context); // Close loading dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sync failed: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        );
      },
    );
  }

  Widget _buildClearDataTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.delete_forever, color: Colors.red),
      title: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
      subtitle: const Text('Delete all local credentials'),
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Clear All Data?'),
            content: const Text(
              'This will delete all your local credentials. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );

        if (confirmed == true && context.mounted) {
          try {
            await context.read<VaultProvider>().clearAllCredentials();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All credentials cleared'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error clearing data: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      },
    );
  }

  Widget _buildRemoveDuplicatesTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.content_copy, color: Colors.orange),
      title: const Text('Remove Duplicates'),
      subtitle: const Text('Clean up duplicate credentials'),
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove Duplicates?'),
            content: const Text(
              'This will keep only one copy of each credential based on app name, username, and profile name.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove'),
              ),
            ],
          ),
        );

        if (confirmed == true && context.mounted) {
          try {
            final removed = await context.read<VaultProvider>().removeDuplicates();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed $removed duplicate(s)'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error removing duplicates: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      },
    );
  }

  Widget _buildCloudAccountTile(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (!authProvider.isFirebaseAvailable) {
          return ListTile(
            leading: const Icon(Icons.cloud_off),
            title: const Text('Offline Mode'),
            subtitle: const Text('Cloud sync not available on this platform'),
          );
        }

        if (authProvider.isAuthenticated && authProvider.userEmail != null) {
          return ListTile(
            leading: const Icon(Icons.cloud_done, color: Colors.green),
            title: const Text('Cloud Account'),
            subtitle: Text(authProvider.userEmail!),
            trailing: const Icon(Icons.verified, color: Colors.green, size: 20),
          );
        }

        return ListTile(
          leading: const Icon(Icons.cloud_off),
          title: const Text('Not Signed In'),
          subtitle: const Text('Tap to sign in to cloud'),
          onTap: () {
            // TODO: Navigate to cloud auth screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please restart the app to sign in')),
            );
          },
        );
      },
    );
  }

  Widget _buildSignOutTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout),
      title: const Text('Sign Out'),
      subtitle: const Text('Sign out of your account'),
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sign Out?'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        );

        if (confirmed == true && context.mounted) {
          final authProvider = context.read<AuthProvider>();
          await authProvider.signOut();
          
          if (context.mounted) {
            // On Firebase platforms, go to cloud auth screen
            // On offline platforms (Windows), go to login screen
            final destination = authProvider.isFirebaseAvailable
                ? const CloudAuthScreen()
                : const LoginScreen();
            
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => destination),
              (route) => false,
            );
          }
        }
      },
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Icon(
            Icons.lock_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Enkript',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.0.0',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your secure password vault',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
