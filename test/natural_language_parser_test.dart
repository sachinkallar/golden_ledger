import 'package:flutter_test/flutter_test.dart';
import 'package:golden_ledger/features/natural_entry/natural_language_parser.dart';
import 'package:golden_ledger/features/transactions/domain/transaction_model.dart';

void main() {
  group('NaturalLanguageParser Tests', () {
    test('parses "spent 150 on lunch"', () {
      final parsed = NaturalLanguageParser.parse('spent 150 on lunch');
      expect(parsed, isNotNull);
      expect(parsed!.type, equals(TransactionType.expense));
      expect(parsed.amountMinor, equals(15000));
      expect(parsed.suggestedCategoryId, equals('cat_food'));
      expect(parsed.description.toLowerCase(), contains('lunch'));
    });

    test('parses "salary 25000"', () {
      final parsed = NaturalLanguageParser.parse('salary 25000');
      expect(parsed, isNotNull);
      expect(parsed!.type, equals(TransactionType.income));
      expect(parsed.amountMinor, equals(2500000));
      expect(parsed.suggestedCategoryId, equals('cat_salary'));
    });

    test('parses "coffee 60"', () {
      final parsed = NaturalLanguageParser.parse('coffee 60');
      expect(parsed, isNotNull);
      expect(parsed!.type, equals(TransactionType.expense));
      expect(parsed.amountMinor, equals(6000));
      expect(parsed.suggestedCategoryId, equals('cat_coffee'));
    });

    test('parses "paid 2000 rent"', () {
      final parsed = NaturalLanguageParser.parse('paid 2000 rent');
      expect(parsed, isNotNull);
      expect(parsed!.type, equals(TransactionType.expense));
      expect(parsed.amountMinor, equals(200000));
      expect(parsed.suggestedCategoryId, equals('cat_rent'));
    });

    test('parses "transfer 5000 to cash"', () {
      final parsed = NaturalLanguageParser.parse('transfer 5000 to cash');
      expect(parsed, isNotNull);
      expect(parsed!.type, equals(TransactionType.transfer));
      expect(parsed.amountMinor, equals(500000));
    });

    test('parses shorthand thousands "25k salary"', () {
      final parsed = NaturalLanguageParser.parse('25k salary');
      expect(parsed, isNotNull);
      expect(parsed!.type, equals(TransactionType.income));
      expect(parsed.amountMinor, equals(2500000));
    });

    test('returns null for empty or non-numeric strings', () {
      expect(NaturalLanguageParser.parse(''), isNull);
      expect(NaturalLanguageParser.parse('just some words without numbers'), isNull);
    });
  });
}
