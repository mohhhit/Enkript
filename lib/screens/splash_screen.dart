import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/vault_provider.dart';
import 'auth/cloud_auth_screen.dart';
import 'auth/login_screen.dart';
import 'auth/setup_screen.dart';
import 'home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    
    // On platforms with Firebase (Android, iOS, Web), check cloud authentication first
    if (authProvider.isFirebaseAvailable) {
      // Wait a moment for Firebase auth state to be checked
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      // If not signed in to cloud account, show cloud auth screen
      if (!authProvider.isAuthenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CloudAuthScreen()),
        );
        return;
      }
      
      // User is authenticated - download credentials from cloud
      print('📥 User is authenticated, downloading credentials from cloud...');
      final vaultProvider = context.read<VaultProvider>();
      await vaultProvider.downloadFromCloud();
    }
    
    if (!mounted) return;
    
    // Check if master password is set (for local encryption)
    final isMasterPasswordSet = await authProvider.isMasterPasswordSet();

    if (!mounted) return;

    if (!isMasterPasswordSet) {
      // First time setup - create master password
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SetupScreen()),
      );
    } else {
      // Master password exists - need to unlock
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_rounded,
                size: 100,
                color: Colors.white,
              ),
              SizedBox(height: 24),
              Text(
                'Enkript',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your secure password vault',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 48),
              CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
