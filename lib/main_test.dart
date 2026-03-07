import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/vault_provider.dart';
import 'providers/theme_provider.dart';
import 'services/biometric_service.dart';
import 'services/encryption_service.dart';

// Simple test screen
class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enkript - Test Mode'),
        backgroundColor: Colors.purple,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_rounded,
              size: 100,
              color: Colors.purple,
            ),
            const SizedBox(height: 24),
            const Text(
              'Enkript is Running!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Test mode - App initialized successfully',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                print('Button clicked!');
              },
              child: const Text('Test Button'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Hive for local storage
    await Hive.initFlutter();
    print('✓ Hive initialized');
    
    // Initialize Services
    await EncryptionService.instance.initialize();
    print('✓ Encryption service initialized');
    
    await BiometricService.instance.initialize();
    print('✓ Biometric service initialized');
    
    print('✓ All services initialized successfully!');
  } catch (e) {
    print('Error during initialization: $e');
  }
  
  runApp(const EnkriptApp());
}

class EnkriptApp extends StatelessWidget {
  const EnkriptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VaultProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Enkript',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const TestScreen(), // Using test screen instead of splash
          );
        },
      ),
    );
  }
}
