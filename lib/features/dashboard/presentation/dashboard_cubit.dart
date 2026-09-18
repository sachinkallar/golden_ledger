import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../accounts/domain/account_model.dart';
import '../../accounts/data/account_repository.dart';
import '../../categories/domain/category_model.dart';
import '../../categories/data/category_repository.dart';
import '../../insights/financial_insights_service.dart';
import '../../../core/utils/financial_calculator.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}
class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DateTime selectedMonth;
  final int totalIncomeMinor;
  final int totalExpenseMinor;
  final int totalTransferMinor;
  final int savingsMinor;
  final double savingsRate;
  final int netWorthMinor;
  final Map<String, int> categoryExpenses;
  final Map<int, int> dailySpending; // Day of month -> amountMinor
  final List<Transaction> recentTransactions;
  final List<Account> accounts;
  final List<Category> categories;
  final List<FinancialInsight> insights;

  const DashboardLoaded({
    required this.selectedMonth,
    required this.totalIncomeMinor,
    required this.totalExpenseMinor,
    required this.totalTransferMinor,
    required this.savingsMinor,
    required this.savingsRate,
    required this.netWorthMinor,
    required this.categoryExpenses,
    required this.dailySpending,
    required this.recentTransactions,
    required this.accounts,
    required this.categories,
    required this.insights,
  });

  @override
  List<Object?> get props => [
        selectedMonth,
        totalIncomeMinor,
        totalExpenseMinor,
        totalTransferMinor,
        savingsMinor,
        savingsRate,
        netWorthMinor,
        categoryExpenses,
        dailySpending,
        recentTransactions,
        accounts,
        categories,
        insights,
      ];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}

class DashboardCubit extends Cubit<DashboardState> {
  final TransactionRepository _txRepo;
  final AccountRepository _accountRepo;
  final CategoryRepository _categoryRepo;

  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  DashboardCubit({
    required TransactionRepository transactionRepository,
    required AccountRepository accountRepository,
    required CategoryRepository categoryRepository,
  })  : _txRepo = transactionRepository,
        _accountRepo = accountRepository,
        _categoryRepo = categoryRepository,
        super(DashboardInitial());

  DateTime get currentMonth => _currentMonth;

  Future<void> loadDashboard({DateTime? month}) async {
    try {
      emit(DashboardLoading());
      if (month != null) {
        _currentMonth = DateTime(month.year, month.month, 1);
      }

      final year = _currentMonth.year;
      final m = _currentMonth.month;

      // 1. Monthly Summary via DB Aggregations
      final summary = await _txRepo.getMonthlySummary(year, m);
      final income = summary['income'] ?? 0;
      final expense = summary['expense'] ?? 0;
      final transfer = summary['transfer'] ?? 0;

      final savings = FinancialCalculator.calculateSavings(
        totalIncomeMinor: income,
        totalExpenseMinor: expense,
      );
      final savingsRate = FinancialCalculator.calculateSavingsRate(
        totalIncomeMinor: income,
        totalExpenseMinor: expense,
      );

      // 2. Category Breakdown
      final catExpenses = await _txRepo.getCategoryExpenses(year, m);

      // 3. Current Month Transactions for daily spending & insights
      final start = DateTime(year, m, 1);
      final end = DateTime(year, m + 1, 1).subtract(const Duration(milliseconds: 1));
      final monthTx = await _txRepo.getTransactions(
        filter: TransactionFilter(startDate: start, endDate: end),
      );

      // Daily spending map
      final dailyMap = <int, int>{};
      for (final tx in monthTx) {
        if (tx.type == TransactionType.expense) {
          final day = tx.date.day;
          dailyMap[day] = (dailyMap[day] ?? 0) + tx.amountMinor;
        }
      }

      // 4. Previous Month Tx for MoM insights
      final prevStart = DateTime(year, m - 1, 1);
      final prevEnd = DateTime(year, m, 1).subtract(const Duration(milliseconds: 1));
      final prevMonthTx = await _txRepo.getTransactions(
        filter: TransactionFilter(startDate: prevStart, endDate: prevEnd),
      );

      // 5. Accounts & Categories
      final accounts = await _accountRepo.getAllAccounts();
      final categories = await _categoryRepo.getAllCategories();

      // Net Worth Calculation
      int assets = 0;
      int liabilities = 0;
      for (final acc in accounts) {
        if (acc.isLiability) {
          liabilities += acc.currentBalanceMinor.abs();
        } else {
          assets += acc.currentBalanceMinor;
        }
      }
      final netWorth = FinancialCalculator.calculateNetWorth(
        totalAssetsMinor: assets,
        totalLiabilitiesMinor: liabilities,
      );

      // 6. Recent Transactions (top 6)
      final recentTx = await _txRepo.getTransactions(limit: 6);

      // 7. Insights
      final insights = FinancialInsightsService.generateInsights(
        currentMonthTx: monthTx,
        previousMonthTx: prevMonthTx,
        categories: categories,
      );

      emit(DashboardLoaded(
        selectedMonth: _currentMonth,
        totalIncomeMinor: income,
        totalExpenseMinor: expense,
        totalTransferMinor: transfer,
        savingsMinor: savings,
        savingsRate: savingsRate,
        netWorthMinor: netWorth,
        categoryExpenses: catExpenses,
        dailySpending: dailyMap,
        recentTransactions: recentTx,
        accounts: accounts,
        categories: categories,
        insights: insights,
      ));
    } catch (e) {
      emit(DashboardError('Unable to load financial cockpit: ${e.toString()}'));
    }
  }

  void nextMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    loadDashboard(month: _currentMonth);
  }

  void prevMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    loadDashboard(month: _currentMonth);
  }

  void setMonth(DateTime month) {
    _currentMonth = DateTime(month.year, month.month, 1);
    loadDashboard(month: _currentMonth);
  }
}
