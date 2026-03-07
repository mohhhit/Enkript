import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/password_generator_service.dart';

class PasswordGeneratorDialog extends StatefulWidget {
  const PasswordGeneratorDialog({super.key});

  @override
  State<PasswordGeneratorDialog> createState() => _PasswordGeneratorDialogState();
}

class _PasswordGeneratorDialogState extends State<PasswordGeneratorDialog> {
  int _length = 16;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;
  bool _excludeAmbiguous = false;
  String _generatedPassword = '';
  int _strength = 0;

  @override
  void initState() {
    super.initState();
    _generatePassword();
  }

  void _generatePassword() {
    setState(() {
      _generatedPassword = PasswordGeneratorService.instance.generatePassword(
        length: _length,
        includeUppercase: _includeUppercase,
        includeLowercase: _includeLowercase,
        includeNumbers: _includeNumbers,
        includeSymbols: _includeSymbols,
        excludeAmbiguous: _excludeAmbiguous,
      );
      _strength = PasswordGeneratorService.instance
          .calculatePasswordStrength(_generatedPassword);
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _generatedPassword));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Password Generator'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Generated Password Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _generatedPassword,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: _copyToClipboard,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _generatePassword,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Password Strength
            _buildStrengthIndicator(),
            const SizedBox(height: 24),

            // Length Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Length'),
                Text('$_length', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: _length.toDouble(),
              min: 8,
              max: 32,
              divisions: 24,
              label: _length.toString(),
              onChanged: (value) {
                setState(() => _length = value.toInt());
                _generatePassword();
              },
            ),
            const SizedBox(height: 16),

            // Options
            CheckboxListTile(
              title: const Text('Uppercase (A-Z)'),
              value: _includeUppercase,
              onChanged: (value) {
                setState(() => _includeUppercase = value ?? true);
                _generatePassword();
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Lowercase (a-z)'),
              value: _includeLowercase,
              onChanged: (value) {
                setState(() => _includeLowercase = value ?? true);
                _generatePassword();
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Numbers (0-9)'),
              value: _includeNumbers,
              onChanged: (value) {
                setState(() => _includeNumbers = value ?? true);
                _generatePassword();
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Symbols (!@#\$%^&*)'),
              value: _includeSymbols,
              onChanged: (value) {
                setState(() => _includeSymbols = value ?? true);
                _generatePassword();
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Exclude Ambiguous'),
              subtitle: const Text('Avoid 0, O, l, 1, I, |'),
              value: _excludeAmbiguous,
              onChanged: (value) {
                setState(() => _excludeAmbiguous = value ?? false);
                _generatePassword();
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _generatedPassword),
          child: const Text('Use Password'),
        ),
      ],
    );
  }

  Widget _buildStrengthIndicator() {
    Color color;
    String label;

    if (_strength < 30) {
      color = Colors.red;
      label = 'Weak';
    } else if (_strength < 60) {
      color = Colors.orange;
      label = 'Fair';
    } else if (_strength < 80) {
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
            Text('Strength: $label', style: TextStyle(color: color)),
            Text('$_strength%', style: TextStyle(color: color)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: _strength / 100,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }
}
