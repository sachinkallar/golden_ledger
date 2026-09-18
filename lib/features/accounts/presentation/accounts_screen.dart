import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/ledger_card.dart';
import '../../../core/widgets/category_icon.dart';
import '../domain/account_model.dart';
import 'accounts_cubit.dart';
import '../../dashboard/presentation/dashboard_cubit.dart';
import '../../transactions/presentation/transactions_cubit.dart';
import '../../budgets/presentation/budgets_cubit.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  void _showAddAccountDialog(BuildContext context) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    AccountType selectedType = AccountType.bank;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Add Financial Account', style: TextStyle(fontWeight: FontWeight.w700)),
        content: StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Account Name', hintText: 'e.g. SBI Savings'),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<AccountType>(
                  initialValue: selectedType,
                  dropdownColor: AppColors.card,
                  decoration: const InputDecoration(labelText: 'Account Type'),
                  items: AccountType.values.map((t) {
                    return DropdownMenuItem(value: t, child: Text(t.displayName));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: balanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Opening Balance (₹)', hintText: '0'),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final openingMinor = CurrencyFormatter.parseMajorToMinor(balanceController.text);
                final acc = Account(
                  id: const Uuid().v4(),
                  name: nameController.text.trim(),
                  type: selectedType,
                  openingBalanceMinor: openingMinor,
                  currency: 'INR',
                  iconName: selectedType == AccountType.cash ? 'cash' : (selectedType == AccountType.creditCard ? 'credit_card' : 'bank'),
                  createdAt: DateTime.now(),
                );
                context.read<AccountsCubit>().addAccount(acc);
                Navigator.pop(dialogCtx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            child: const Text('Create Account', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AccountsCubit>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts & Net Worth', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            tooltip: 'Reset to Clean Slate',
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('Reset All Data?', style: TextStyle(fontWeight: FontWeight.w700)),
                  content: const Text(
                    'This will clear all transactions, budgets, and reset all accounts to ₹0 so you can start fresh.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
                      onPressed: () async {
                        Navigator.pop(dialogCtx);
                        await DatabaseHelper.instance.clearAllData();
                        if (!context.mounted) return;
                        context.read<AccountsCubit>().loadAccounts();
                        context.read<DashboardCubit>().loadDashboard();
                        context.read<TransactionsCubit>().loadTransactions();
                        context.read<BudgetsCubit>().loadBudgets();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: AppColors.income, size: 20),
                                SizedBox(width: 10),
                                Text('Ledger reset to clean state', style: TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        );
                      },
                      child: const Text('Reset All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.gold, size: 28),
            onPressed: () => _showAddAccountDialog(context),
          ),
        ],
      ),
      body: Builder(
        builder: (ctx) {
          if (state is AccountsLoaded) {
            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                LedgerCard(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Assets', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(state.totalAssetsMinor),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.income),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 40, color: AppColors.border),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Liabilities', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(state.totalLiabilitiesMinor),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.expense),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                ...state.accounts.map((acc) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: LedgerCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CategoryIcon(iconName: acc.iconName, size: 38),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  acc.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  acc.type.displayName,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(acc.currentBalanceMinor),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: acc.isLiability && acc.currentBalanceMinor > 0 ? AppColors.expense : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator(color: AppColors.gold));
        },
      ),
    );
  }
}
