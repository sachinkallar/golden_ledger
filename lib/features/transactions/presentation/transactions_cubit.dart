import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../domain/transaction_model.dart';
import '../data/transaction_repository.dart';

abstract class TransactionsState extends Equatable {
  const TransactionsState();
  @override
  List<Object?> get props => [];
}

class TransactionsInitial extends TransactionsState {}
class TransactionsLoading extends TransactionsState {}

class TransactionsLoaded extends TransactionsState {
  final List<Transaction> transactions;
  final TransactionFilter filter;
  final int totalIncomeMinor;
  final int totalExpenseMinor;

  const TransactionsLoaded({
    required this.transactions,
    required this.filter,
    required this.totalIncomeMinor,
    required this.totalExpenseMinor,
  });

  @override
  List<Object?> get props => [transactions, filter, totalIncomeMinor, totalExpenseMinor];
}

class TransactionsError extends TransactionsState {
  final String message;
  const TransactionsError(this.message);
  @override
  List<Object?> get props => [message];
}

class TransactionsCubit extends Cubit<TransactionsState> {
  final TransactionRepository _repo;
  TransactionFilter _currentFilter = const TransactionFilter();

  TransactionsCubit({required TransactionRepository transactionRepository})
      : _repo = transactionRepository,
        super(TransactionsInitial());

  TransactionFilter get currentFilter => _currentFilter;

  Future<void> loadTransactions({TransactionFilter? filter}) async {
    try {
      emit(TransactionsLoading());
      if (filter != null) {
        _currentFilter = filter;
      }
      final list = await _repo.getTransactions(filter: _currentFilter);

      int income = 0;
      int expense = 0;
      for (final tx in list) {
        if (tx.type == TransactionType.income) income += tx.amountMinor;
        if (tx.type == TransactionType.expense) expense += tx.amountMinor;
      }

      emit(TransactionsLoaded(
        transactions: list,
        filter: _currentFilter,
        totalIncomeMinor: income,
        totalExpenseMinor: expense,
      ));
    } catch (e) {
      emit(TransactionsError('Unable to load transactions: ${e.toString()}'));
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      await _repo.addTransaction(transaction);
      await loadTransactions();
    } catch (e) {
      emit(TransactionsError('Failed to record transaction'));
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      await _repo.updateTransaction(transaction);
      await loadTransactions();
    } catch (e) {
      emit(TransactionsError('Failed to update transaction'));
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _repo.deleteTransaction(id);
      await loadTransactions();
    } catch (e) {
      emit(TransactionsError('Failed to delete transaction'));
    }
  }

  void setFilter(TransactionFilter filter) {
    _currentFilter = filter;
    loadTransactions(filter: filter);
  }

  void clearFilter() {
    _currentFilter = const TransactionFilter();
    loadTransactions(filter: _currentFilter);
  }
}
