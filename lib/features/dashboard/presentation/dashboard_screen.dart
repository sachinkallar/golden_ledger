import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../core/widgets/ledger_card.dart';
import '../../../core/widgets/category_icon.dart';
import '../../../core/widgets/empty_state.dart';
import '../../categories/domain/category_model.dart';
import 'dashboard_cubit.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/presentation/transaction_entry_sheet.dart';
import '../../transactions/presentation/natural_entry_dialog.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardCubit>().state;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.gold,
          onRefresh: () => context.read<DashboardCubit>().loadDashboard(),
          child: Builder(
            builder: (ctx) {
              if (state is DashboardLoading) {
                return const Center(child: CircularProgressIndicator(color: AppColors.gold));
              }
              if (state is DashboardLoaded) {
                return _buildDashboardContent(context, state);
              }
              if (state is DashboardError) {
                return Center(
                  child: EmptyStateWidget(
                    icon: Icons.error_outline_rounded,
                    title: 'Something went wrong',
                    description: state.message,
                    action: ElevatedButton(
                      onPressed: () => context.read<DashboardCubit>().loadDashboard(),
                      child: const Text('Retry'),
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, DashboardLoaded state) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Golden Ledger',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateHelpers.formatMonthYear(state.selectedMonth),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary),
                    onPressed: () => context.read<DashboardCubit>().prevMonth(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary),
                    onPressed: () => context.read<DashboardCubit>().nextMonth(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          LedgerCard(
            gradient: AppColors.cardGradient,
            border: Border.all(color: AppColors.borderLight, width: 1.2),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Net Worth Position',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.goldSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Savings Rate: ${state.savingsRate}%',
                        style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  CurrencyFormatter.format(state.netWorthMinor),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.border),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _buildCockpitMetric(
                        label: 'Income',
                        amountMinor: state.totalIncomeMinor,
                        color: AppColors.income,
                        icon: Icons.arrow_downward_rounded,
                      ),
                    ),
                    Container(width: 1, height: 40, color: AppColors.border),
                    Expanded(
                      child: _buildCockpitMetric(
                        label: 'Expenses',
                        amountMinor: state.totalExpenseMinor,
                        color: AppColors.expense,
                        icon: Icons.arrow_upward_rounded,
                      ),
                    ),
                    Container(width: 1, height: 40, color: AppColors.border),
                    Expanded(
                      child: _buildCockpitMetric(
                        label: 'Net Savings',
                        amountMinor: state.savingsMinor,
                        color: state.savingsMinor >= 0 ? AppColors.goldLight : AppColors.expense,
                        icon: Icons.savings_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildQuickButton(
                  context,
                  label: '+ Expense',
                  color: AppColors.expense,
                  onTap: () => TransactionEntrySheet.show(context, initialType: TransactionType.expense),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickButton(
                  context,
                  label: '+ Income',
                  color: AppColors.income,
                  onTap: () => TransactionEntrySheet.show(context, initialType: TransactionType.income),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickButton(
                  context,
                  label: '⇄ Transfer',
                  color: AppColors.transfer,
                  onTap: () => TransactionEntrySheet.show(context, initialType: TransactionType.transfer),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.goldSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.gold, width: 1.2),
                  ),
                ),
                icon: const Icon(Icons.bolt_rounded, color: AppColors.gold),
                tooltip: 'Natural Language Entry',
                onPressed: () => NaturalEntryDialog.show(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Accounts',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 94,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.accounts.length,
              separatorBuilder: (ctx, idx) => const SizedBox(width: 12),
              itemBuilder: (ctx, i) {
                final acc = state.accounts[i];
                return SizedBox(
                  width: 170,
                  child: LedgerCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              acc.name,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                            CategoryIcon(iconName: acc.iconName, size: 22),
                          ],
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
              },
            ),
          ),
          const SizedBox(height: 26),

          if (state.categoryExpenses.isNotEmpty) ...[
            const Text(
              'Monthly Spending by Category',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 14),
            LedgerCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  ...state.categoryExpenses.entries.take(5).map((entry) {
                    final cat = state.categories.firstWhere(
                      (c) => c.id == entry.key,
                      orElse: () => const Category(id: 'other', name: 'General', type: CategoryType.expense, iconName: 'category', colorHex: '#E5A93C'),
                    );
                    final pct = state.totalExpenseMinor > 0
                        ? (entry.value / state.totalExpenseMinor)
                        : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CategoryIcon(iconName: cat.iconName, size: 28),
                                  const SizedBox(width: 10),
                                  Text(
                                    cat.name,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                              Text(
                                '${CurrencyFormatter.format(entry.value)}  (${(pct * 100).toStringAsFixed(1)}%)',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct.clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: AppColors.surface,
                              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 26),
          ],

          if (state.dailySpending.isNotEmpty) ...[
            const Text(
              'Daily Spending Trend',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 14),
            LedgerCard(
              padding: const EdgeInsets.all(18),
              child: SizedBox(
                height: 160,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: 5,
                          getTitlesWidget: (val, meta) => Text(
                            'Day ${val.toInt()}',
                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                          ),
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: state.dailySpending.entries
                            .map((e) => FlSpot(e.key.toDouble(), (e.value / 100.0)))
                            .toList()
                          ..sort((a, b) => a.x.compareTo(b.x)),
                        isCurved: true,
                        color: AppColors.gold,
                        barWidth: 2.5,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.gold.withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.recentTransactions.isEmpty)
            const EmptyStateWidget(
              icon: Icons.receipt_rounded,
              title: 'No transactions yet',
              description: 'Tap + Expense above to record your first transaction.',
            )
          else
            ...state.recentTransactions.map((tx) {
              final cat = state.categories.where((c) => c.id == tx.categoryId);
              final iconName = tx.type == TransactionType.transfer
                  ? 'transfer'
                  : (cat.isNotEmpty ? cat.first.iconName : 'category');

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              DateHelpers.formatDate(tx.date),
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${tx.type == TransactionType.income ? "+" : (tx.type == TransactionType.expense ? "-" : "")}${CurrencyFormatter.format(tx.amountMinor)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: tx.type == TransactionType.income ? AppColors.income : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCockpitMetric({
    required String label,
    required int amountMinor,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.format(amountMinor, compact: true),
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }

  Widget _buildQuickButton(BuildContext context, {required String label, required Color color, required VoidCallback onTap}) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5), width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}
