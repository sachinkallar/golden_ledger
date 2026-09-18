import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/ledger_card.dart';
import '../../../core/widgets/category_icon.dart';
import '../../natural_entry/natural_language_parser.dart';
import '../domain/transaction_model.dart';
import 'transactions_cubit.dart';
import '../../dashboard/presentation/dashboard_cubit.dart';
import '../../accounts/presentation/accounts_cubit.dart';
import '../../budgets/presentation/budgets_cubit.dart';

class NaturalEntryDialog extends StatefulWidget {
  const NaturalEntryDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const NaturalEntryDialog(),
    );
  }

  @override
  State<NaturalEntryDialog> createState() => _NaturalEntryDialogState();
}

class _NaturalEntryDialogState extends State<NaturalEntryDialog> {
  final TextEditingController _controller = TextEditingController();
  ParsedTransaction? _parsed;

  final List<String> _samplePrompts = [
    'spent 150 on lunch',
    'coffee 60',
    'salary 35000',
    'paid 2000 rent',
    'uber 240',
    'groceries 850',
    'got 500 cashback',
  ];

  void _onChanged(String val) {
    setState(() {
      _parsed = NaturalLanguageParser.parse(val);
    });
  }

  Future<void> _confirmAndSave() async {
    if (_parsed == null) return;

    final accountsState = context.read<AccountsCubit>().state;
    String defaultAccId = 'acc_hdfc';
    if (accountsState is AccountsLoaded && accountsState.accounts.isNotEmpty) {
      defaultAccId = accountsState.accounts.first.id;
    }

    final now = DateTime.now();
    final tx = Transaction(
      id: const Uuid().v4(),
      type: _parsed!.type,
      amountMinor: _parsed!.amountMinor,
      categoryId: _parsed!.suggestedCategoryId,
      accountId: defaultAccId,
      date: _parsed!.date,
      description: _parsed!.description,
      notes: 'Natural language entry: "${_controller.text.trim()}"',
      tags: ['nlp_entry'],
      createdAt: now,
      updatedAt: now,
    );

    await context.read<TransactionsCubit>().addTransaction(tx);
    if (!mounted) return;
    context.read<DashboardCubit>().loadDashboard();
    context.read<AccountsCubit>().loadAccounts();
    context.read<BudgetsCubit>().loadBudgets();

    Navigator.pop(context);
    final formattedAmt = CurrencyFormatter.format(tx.amountMinor);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.cardElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.gold, width: 1.2),
        ),
        content: Row(
          children: [
            const Icon(Icons.bolt_rounded, color: AppColors.gold, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Recorded: ${tx.description} ($formattedAmt)',
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset, left: 20, right: 20, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.bolt_rounded, color: AppColors.gold, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Natural Language Entry',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Type freely like "spent 150 on lunch" or "salary 25000"',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g. spent 180 on dinner yesterday',
              prefixIcon: const Icon(Icons.mic_none_rounded, color: AppColors.gold),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                      onPressed: () {
                        _controller.clear();
                        _onChanged('');
                      },
                    )
                  : null,
            ),
            onChanged: _onChanged,
            onSubmitted: (_) => _confirmAndSave(),
          ),
          const SizedBox(height: 12),
          // Suggested prompt chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _samplePrompts.map((p) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(p, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                    backgroundColor: AppColors.cardElevated,
                    side: const BorderSide(color: AppColors.border),
                    onPressed: () {
                      _controller.text = p;
                      _onChanged(p);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Live Parse Preview
          if (_parsed != null) ...[
            LedgerCard(
              backgroundColor: AppColors.cardElevated,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CategoryIcon(
                    iconName: _parsed!.suggestedCategoryId?.replaceAll('cat_', '') ?? 'category',
                    color: _parsed!.type == TransactionType.income ? AppColors.income : AppColors.gold,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _parsed!.description,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _parsed!.type == TransactionType.income
                                    ? AppColors.incomeSurface
                                    : AppColors.expenseSurface,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _parsed!.type.displayName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _parsed!.type == TransactionType.income
                                      ? AppColors.income
                                      : AppColors.expense,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Confidence: ${(_parsed!.confidence * 100).toInt()}%',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(_parsed!.amountMinor),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _parsed!.type == TransactionType.income ? AppColors.income : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _confirmAndSave,
              icon: const Icon(Icons.check_circle_rounded, color: Colors.black),
              label: const Text('Confirm & Record', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
