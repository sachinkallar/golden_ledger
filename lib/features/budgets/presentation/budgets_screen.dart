import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/ledger_card.dart';
import '../../../core/widgets/category_icon.dart';
import '../../../core/widgets/empty_state.dart';
import '../../categories/domain/category_model.dart';
import '../domain/budget_model.dart';
import 'budgets_cubit.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  void _showAddBudgetDialog(BuildContext context, BudgetsLoaded state) {
    String selectedCatId = state.categories.isNotEmpty ? state.categories.first.id : 'cat_food';
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Set Monthly Budget', style: TextStyle(fontWeight: FontWeight.w700)),
        content: StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedCatId,
                  dropdownColor: AppColors.card,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: state.categories.map((c) {
                    return DropdownMenuItem(value: c.id, child: Text(c.name));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedCatId = val);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monthly Limit (₹)',
                    hintText: 'e.g. 5000',
                  ),
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
              final limitMinor = CurrencyFormatter.parseMajorToMinor(amountController.text);
              if (limitMinor > 0) {
                final budget = Budget(
                  id: const Uuid().v4(),
                  categoryId: selectedCatId,
                  amountMinor: limitMinor,
                  month: state.month,
                  year: state.year,
                );
                context.read<BudgetsCubit>().saveBudget(budget);
                Navigator.pop(dialogCtx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            child: const Text('Save Budget', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BudgetsCubit>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Budgets', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          if (state is BudgetsLoaded)
            IconButton(
              icon: const Icon(Icons.add_rounded, color: AppColors.gold, size: 28),
              onPressed: () => _showAddBudgetDialog(context, state),
            ),
        ],
      ),
      body: Builder(
        builder: (ctx) {
          if (state is BudgetsLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.gold));
          }
          if (state is BudgetsLoaded) {
            if (state.budgets.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.savings_rounded,
                title: 'No budgets created',
                description: 'Set monthly limits on your categories to keep spending under control.',
                action: ElevatedButton.icon(
                  onPressed: () => _showAddBudgetDialog(context, state),
                  icon: const Icon(Icons.add_rounded, color: Colors.black),
                  label: const Text('Create Budget', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                LedgerCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Budget Allocation', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            CurrencyFormatter.format(state.totalSpentMinor),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          Text(
                            'Limit: ${CurrencyFormatter.format(state.totalBudgetMinor)}',
                            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: state.totalBudgetMinor > 0 ? (state.totalSpentMinor / state.totalBudgetMinor).clamp(0.0, 1.0) : 0.0,
                          minHeight: 8,
                          backgroundColor: AppColors.surface,
                          valueColor: AlwaysStoppedAnimation(
                            state.totalSpentMinor > state.totalBudgetMinor ? AppColors.expense : AppColors.gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                ...state.budgets.map((b) {
                  final cat = state.categories.firstWhere(
                    (c) => c.id == b.categoryId,
                    orElse: () => const Category(id: 'other', name: 'General', type: CategoryType.expense, iconName: 'category', colorHex: '#E5A93C'),
                  );
                  final spent = state.categorySpent[b.categoryId] ?? 0;
                  final pct = b.amountMinor > 0 ? (spent / b.amountMinor) : 0.0;
                  final isExceeded = spent >= b.amountMinor;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: LedgerCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CategoryIcon(iconName: cat.iconName, size: 34),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cat.name,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${(pct * 100).toInt()}% used',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isExceeded ? AppColors.expense : AppColors.gold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.format(spent),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isExceeded ? AppColors.expense : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '/ ${CurrencyFormatter.format(b.amountMinor)}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct.clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: AppColors.surface,
                              valueColor: AlwaysStoppedAnimation(isExceeded ? AppColors.expense : AppColors.gold),
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
          return const SizedBox();
        },
      ),
    );
  }
}
