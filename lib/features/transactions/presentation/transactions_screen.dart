import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../core/widgets/ledger_card.dart';
import '../../../core/widgets/category_icon.dart';
import '../../../core/widgets/empty_state.dart';
import '../domain/transaction_model.dart';
import '../data/transaction_repository.dart';
import 'transactions_cubit.dart';
import 'transaction_entry_sheet.dart';
import '../../accounts/presentation/accounts_cubit.dart';
import '../../categories/presentation/categories_cubit.dart';
import '../../dashboard/presentation/dashboard_cubit.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  TransactionType? _selectedTypeFilter;

  void _onSearchChanged(String val) {
    context.read<TransactionsCubit>().setFilter(
      TransactionFilter(
        searchQuery: val,
        type: _selectedTypeFilter,
      ),
    );
  }

  void _onTypeFilterChanged(TransactionType? type) {
    setState(() => _selectedTypeFilter = type);
    context.read<TransactionsCubit>().setFilter(
      TransactionFilter(
        searchQuery: _searchController.text,
        type: _selectedTypeFilter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionsCubit>().state;
    final categoriesState = context.watch<CategoriesCubit>().state;
    final accountsState = context.watch<AccountsCubit>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.gold, size: 28),
            onPressed: () => TransactionEntrySheet.show(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by title, note, or tag...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', _selectedTypeFilter == null, () => _onTypeFilterChanged(null)),
                      const SizedBox(width: 8),
                      _buildFilterChip('Expenses', _selectedTypeFilter == TransactionType.expense, () => _onTypeFilterChanged(TransactionType.expense)),
                      const SizedBox(width: 8),
                      _buildFilterChip('Income', _selectedTypeFilter == TransactionType.income, () => _onTypeFilterChanged(TransactionType.income)),
                      const SizedBox(width: 8),
                      _buildFilterChip('Transfers', _selectedTypeFilter == TransactionType.transfer, () => _onTypeFilterChanged(TransactionType.transfer)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: Builder(
              builder: (ctx) {
                if (state is TransactionsLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                }
                if (state is TransactionsLoaded) {
                  if (state.transactions.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.receipt_long_rounded,
                      title: 'No transactions found',
                      description: state.filter.isEmpty
                          ? 'Start recording your expenses or income today.'
                          : 'Try changing your search query or type filters.',
                      action: ElevatedButton.icon(
                        onPressed: () => TransactionEntrySheet.show(context),
                        icon: const Icon(Icons.add_rounded, color: Colors.black),
                        label: const Text('Add Transaction', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: state.transactions.length,
                    itemBuilder: (ctx, i) {
                      final tx = state.transactions[i];
                      
                      String catName = 'Transfer';
                      String iconName = 'transfer';

                      if (tx.type != TransactionType.transfer && categoriesState is CategoriesLoaded) {
                        final cat = categoriesState.findById(tx.categoryId);
                        if (cat != null) {
                          catName = cat.name;
                          iconName = cat.iconName;
                        } else {
                          catName = tx.type == TransactionType.income ? 'Income' : 'Expense';
                          iconName = tx.type == TransactionType.income ? 'salary' : 'food';
                        }
                      }

                      String accountName = 'Account';
                      if (accountsState is AccountsLoaded) {
                        final acc = accountsState.accounts.where((a) => a.id == tx.accountId);
                        if (acc.isNotEmpty) accountName = acc.first.name;
                      }

                      return Dismissible(
                        key: Key(tx.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.expense,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              title: const Text('Delete Transaction?'),
                              content: Text('Are you sure you want to delete "${tx.description}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogCtx, false),
                                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogCtx, true),
                                  child: const Text('Delete', style: TextStyle(color: AppColors.expense)),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) {
                          context.read<TransactionsCubit>().deleteTransaction(tx.id);
                          context.read<DashboardCubit>().loadDashboard();
                          context.read<AccountsCubit>().loadAccounts();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: LedgerCard(
                            padding: const EdgeInsets.all(14),
                            onTap: () => TransactionEntrySheet.show(context, existingTransaction: tx),
                            child: Row(
                              children: [
                                CategoryIcon(
                                  iconName: iconName,
                                  color: tx.type == TransactionType.income
                                      ? AppColors.income
                                      : (tx.type == TransactionType.transfer ? AppColors.transfer : AppColors.gold),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.description,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            catName,
                                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                          ),
                                          const Text(' • ', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                          Text(
                                            accountName,
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                          const Text(' • ', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                          Text(
                                            DateHelpers.formatDate(tx.date),
                                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${tx.type == TransactionType.income ? "+" : (tx.type == TransactionType.expense ? "-" : "")}${CurrencyFormatter.format(tx.amountMinor)}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: tx.type == TransactionType.income
                                        ? AppColors.income
                                        : (tx.type == TransactionType.transfer ? AppColors.transfer : AppColors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      selected: isSelected,
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.black : AppColors.textPrimary)),
      selectedColor: AppColors.gold,
      backgroundColor: AppColors.card,
      side: BorderSide(color: isSelected ? AppColors.gold : AppColors.border),
      onSelected: (_) => onTap(),
    );
  }
}
