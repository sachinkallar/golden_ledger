import '../transactions/domain/transaction_model.dart';
import '../categories/domain/category_model.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/financial_calculator.dart';

class FinancialInsight {
  final String title;
  final String description;
  final String iconName;
  final bool isPositive;

  const FinancialInsight({
    required this.title,
    required this.description,
    required this.iconName,
    this.isPositive = true,
  });
}

class FinancialInsightsService {
  static List<FinancialInsight> generateInsights({
    required List<Transaction> currentMonthTx,
    required List<Transaction> previousMonthTx,
    required List<Category> categories,
  }) {
    final insights = <FinancialInsight>[];

    final currentExpenses = currentMonthTx.where((t) => t.type == TransactionType.expense).toList();
    final currentIncomes = currentMonthTx.where((t) => t.type == TransactionType.income).toList();
    final prevExpenses = previousMonthTx.where((t) => t.type == TransactionType.expense).toList();

    final totalExpCurrent = currentExpenses.fold<int>(0, (sum, t) => sum + t.amountMinor);
    final totalIncCurrent = currentIncomes.fold<int>(0, (sum, t) => sum + t.amountMinor);
    final totalExpPrev = prevExpenses.fold<int>(0, (sum, t) => sum + t.amountMinor);

    if (currentExpenses.isEmpty && currentIncomes.isEmpty) {
      return [
        const FinancialInsight(
          title: 'Start Tracking',
          description: 'Record your daily expenses and income to see personalized financial insights and observations.',
          iconName: 'category',
          isPositive: true,
        ),
      ];
    }

    if (totalIncCurrent > 0) {
      final rate = FinancialCalculator.calculateSavingsRate(
        totalIncomeMinor: totalIncCurrent,
        totalExpenseMinor: totalExpCurrent,
      );
      if (rate >= 40.0) {
        insights.add(FinancialInsight(
          title: 'Healthy Savings Rate',
          description: 'You are saving $rate% of your total earnings this month. Excellent financial discipline.',
          iconName: 'investment',
          isPositive: true,
        ));
      } else if (rate > 0) {
        insights.add(FinancialInsight(
          title: 'Positive Cash Flow',
          description: 'Your savings rate is $rate%. Consider optimizing recurring subscriptions to push past 30%.',
          iconName: 'investment',
          isPositive: true,
        ));
      } else {
        insights.add(FinancialInsight(
          title: 'Expenses Exceed Income',
          description: 'Total spending exceeds recorded income by ${CurrencyFormatter.format(totalExpCurrent - totalIncCurrent)}.',
          iconName: 'loan',
          isPositive: false,
        ));
      }
    }

    if (totalExpPrev > 0 && totalExpCurrent > 0) {
      final changePct = FinancialCalculator.calculatePeriodChangePercentage(
        currentMinor: totalExpCurrent,
        previousMinor: totalExpPrev,
      );
      if (changePct != null) {
        if (changePct < 0) {
          insights.add(FinancialInsight(
            title: 'Lower Spending',
            description: 'Your spending this month is ${changePct.abs()}% lower compared to last month.',
            iconName: 'trending_up',
            isPositive: true,
          ));
        } else if (changePct > 0) {
          insights.add(FinancialInsight(
            title: 'Spending Increased',
            description: 'Spending is $changePct% higher than last month. Check top categories for sudden outflows.',
            iconName: 'bills',
            isPositive: false,
          ));
        }
      }
    }

    if (currentExpenses.isNotEmpty) {
      final catTotals = <String, int>{};
      for (final tx in currentExpenses) {
        final catId = tx.categoryId ?? 'other';
        catTotals[catId] = (catTotals[catId] ?? 0) + tx.amountMinor;
      }
      var topCatId = '';
      var maxAmt = 0;
      catTotals.forEach((catId, amt) {
        if (amt > maxAmt) {
          maxAmt = amt;
          topCatId = catId;
        }
      });

      if (maxAmt > 0) {
        final catName = categories.firstWhere(
          (c) => c.id == topCatId,
          orElse: () => const Category(id: 'other', name: 'General', type: CategoryType.expense, iconName: 'category', colorHex: '#E5A93C'),
        ).name;
        final pct = FinancialCalculator.calculatePercentage(portionMinor: maxAmt, totalMinor: totalExpCurrent);

        insights.add(FinancialInsight(
          title: 'Top Category: $catName',
          description: '$catName represents $pct% (${CurrencyFormatter.format(maxAmt)}) of your total expenses this month.',
          iconName: 'shopping',
          isPositive: pct < 45.0,
        ));
      }
    }

    if (currentExpenses.isNotEmpty) {
      final daysRecorded = currentExpenses.map((t) => t.date.day).toSet().length;
      final effectiveDays = daysRecorded > 0 ? daysRecorded : 1;
      final avgDaily = totalExpCurrent ~/ effectiveDays;

      insights.add(FinancialInsight(
        title: 'Daily Average Outflow',
        description: 'Your average spending is ${CurrencyFormatter.format(avgDaily)} across active spending days.',
        iconName: 'cash',
        isPositive: true,
      ));
    }

    return insights;
  }
}
