class CurrencyFormatter {
  static String currencySymbol = '₹';

  /// Formats amount in Indian Rupee notation: ₹1,23,456
  /// Uses Indian numbering system (last 3 digits, then groups of 2).
  static String format(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();

    // If the amount has no fractional part, format as integer
    final String numberStr;
    if (absAmount == absAmount.truncateToDouble()) {
      numberStr = absAmount.toInt().toString();
    } else {
      numberStr = absAmount.toStringAsFixed(2);
    }

    final parts = numberStr.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

    final formatted = _formatIndian(integerPart);
    final sign = isNegative ? '-' : '';
    return '$sign$currencySymbol$formatted$decimalPart';
  }

  /// Formats large amounts compactly: ₹1.2K, ₹1.5L, ₹2.3Cr
  static String formatCompact(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final sign = isNegative ? '-' : '';

    if (absAmount >= 10000000) {
      // Crores (1Cr = 10,000,000)
      final cr = absAmount / 10000000;
      return '$sign$currencySymbol${_trimTrailingZeros(cr.toStringAsFixed(1))}Cr';
    }
    if (absAmount >= 100000) {
      // Lakhs (1L = 100,000)
      final lakhs = absAmount / 100000;
      return '$sign$currencySymbol${_trimTrailingZeros(lakhs.toStringAsFixed(1))}L';
    }
    if (absAmount >= 1000) {
      // Thousands
      final k = absAmount / 1000;
      return '$sign$currencySymbol${_trimTrailingZeros(k.toStringAsFixed(1))}K';
    }

    return '$sign$currencySymbol${absAmount.toInt()}';
  }

  /// Formats with explicit sign: +₹500 or -₹200
  static String formatSigned(double amount) {
    if (amount > 0) {
      return '+${format(amount)}';
    }
    if (amount < 0) {
      return format(amount); // Already has '-'
    }
    return format(amount); // ₹0
  }

  /// Formats the integer part using Indian numbering system.
  /// Last 3 digits stay together, then groups of 2.
  /// e.g. 1234567 → 12,34,567
  static String _formatIndian(String number) {
    if (number.length <= 3) return number;

    final lastThree = number.substring(number.length - 3);
    var remaining = number.substring(0, number.length - 3);

    final buffer = StringBuffer();
    while (remaining.length > 2) {
      buffer.write('${remaining.substring(remaining.length - 2)},');
      remaining = remaining.substring(0, remaining.length - 2);
    }
    if (remaining.isNotEmpty) {
      buffer.write('$remaining,');
    }

    // Reverse the comma-separated groups
    final groups = buffer.toString().split(',').where((s) => s.isNotEmpty).toList();
    final reversed = groups.reversed.join(',');

    return '$reversed,$lastThree';
  }

  /// Removes trailing '.0' from formatted compact numbers.
  static String _trimTrailingZeros(String value) {
    if (value.endsWith('.0')) {
      return value.substring(0, value.length - 2);
    }
    return value;
  }
}
