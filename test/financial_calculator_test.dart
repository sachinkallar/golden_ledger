import 'package:flutter_test/flutter_test.dart';
import 'package:golden_ledger/core/utils/financial_calculator.dart';
import 'package:golden_ledger/core/utils/currency_formatter.dart';

void main() {
  group('FinancialCalculator Tests', () {
    test('calculateSavings: correctly calculates net savings in minor units', () {
      final savings = FinancialCalculator.calculateSavings(
        totalIncomeMinor: 2500000, // ₹25,000
        totalExpenseMinor: 1258000, // ₹12,580
      );
      expect(savings, equals(1242000)); // ₹12,420
    });

    test('calculateSavingsRate: computes accurate percentage with 1 decimal', () {
      final rate = FinancialCalculator.calculateSavingsRate(
        totalIncomeMinor: 2500000, // ₹25,000
        totalExpenseMinor: 1258000, // ₹12,580
      );
      // (12420 / 25000) * 100 = 49.68% -> 49.7%
      expect(rate, equals(49.7));
    });

    test('calculateSavingsRate: safely handles zero or negative income without division by zero', () {
      final rateZero = FinancialCalculator.calculateSavingsRate(
        totalIncomeMinor: 0,
        totalExpenseMinor: 150000,
      );
      expect(rateZero, equals(0.0));

      final rateNegative = FinancialCalculator.calculateSavingsRate(
        totalIncomeMinor: -5000,
        totalExpenseMinor: 150000,
      );
      expect(rateNegative, equals(0.0));
    });

    test('calculateNetWorth: Total Assets minus Total Liabilities', () {
      final netWorth = FinancialCalculator.calculateNetWorth(
        totalAssetsMinor: 10000000, // ₹1,00,000
        totalLiabilitiesMinor: 1500000, // ₹15,000 (credit card / loan)
      );
      expect(netWorth, equals(8500000)); // ₹85,000
    });

    test('calculatePeriodChangePercentage: safely handles zero previous amount', () {
      final change = FinancialCalculator.calculatePeriodChangePercentage(
        currentMinor: 50000,
        previousMinor: 0,
      );
      expect(change, isNull);

      final validChange = FinancialCalculator.calculatePeriodChangePercentage(
        currentMinor: 9000,
        previousMinor: 10000,
      );
      expect(validChange, equals(-10.0)); // 10% decrease
    });
  });

  group('CurrencyFormatter Tests', () {
    test('format: formats minor units to clean Indian Rupee notation', () {
      expect(CurrencyFormatter.format(15000), equals('₹150'));
      expect(CurrencyFormatter.format(15050), equals('₹150.50'));
      expect(CurrencyFormatter.format(2500000), equals('₹25,000'));
    });

    test('parseMajorToMinor: accurately parses user entered strings', () {
      expect(CurrencyFormatter.parseMajorToMinor('150'), equals(15000));
      expect(CurrencyFormatter.parseMajorToMinor('₹ 150.50'), equals(15050));
      expect(CurrencyFormatter.parseMajorToMinor('25,000'), equals(2500000));
      expect(CurrencyFormatter.parseMajorToMinor(''), equals(0));
    });
  });
}
