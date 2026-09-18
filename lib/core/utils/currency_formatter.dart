import 'package:intl/intl.dart';

/// Handles monetary formatting with minor units (paise/cents).
/// 1 INR = 100 paise. Amount is stored as int to prevent floating-point inaccuracies.
class CurrencyFormatter {
  static final NumberFormat _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _inrCompactFormat = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 1,
  );

  /// Formats integer paise into currency string (e.g. 15050 -> "₹150.50")
  static String format(int minorUnits, {String symbol = '₹', bool compact = false, bool showDecimals = true}) {
    final double major = minorUnits / 100.0;
    if (compact && major.abs() >= 100000) {
      return _inrCompactFormat.format(major);
    }
    if (!showDecimals || minorUnits % 100 == 0) {
      final formatter = NumberFormat.currency(locale: 'en_IN', symbol: symbol, decimalDigits: 0);
      return formatter.format(major);
    }
    return _inrFormat.format(major);
  }

  /// Parses user entered text (e.g. "150.50", "150", "₹ 2,500") into integer minor units.
  static int parseMajorToMinor(String text) {
    if (text.trim().isEmpty) return 0;
    final clean = text.replaceAll(RegExp(r'[^0-9.]'), '');
    final parts = clean.split('.');
    if (parts.isEmpty || parts[0].isEmpty) return 0;
    
    final major = int.tryParse(parts[0]) ?? 0;
    int minor = 0;
    if (parts.length > 1 && parts[1].isNotEmpty) {
      final decimalPart = parts[1].padRight(2, '0').substring(0, 2);
      minor = int.tryParse(decimalPart) ?? 0;
    }
    return (major * 100) + minor;
  }

  /// Converts minor units to double for display/input fields
  static double toDouble(int minorUnits) => minorUnits / 100.0;
}
