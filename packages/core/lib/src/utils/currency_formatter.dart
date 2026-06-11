/// Utility class for formatting Vietnamese Dong (VND) currency values.
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Formats a number as VND currency.
  ///
  /// Example: 199000 -> "199.000d"
  /// Example: 1500000 -> "1.500.000d"
  /// Example: 0 -> "0d"
  static String formatVND(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final intPart = absAmount.truncate();
    final formatted = _addThousandSeparator(intPart.toString());
    return '${isNegative ? '-' : ''}$formatted\u0111';
  }

  /// Formats a number as VND currency with the currency symbol separated.
  ///
  /// Example: 199000 -> "199.000 VND"
  static String formatVNDFull(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final intPart = absAmount.truncate();
    final formatted = _addThousandSeparator(intPart.toString());
    return '${isNegative ? '-' : ''}$formatted VND';
  }

  /// Formats a compact representation for large values.
  ///
  /// Example: 1500000 -> "1.5tr"
  /// Example: 150000 -> "150k"
  /// Example: 1500 -> "1.500d"
  static String formatCompact(double amount) {
    final absAmount = amount.abs();
    final prefix = amount < 0 ? '-' : '';

    if (absAmount >= 1000000000) {
      final value = absAmount / 1000000000;
      return '$prefix${_formatDecimal(value)}t\u1ef7';
    } else if (absAmount >= 1000000) {
      final value = absAmount / 1000000;
      return '$prefix${_formatDecimal(value)}tr';
    } else if (absAmount >= 100000) {
      final value = absAmount / 1000;
      return '$prefix${_formatDecimal(value)}k';
    }

    return formatVND(amount);
  }

  static String _addThousandSeparator(String number) {
    if (number.length <= 3) return number;

    final buffer = StringBuffer();
    final remainder = number.length % 3;

    if (remainder > 0) {
      buffer.write(number.substring(0, remainder));
      if (number.length > remainder) buffer.write('.');
    }

    for (var i = remainder; i < number.length; i += 3) {
      buffer.write(number.substring(i, i + 3));
      if (i + 3 < number.length) buffer.write('.');
    }

    return buffer.toString();
  }

  static String _formatDecimal(double value) {
    if (value == value.truncateToDouble()) {
      return value.truncate().toString();
    }
    return value.toStringAsFixed(1);
  }
}
