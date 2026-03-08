import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/biometric_service.dart';
import '../../widgets/responsive_container.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isBiometricAvailable = false;
  bool _isBiometricLoading = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    print('🔵 Checking biometric availability...');
    final available = await BiometricService.instance.isAvailable;
    print('🔵 Biometric available: $available');
    
    if (mounted) {
      setState(() => _isBiometricAvailable = available);
    }
    
    // Don't auto-attempt biometric on screen load - let user manually trigger it
    // This prevents issues with dialog appearing before screen is fully rendered
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometricAuth() async {
    if (_isBiometricLoading) return; // Prevent double-tap
    
    print('🔵 Biometric button pressed');
    print('🔵 Biometric available: $_isBiometricAvailable');
    
    if (!_isBiometricAvailable) {
      _showError('Biometric authentication not available on this device');
      return;
    }
    
    // Check if biometrics are enrolled
    final biometrics = BiometricService.instance.availableBiometrics;
    print('🔵 Enrolled biometrics: $biometrics');
    
    if (biometrics.isEmpty) {
      _showError('Please enroll fingerprint in your device settings first');
      return;
    }
    
    setState(() => _isBiometricLoading = true);
    
    try {
      print('🔐 Calling BiometricService.authenticate()...');
      final authenticated = await BiometricService.instance.authenticate(
        localizedReason: 'Unlock Enkript',
      );
      
      print('🔵 Authentication result: $authenticated');
      
      if (mounted) {
        setState(() => _isBiometricLoading = false);
        
        if (authenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          print('⚠️ Authentication returned false');
          _showError('Biometric authentication failed. Please try again.');
        }
      }
    } catch (e) {
      print('❌ Error in _tryBiometricAuth: $e');
      if (mounted) {
        setState(() => _isBiometricLoading = false);
        _showError('Error: ${e.toString()}');
      }
    }
  }

  Future<void> _login() async {
    if (_passwordController.text.isEmpty) {
      _showError('Please enter your master password');
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final isValid = await authProvider.verifyMasterPassword(_passwordController.text);

    if (mounted) {
      setState(() => _isLoading = false);

      if (isValid) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        _showError('Invalid master password');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 500,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.lock_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome Back',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your master password to unlock',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Master Password',
                  hintText: 'Enter your master password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Unlock',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              if (_isBiometricAvailable) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isBiometricLoading ? null : _tryBiometricAuth,
                  icon: _isBiometricLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          BiometricService.instance.hasFingerprint
                              ? Icons.fingerprint
                              : Icons.face,
                        ),
                  label: Text(_isBiometricLoading
                      ? 'Authenticating...'
                      : 'Use ${BiometricService.instance.getBiometricTypeName()}'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
