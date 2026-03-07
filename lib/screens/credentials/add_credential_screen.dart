import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/credential.dart';
import '../../providers/vault_provider.dart';
import '../../services/encryption_service.dart';
import '../../services/password_generator_service.dart';
import '../../widgets/password_generator_dialog.dart';

class AddCredentialScreen extends StatefulWidget {
  final Credential? credential;

  const AddCredentialScreen({super.key, this.credential});

  @override
  State<AddCredentialScreen> createState() => _AddCredentialScreenState();
}

class _AddCredentialScreenState extends State<AddCredentialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _appNameController = TextEditingController();
  final _profileNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _websiteController = TextEditingController();
  final _notesController = TextEditingController();

  bool _obscurePassword = true;
  String? _selectedCategory;
  int _passwordStrength = 0;

  final List<String> _categories = [
    'Social',
    'Banking',
    'Email',
    'Work',
    'Shopping',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.credential != null) {
      _loadCredential();
    }
    _passwordController.addListener(_updatePasswordStrength);
  }

  void _loadCredential() {
    final cred = widget.credential!;
    _appNameController.text = cred.appName;
    _profileNameController.text = cred.profileName;
    _usernameController.text = cred.username;
    _passwordController.text = EncryptionService.instance.decrypt(cred.encryptedPassword);
    _websiteController.text = cred.website ?? '';
    _notesController.text = cred.notes ?? '';
    _selectedCategory = cred.category;
  }

  void _updatePasswordStrength() {
    setState(() {
      _passwordStrength = PasswordGeneratorService.instance
          .calculatePasswordStrength(_passwordController.text);
    });
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _profileNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveCredential() async {
    if (!_formKey.currentState!.validate()) return;

    final encryptedPassword = EncryptionService.instance.encrypt(_passwordController.text);

    final credential = Credential(
      id: widget.credential?.id ?? const Uuid().v4(),
      appName: _appNameController.text.trim(),
      profileName: _profileNameController.text.trim(),
      username: _usernameController.text.trim(),
      encryptedPassword: encryptedPassword,
      website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      category: _selectedCategory,
      createdAt: widget.credential?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      isFavorite: widget.credential?.isFavorite ?? false,
    );

    try {
      final vaultProvider = context.read<VaultProvider>();
      if (widget.credential == null) {
        await vaultProvider.addCredential(credential);
      } else {
        await vaultProvider.updateCredential(credential);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.credential == null
                ? 'Credential added successfully'
                : 'Credential updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving credential: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showPasswordGenerator() async {
    final password = await showDialog<String>(
      context: context,
      builder: (context) => const PasswordGeneratorDialog(),
    );

    if (password != null) {
      setState(() {
        _passwordController.text = password;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.credential == null ? 'Add Credential' : 'Edit Credential'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveCredential,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _appNameController,
              decoration: const InputDecoration(
                labelText: 'App/Website Name',
                hintText: 'e.g., Facebook, Gmail',
                prefixIcon: Icon(Icons.apps),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter app name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _profileNameController,
              decoration: const InputDecoration(
                labelText: 'Profile/Account Name',
                hintText: 'e.g., Personal, Work',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter profile name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username/Email',
                hintText: 'Enter username or email',
                prefixIcon: Icon(Icons.account_circle),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter username' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.auto_awesome),
                      onPressed: _showPasswordGenerator,
                      tooltip: 'Generate Password',
                    ),
                    IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ],
                ),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter password' : null,
            ),
            const SizedBox(height: 8),
            _buildPasswordStrengthIndicator(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Website (Optional)',
                hintText: 'https://example.com',
                prefixIcon: Icon(Icons.language),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category.toLowerCase(),
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Add any additional notes',
                prefixIcon: Icon(Icons.note),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    Color color;
    String label;

    if (_passwordStrength < 30) {
      color = Colors.red;
      label = 'Weak';
    } else if (_passwordStrength < 60) {
      color = Colors.orange;
      label = 'Fair';
    } else if (_passwordStrength < 80) {
      color = Colors.blue;
      label = 'Good';
    } else {
      color = Colors.green;
      label = 'Strong';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Password Strength: $label',
              style: TextStyle(fontSize: 12, color: color),
            ),
            Text(
              '$_passwordStrength%',
              style: TextStyle(fontSize: 12, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: _passwordStrength / 100,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }
}
