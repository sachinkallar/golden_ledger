import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../core/widgets/ledger_card.dart';
import '../../../core/widgets/category_icon.dart';
import '../../dashboard/presentation/dashboard_cubit.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardCubit>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reports', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Builder(
        builder: (ctx) {
          if (state is DashboardLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Month navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateHelpers.formatMonthYear(state.selectedMonth),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded),
                            onPressed: () => context.read<DashboardCubit>().prevMonth(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded),
                            onPressed: () => context.read<DashboardCubit>().nextMonth(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Cash Flow Summary
                  LedgerCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cash Flow Summary',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryRow('Total Inflow (Income)', CurrencyFormatter.format(state.totalIncomeMinor), AppColors.income),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Total Outflow (Expenses)', CurrencyFormatter.format(state.totalExpenseMinor), AppColors.expense),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Transfers (Neutral)', CurrencyFormatter.format(state.totalTransferMinor), AppColors.transfer),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: AppColors.border),
                        ),
                        _buildSummaryRow(
                          'Net Cash Flow (Savings)',
                          CurrencyFormatter.format(state.savingsMinor),
                          state.savingsMinor >= 0 ? AppColors.gold : AppColors.expense,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Financial Insights Engine observations
                  const Text(
                    'Financial Insights & Observations',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  ...state.insights.map((insight) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: LedgerCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CategoryIcon(
                              iconName: insight.iconName,
                              color: insight.isPositive ? AppColors.gold : AppColors.expense,
                              size: 36,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    insight.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    insight.description,
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
                                  ),
                                ],
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
          return const Center(child: CircularProgressIndicator(color: AppColors.gold));
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
