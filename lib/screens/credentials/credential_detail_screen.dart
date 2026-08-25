import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/credential.dart';
import '../../providers/vault_provider.dart';
import '../../services/encryption_service.dart';
import '../../services/biometric_service.dart';
import '../../providers/auth_provider.dart';
import 'add_credential_screen.dart';

class CredentialDetailScreen extends StatefulWidget {
  final Credential credential;

  const CredentialDetailScreen({super.key, required this.credential});

  @override
  State<CredentialDetailScreen> createState() => _CredentialDetailScreenState();
}

class _CredentialDetailScreenState extends State<CredentialDetailScreen> {
  bool _isPasswordVisible = false;
  String? _decryptedPassword;
  String? _passwordError;

  Future<bool> _promptForMasterPassword() async {
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    String? error;
    bool? isValid;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Authentication Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Enter your master password to view this credential.'),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Master Password',
                  errorText: error,
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => obscurePassword = !obscurePassword),
                  ),
                ),
                onSubmitted: (value) async {
                  isValid = await context.read<AuthProvider>().verifyMasterPassword(value);
                  if (isValid == true && context.mounted) {
                    Navigator.pop(context);
                  } else if (context.mounted) {
                    setState(() => error = 'Invalid master password');
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                isValid = false;
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                isValid = await context.read<AuthProvider>().verifyMasterPassword(passwordController.text);
                if (isValid == true && context.mounted) {
                  Navigator.pop(context);
                } else if (context.mounted) {
                  setState(() => error = 'Invalid master password');
                }
              },
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    );

    return isValid ?? false;
  }

  Future<void> _togglePasswordVisibility() async {
    if (!_isPasswordVisible) {
      bool authenticated = false;
      
      if (BiometricService.instance.isAvailable) {
        // Require biometric auth to view password
        authenticated = await BiometricService.instance.authenticate(
          localizedReason: 'Authenticate to view password',
        );
      } else {
        // Fallback to master password
        authenticated = await _promptForMasterPassword();
      }

      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      _decryptedPassword = EncryptionService.instance.tryDecrypt(
        widget.credential.encryptedPassword,
      );

      if (_decryptedPassword == null) {
        _passwordError = 'Unable to decrypt password on this device.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to decrypt password'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
      _passwordError = null;
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteCredential() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Credential'),
        content: const Text('Are you sure you want to delete this credential?'),
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

    if (confirmed == true && mounted) {
      try {
        await context.read<VaultProvider>().deleteCredential(widget.credential.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Credential deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting credential: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.credential.appName),
        actions: [
          IconButton(
            icon: Icon(
              widget.credential.isFavorite ? Icons.star : Icons.star_border,
              color: widget.credential.isFavorite ? Colors.amber : null,
            ),
            onPressed: () {
              context.read<VaultProvider>().toggleFavorite(widget.credential.id);
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddCredentialScreen(credential: widget.credential),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteCredential,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
          _buildInfoCard(
            'App/Website',
            widget.credential.appName,
            Icons.apps,
            onCopy: () => _copyToClipboard(widget.credential.appName, 'App name'),
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Profile',
            widget.credential.profileName,
            Icons.person,
            onCopy: () => _copyToClipboard(widget.credential.profileName, 'Profile name'),
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Username',
            widget.credential.username,
            Icons.account_circle,
            onCopy: () => _copyToClipboard(widget.credential.username, 'Username'),
          ),
          const SizedBox(height: 12),
          _buildPasswordCard(),
          if (widget.credential.website != null) ...[
            const SizedBox(height: 12),
            _buildInfoCard(
              'Website',
              widget.credential.website!,
              Icons.language,
              onCopy: () => _copyToClipboard(widget.credential.website!, 'Website'),
            ),
          ],
          if (widget.credential.category != null) ...[
            const SizedBox(height: 12),
            _buildInfoCard(
              'Category',
              widget.credential.category!,
              Icons.category,
            ),
          ],
          if (widget.credential.notes != null) ...[
            const SizedBox(height: 12),
            _buildNotesCard(),
          ],
          const SizedBox(height: 24),
          _buildMetadataCard(),
        ],
      ))),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon,
      {VoidCallback? onCopy}) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: onCopy != null
            ? IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: onCopy,
              )
            : null,
      ),
    );
  }

  Widget _buildPasswordCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.lock),
        title: const Text(
          'Password',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        subtitle: Text(
          _isPasswordVisible
              ? (_decryptedPassword ?? _passwordError ?? 'Unable to decrypt password')
              : '••••••••',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isPasswordVisible && _decryptedPassword != null)
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () => _copyToClipboard(_decryptedPassword!, 'Password'),
              ),
            IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                size: 20,
              ),
              onPressed: _togglePasswordVisibility,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.note, size: 20),
                SizedBox(width: 8),
                Text(
                  'Notes',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.credential.notes!,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataCard() {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetadataRow(
              'Created',
              _formatDate(widget.credential.createdAt),
            ),
            const SizedBox(height: 8),
            _buildMetadataRow(
              'Last Modified',
              _formatDate(widget.credential.updatedAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
