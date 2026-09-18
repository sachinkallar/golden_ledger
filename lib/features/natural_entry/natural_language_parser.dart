import '../transactions/domain/transaction_model.dart';

class ParsedTransaction {
  final TransactionType type;
  final int amountMinor;
  final String? suggestedCategoryId;
  final String description;
  final DateTime date;
  final double confidence;

  const ParsedTransaction({
    required this.type,
    required this.amountMinor,
    this.suggestedCategoryId,
    required this.description,
    required this.date,
    this.confidence = 0.8,
  });
}

class NaturalLanguageParser {
  static const Map<String, List<String>> _categoryKeywords = {
    'cat_food': ['lunch', 'dinner', 'breakfast', 'meal', 'food', 'restaurant', 'eat', 'burger', 'pizza', 'biryani', 'swiggy', 'zomato'],
    'cat_groceries': ['grocery', 'groceries', 'supermarket', 'blinkit', 'zepto', 'milk', 'vegetables', 'fruits', 'mart'],
    'cat_coffee': ['coffee', 'tea', 'chai', 'starbucks', 'cafe', 'snack', 'snacks'],
    'cat_transport': ['uber', 'ola', 'rapido', 'auto', 'taxi', 'cab', 'bus', 'train', 'metro', 'fare', 'toll'],
    'cat_fuel': ['fuel', 'petrol', 'diesel', 'gas'],
    'cat_bills': ['bill', 'electricity', 'water', 'wifi', 'broadband', 'internet', 'maintenance'],
    'cat_rent': ['rent', 'flat', 'house rent', 'room rent'],
    'cat_subs': ['subscription', 'netflix', 'spotify', 'youtube', 'prime', 'icloud', 'hotstar'],
    'cat_shopping': ['shopping', 'clothes', 'shoes', 'amazon', 'flipkart', 'myntra', 'zara', 'h&m'],
    'cat_entertainment': ['movie', 'cinema', 'pvr', 'theatre', 'game', 'concert'],
    'cat_health': ['doctor', 'medicine', 'pharmacy', 'hospital', 'clinic', 'tablet', 'medical', 'gym'],
    'cat_salary': ['salary', 'paycheck', 'payroll', 'stipend', 'bonus'],
    'cat_freelance': ['freelance', 'client', 'consulting', 'project payment'],
    'cat_cashback': ['cashback', 'refund', 'reward', 'gpay reward'],
  };

  static ParsedTransaction? parse(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;

    final lower = text.toLowerCase();

    TransactionType type = TransactionType.expense;
    if (lower.contains('transfer') || lower.contains('moved to') || lower.contains('sent to')) {
      type = TransactionType.transfer;
    } else if (lower.contains('salary') ||
        lower.contains('income') ||
        lower.contains('earned') ||
        lower.contains('received') ||
        lower.contains('cashback') ||
        lower.contains('got ')) {
      type = TransactionType.income;
    }

    final amountRegex = RegExp(r'(?:₹|rs\.?|inr)?\s*(\d+(?:,\d+)*(?:\.\d+)?)\s*(k)?', caseSensitive: false);
    final match = amountRegex.firstMatch(lower);
    if (match == null) return null;

    final numberStr = match.group(1)!.replaceAll(',', '');
    final isThousands = match.group(2) != null;
    double amountMajor = double.tryParse(numberStr) ?? 0.0;
    if (isThousands) {
      amountMajor *= 1000;
    }
    final int amountMinor = (amountMajor * 100).round();
    if (amountMinor <= 0) return null;

    String? matchedCategory;
    for (final entry in _categoryKeywords.entries) {
      for (final kw in entry.value) {
        if (lower.contains(kw)) {
          matchedCategory = entry.key;
          break;
        }
      }
      if (matchedCategory != null) break;
    }

    matchedCategory ??= (type == TransactionType.income ? 'cat_salary' : 'cat_food');

    String cleanDesc = lower
        .replaceAll(match.group(0)!, '')
        .replaceAll(RegExp(r'(spent|paid|for|on|bought|got|received|rs|inr|rupees)'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleanDesc.isEmpty) {
      cleanDesc = type == TransactionType.income ? 'Income' : 'Quick Expense';
    } else {
      cleanDesc = cleanDesc[0].toUpperCase() + cleanDesc.substring(1);
    }

    DateTime date = DateTime.now();
    if (lower.contains('yesterday')) {
      date = date.subtract(const Duration(days: 1));
    }

    return ParsedTransaction(
      type: type,
      amountMinor: amountMinor,
      suggestedCategoryId: matchedCategory,
      description: cleanDesc,
      date: date,
      confidence: 0.9,
    );
  }
}
