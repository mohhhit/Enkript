import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/biometric_service.dart';
import '../../widgets/responsive_container.dart';
import '../home/home_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _masterPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _enableBiometric = false;
  final int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final isAvailable = await BiometricService.instance.isAvailable;
    if (isAvailable) {
      setState(() => _enableBiometric = true); // Auto-enable if available
    }
  }

  @override
  void dispose() {
    _masterPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    
    // Set master password
    await authProvider.setMasterPassword(_masterPasswordController.text);
    
    // Enable biometric if selected
    if (_enableBiometric) {
      await authProvider.toggleBiometric(true);
    }

    if (!mounted) return;

    // Navigate to home
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to Enkript',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Let\'s set up your password vault',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 24),
                      _buildMasterPasswordField(),
                      const SizedBox(height: 16),
                      _buildConfirmPasswordField(),
                      const SizedBox(height: 24),
                      if (BiometricService.instance.isAvailable)
                        _buildBiometricOption(),
                      const SizedBox(height: 32),
                      _buildSetupButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final authProvider = context.read<AuthProvider>();
    final isCloudEnabled = authProvider.isFirebaseAvailable && authProvider.isAuthenticated;
    
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Your master password encrypts all your data. Make it strong and memorable!',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (isCloudEnabled) ...[
              const SizedBox(height: 12),
              Text(
                'Note: This is different from your cloud account password. The master password encrypts your data locally.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMasterPasswordField() {
    return TextFormField(
      controller: _masterPasswordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Master Password',
        hintText: 'Enter a strong master password',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a master password';
        }
        if (value.length < 8) {
          return 'Password must be at least 8 characters';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirm,
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        hintText: 'Re-enter your master password',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
      ),
      validator: (value) {
        if (value != _masterPasswordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildBiometricOption() {
    return Card(
      child: SwitchListTile(
        title: Text('Enable ${BiometricService.instance.getBiometricTypeName()}'),
        subtitle: const Text('Use biometric auth for quick access'),
        secondary: Icon(
          BiometricService.instance.hasFingerprint
              ? Icons.fingerprint
              : Icons.face,
        ),
        value: _enableBiometric,
        onChanged: (value) => setState(() => _enableBiometric = value),
      ),
    );
  }

  Widget _buildSetupButton() {
    return ElevatedButton(
      onPressed: _completeSetup,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text(
        'Complete Setup',
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}
