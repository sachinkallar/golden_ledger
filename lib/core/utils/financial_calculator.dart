/// Core Financial Calculations for Golden Ledger
/// All calculations operate on integer minor units (paise) to guarantee accuracy.
class FinancialCalculator {
  /// Savings = Income - Expenses
  static int calculateSavings({required int totalIncomeMinor, required int totalExpenseMinor}) {
    return totalIncomeMinor - totalExpenseMinor;
  }

  /// Savings Rate = (Income - Expenses) / Income * 100
  /// Guard against zero or negative income. Returns 0.0 when income <= 0.
  static double calculateSavingsRate({required int totalIncomeMinor, required int totalExpenseMinor}) {
    if (totalIncomeMinor <= 0) return 0.0;
    final savings = totalIncomeMinor - totalExpenseMinor;
    if (savings <= 0) return 0.0;
    final rate = (savings / totalIncomeMinor) * 100.0;
    return double.parse(rate.toStringAsFixed(1));
  }

  /// Percentage calculation with safe zero division guard
  static double calculatePercentage({required int portionMinor, required int totalMinor}) {
    if (totalMinor <= 0) return 0.0;
    final pct = (portionMinor / totalMinor) * 100.0;
    return double.parse(pct.toStringAsFixed(1));
  }

  /// Net Worth = Total Assets - Total Liabilities
  static int calculateNetWorth({required int totalAssetsMinor, required int totalLiabilitiesMinor}) {
    return totalAssetsMinor - totalLiabilitiesMinor;
  }

  /// Percentage change comparison between current and previous period:
  /// ((Current - Previous) / Previous) * 100.
  /// Returns null if previous is 0 to prevent misleading infinity calculations.
  static double? calculatePeriodChangePercentage({required int currentMinor, required int previousMinor}) {
    if (previousMinor == 0) return null;
    final diff = currentMinor - previousMinor;
    return double.parse(((diff / previousMinor.abs()) * 100.0).toStringAsFixed(1));
  }
}
