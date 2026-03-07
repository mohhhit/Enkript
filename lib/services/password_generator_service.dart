import 'dart:math';

class PasswordGeneratorService {
  static final PasswordGeneratorService _instance = PasswordGeneratorService._internal();
  factory PasswordGeneratorService() => _instance;
  PasswordGeneratorService._internal();

  static PasswordGeneratorService get instance => _instance;

  final Random _random = Random.secure();

  // Character sets
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _numbers = '0123456789';
  static const String _symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  /// Generate a strong random password
  /// 
  /// [length] - Password length (default: 16)
  /// [includeUppercase] - Include uppercase letters
  /// [includeLowercase] - Include lowercase letters
  /// [includeNumbers] - Include numbers
  /// [includeSymbols] - Include special symbols
  /// [excludeAmbiguous] - Exclude ambiguous characters (0, O, l, 1, etc.)
  String generatePassword({
    int length = 16,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
    bool excludeAmbiguous = false,
  }) {
    if (length < 4) {
      throw ArgumentError('Password length must be at least 4 characters');
    }

    if (!includeUppercase && !includeLowercase && !includeNumbers && !includeSymbols) {
      throw ArgumentError('At least one character type must be included');
    }

    String charset = '';
    List<String> required = [];

    if (includeLowercase) {
      charset += _lowercase;
      required.add(_lowercase[_random.nextInt(_lowercase.length)]);
    }

    if (includeUppercase) {
      charset += _uppercase;
      required.add(_uppercase[_random.nextInt(_uppercase.length)]);
    }

    if (includeNumbers) {
      charset += _numbers;
      required.add(_numbers[_random.nextInt(_numbers.length)]);
    }

    if (includeSymbols) {
      charset += _symbols;
      required.add(_symbols[_random.nextInt(_symbols.length)]);
    }

    // Remove ambiguous characters if requested
    if (excludeAmbiguous) {
      const ambiguous = ['0', 'O', 'o', 'l', '1', 'I', '|'];
      for (var char in ambiguous) {
        charset = charset.replaceAll(char, '');
      }
    }

    // Generate remaining characters
    final remaining = length - required.length;
    final password = List<String>.from(required);

    for (var i = 0; i < remaining; i++) {
      password.add(charset[_random.nextInt(charset.length)]);
    }

    // Shuffle the password
    password.shuffle(_random);

    return password.join();
  }

  /// Generate a memorable passphrase
  String generatePassphrase({
    int wordCount = 4,
    String separator = '-',
    bool capitalize = true,
    bool includeNumber = true,
  }) {
    final words = _wordList..shuffle(_random);
    final selectedWords = words.take(wordCount).toList();

    if (capitalize) {
      for (var i = 0; i < selectedWords.length; i++) {
        selectedWords[i] = _capitalizeFirst(selectedWords[i]);
      }
    }

    if (includeNumber) {
      selectedWords.add(_random.nextInt(9999).toString().padLeft(4, '0'));
    }

    return selectedWords.join(separator);
  }

  /// Calculate password strength (0-100)
  int calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;

    int score = 0;
    
    // Length score (max 30 points)
    score += (password.length * 2).clamp(0, 30);

    // Character variety (max 40 points)
    if (RegExp(r'[a-z]').hasMatch(password)) score += 10;
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 10;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 10;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score += 10;

    // Complexity (max 30 points)
    final uniqueChars = password.split('').toSet().length;
    score += (uniqueChars * 2).clamp(0, 30);

    // Penalize common patterns
    if (RegExp(r'(012|123|234|345|456|567|678|789|abc|bcd|cde)').hasMatch(password.toLowerCase())) {
      score -= 10;
    }

    return score.clamp(0, 100);
  }

  /// Get password strength label
  String getStrengthLabel(int strength) {
    if (strength < 30) return 'Weak';
    if (strength < 60) return 'Fair';
    if (strength < 80) return 'Good';
    return 'Strong';
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Sample word list for passphrase generation
  final List<String> _wordList = [
    'apple', 'banana', 'cherry', 'dragon', 'eagle', 'forest', 'galaxy', 'harbor',
    'island', 'jungle', 'knight', 'lotus', 'mountain', 'nebula', 'ocean', 'phoenix',
    'quest', 'river', 'storm', 'tiger', 'unicorn', 'valley', 'wizard', 'xenon',
    'yellow', 'zenith', 'anchor', 'bridge', 'castle', 'diamond', 'eclipse', 'flame',
    'garden', 'horizon', 'ivory', 'jasper', 'koala', 'lightning', 'meteor', 'north',
    'orchid', 'palace', 'quartz', 'rainbow', 'silver', 'thunder', 'umbrella', 'volcano',
  ];
}
