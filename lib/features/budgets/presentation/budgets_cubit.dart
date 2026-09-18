import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../domain/budget_model.dart';
import '../data/budget_repository.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/domain/category_model.dart';

abstract class BudgetsState extends Equatable {
  const BudgetsState();
  @override
  List<Object?> get props => [];
}

class BudgetsInitial extends BudgetsState {}
class BudgetsLoading extends BudgetsState {}

class BudgetsLoaded extends BudgetsState {
  final List<Budget> budgets;
  final Map<String, int> categorySpent;
  final List<Category> categories;
  final int totalBudgetMinor;
  final int totalSpentMinor;
  final int month;
  final int year;

  const BudgetsLoaded({
    required this.budgets,
    required this.categorySpent,
    required this.categories,
    required this.totalBudgetMinor,
    required this.totalSpentMinor,
    required this.month,
    required this.year,
  });

  @override
  List<Object?> get props => [
        budgets,
        categorySpent,
        categories,
        totalBudgetMinor,
        totalSpentMinor,
        month,
        year,
      ];
}

class BudgetsError extends BudgetsState {
  final String message;
  const BudgetsError(this.message);
  @override
  List<Object?> get props => [message];
}

class BudgetsCubit extends Cubit<BudgetsState> {
  final BudgetRepository _budgetRepo;
  final TransactionRepository _txRepo;
  final CategoryRepository _catRepo;

  BudgetsCubit({
    required BudgetRepository budgetRepository,
    required TransactionRepository transactionRepository,
    required CategoryRepository categoryRepository,
  })  : _budgetRepo = budgetRepository,
        _txRepo = transactionRepository,
        _catRepo = categoryRepository,
        super(BudgetsInitial());

  Future<void> loadBudgets({int? year, int? month}) async {
    try {
      emit(BudgetsLoading());
      final now = DateTime.now();
      final targetYear = year ?? now.year;
      final targetMonth = month ?? now.month;

      final budgets = await _budgetRepo.getBudgetsForMonth(targetYear, targetMonth);
      final catSpent = await _txRepo.getCategoryExpenses(targetYear, targetMonth);
      final categories = await _catRepo.getAllCategories();

      int totalBudget = 0;
      int totalSpent = 0;

      for (final b in budgets) {
        totalBudget += b.amountMinor;
        totalSpent += (catSpent[b.categoryId] ?? 0);
      }

      emit(BudgetsLoaded(
        budgets: budgets,
        categorySpent: catSpent,
        categories: categories,
        totalBudgetMinor: totalBudget,
        totalSpentMinor: totalSpent,
        month: targetMonth,
        year: targetYear,
      ));
    } catch (e) {
      emit(BudgetsError('Failed to load budgets'));
    }
  }

  Future<void> saveBudget(Budget budget) async {
    try {
      await _budgetRepo.saveBudget(budget);
      await loadBudgets(year: budget.year, month: budget.month);
    } catch (e) {
      emit(BudgetsError('Failed to save budget'));
    }
  }

  Future<void> deleteBudget(String id, int year, int month) async {
    try {
      await _budgetRepo.deleteBudget(id);
      await loadBudgets(year: year, month: month);
    } catch (e) {
      emit(BudgetsError('Failed to delete budget'));
    }
  }
}
