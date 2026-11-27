import 'package:flutter/services.dart';

/// Utilities for formatting and parsing Vietnamese currency amounts.
abstract final class CurrencyFormatter {
  /// Formats a numeric amount as `1.800.000 ₫`.
  static String formatVnd(num amount, {bool withSymbol = true}) {
    final isNegative = amount < 0;
    final rounded = amount.abs().round();
    final digits = rounded.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      final reverseIndex = digits.length - i;
      buffer.write(digits[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    final prefix = isNegative ? '-' : '';
    final suffix = withSymbol ? ' ₫' : '';
    return '$prefix$buffer$suffix';
  }

  /// Formats a signed transaction amount such as `-85.000 ₫`.
  static String formatSignedVnd(num amount) {
    if (amount > 0) {
      return '+${formatVnd(amount)}';
    }
    return formatVnd(amount);
  }

  /// Parses formatted strings like `3.000.000 ₫` or `3000000` into a double.
  static double? tryParseVnd(String raw) {
    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return null;
    return double.tryParse(digitsOnly);
  }
}

/// TextInputFormatter that keeps digits formatted with `.` thousand separators.
class VndInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue();
    }

    final parsed = int.tryParse(digits);
    if (parsed == null) {
      return oldValue;
    }

    final formatted = CurrencyFormatter.formatVnd(parsed, withSymbol: false);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
