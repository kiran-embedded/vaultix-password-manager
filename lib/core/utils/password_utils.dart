// lib/core/utils/password_utils.dart
import 'dart:math';

/// Password generation & strength analysis utilities.
final class PasswordUtils {
  PasswordUtils._();

  static const _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _lower = 'abcdefghijklmnopqrstuvwxyz';
  static const _digits = '0123456789';
  static const _symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  // ─── Generation ───────────────────────────────────────────────────

  static String generate({
    int length = 20,
    bool useUpper = true,
    bool useLower = true,
    bool useDigits = true,
    bool useSymbols = true,
  }) {
    final rng = Random.secure();
    final charset = StringBuffer();
    if (useUpper) charset.write(_upper);
    if (useLower) charset.write(_lower);
    if (useDigits) charset.write(_digits);
    if (useSymbols) charset.write(_symbols);

    if (charset.isEmpty) return '';
    final chars = charset.toString();

    // Ensure at least one char from each selected class
    final result = <String>[];
    if (useUpper) result.add(_upper[rng.nextInt(_upper.length)]);
    if (useLower) result.add(_lower[rng.nextInt(_lower.length)]);
    if (useDigits) result.add(_digits[rng.nextInt(_digits.length)]);
    if (useSymbols) result.add(_symbols[rng.nextInt(_symbols.length)]);

    while (result.length < length) {
      result.add(chars[rng.nextInt(chars.length)]);
    }
    result.shuffle(rng);
    return result.take(length).join();
  }

  // ─── Strength Analysis ────────────────────────────────────────────

  static PasswordStrength analyzeStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;

    int score = 0;

    // Length scoring
    if (password.length >= 8) score += 10;
    if (password.length >= 12) score += 15;
    if (password.length >= 16) score += 15;
    if (password.length >= 20) score += 10;

    // Charset diversity
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSymbol = password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]'));

    if (hasUpper) score += 10;
    if (hasLower) score += 10;
    if (hasDigit) score += 10;
    if (hasSymbol) score += 20;

    // Entropy bonus
    if (hasUpper && hasLower && hasDigit && hasSymbol) score += 10;

    if (score >= 80) return PasswordStrength.veryStrong;
    if (score >= 60) return PasswordStrength.strong;
    if (score >= 40) return PasswordStrength.medium;
    if (score >= 20) return PasswordStrength.weak;
    return PasswordStrength.veryWeak;
  }

  static int strengthScore(String password) {
    final s = analyzeStrength(password);
    return switch (s) {
      PasswordStrength.none => 0,
      PasswordStrength.veryWeak => 15,
      PasswordStrength.weak => 35,
      PasswordStrength.medium => 55,
      PasswordStrength.strong => 75,
      PasswordStrength.veryStrong => 100,
    };
  }
}

enum PasswordStrength { none, veryWeak, weak, medium, strong, veryStrong }

extension PasswordStrengthX on PasswordStrength {
  String get label => switch (this) {
    PasswordStrength.none => '',
    PasswordStrength.veryWeak => 'Very Weak',
    PasswordStrength.weak => 'Weak',
    PasswordStrength.medium => 'Medium',
    PasswordStrength.strong => 'Strong',
    PasswordStrength.veryStrong => 'Very Strong',
  };
}
