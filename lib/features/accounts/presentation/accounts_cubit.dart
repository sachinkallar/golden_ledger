import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../domain/account_model.dart';
import '../data/account_repository.dart';

abstract class AccountsState extends Equatable {
  const AccountsState();
  @override
  List<Object?> get props => [];
}

class AccountsInitial extends AccountsState {}
class AccountsLoading extends AccountsState {}

class AccountsLoaded extends AccountsState {
  final List<Account> accounts;
  final int totalAssetsMinor;
  final int totalLiabilitiesMinor;
  final int netAvailableMinor;

  const AccountsLoaded({
    required this.accounts,
    required this.totalAssetsMinor,
    required this.totalLiabilitiesMinor,
    required this.netAvailableMinor,
  });

  @override
  List<Object?> get props => [accounts, totalAssetsMinor, totalLiabilitiesMinor, netAvailableMinor];
}

class AccountsError extends AccountsState {
  final String message;
  const AccountsError(this.message);
  @override
  List<Object?> get props => [message];
}

class AccountsCubit extends Cubit<AccountsState> {
  final AccountRepository _accountRepo;

  AccountsCubit({required AccountRepository accountRepository})
      : _accountRepo = accountRepository,
        super(AccountsInitial());

  Future<void> loadAccounts() async {
    try {
      emit(AccountsLoading());
      final accounts = await _accountRepo.getAllAccounts();

      int assets = 0;
      int liabilities = 0;

      for (final acc in accounts) {
        if (acc.isLiability) {
          liabilities += acc.currentBalanceMinor.abs();
        } else {
          assets += acc.currentBalanceMinor;
        }
      }

      emit(AccountsLoaded(
        accounts: accounts,
        totalAssetsMinor: assets,
        totalLiabilitiesMinor: liabilities,
        netAvailableMinor: assets - liabilities,
      ));
    } catch (e) {
      emit(AccountsError('Unable to load accounts: ${e.toString()}'));
    }
  }

  Future<void> addAccount(Account account) async {
    try {
      await _accountRepo.createAccount(account);
      await loadAccounts();
    } catch (e) {
      emit(AccountsError('Failed to create account'));
    }
  }

  Future<void> updateAccount(Account account) async {
    try {
      await _accountRepo.updateAccount(account);
      await loadAccounts();
    } catch (e) {
      emit(AccountsError('Failed to update account'));
    }
  }

  Future<void> deleteAccount(String id) async {
    try {
      await _accountRepo.deleteAccount(id);
      await loadAccounts();
    } catch (e) {
      emit(AccountsError('Failed to delete account'));
    }
  }
}
