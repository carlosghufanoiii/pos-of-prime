import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  /// Formats a double value to Philippine Peso currency string
  /// Example: 1234.56 -> ₱1,234.56
  static String format(double amount) {
    return _formatter.format(amount);
  }

  /// Formats a double value to Philippine Peso currency string without symbol
  /// Example: 1234.56 -> 1,234.56
  static String formatWithoutSymbol(double amount) {
    return NumberFormat('#,##0.00', 'en_PH').format(amount);
  }

  /// Parses a currency string to double
  /// Handles both ₱1,234.56 and 1,234.56 formats
  static double parse(String currencyString) {
    // Remove currency symbol and spaces
    String cleanString = currencyString
        .replaceAll('₱', '')
        .replaceAll(',', '')
        .trim();

    return double.tryParse(cleanString) ?? 0.0;
  }

  /// Validates if a string represents a valid currency amount
  static bool isValidAmount(String value) {
    try {
      double amount = parse(value);
      return amount >= 0;
    } catch (e) {
      return false;
    }
  }

  /// Calculates tax amount (VAT) - Philippines VAT is 12%
  static double calculateVAT(double amount) {
    return amount * 0.12;
  }

  /// Calculates amount inclusive of VAT
  static double addVAT(double amount) {
    return amount * 1.12;
  }

  /// Calculates amount exclusive of VAT from VAT-inclusive amount
  static double removeVAT(double inclusiveAmount) {
    return inclusiveAmount / 1.12;
  }

  /// Rounds amount to nearest centavo (0.01)
  static double roundToCentavo(double amount) {
    return (amount * 100).round() / 100;
  }
}
