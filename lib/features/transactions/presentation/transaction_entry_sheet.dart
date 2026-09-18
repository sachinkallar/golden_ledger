import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../core/widgets/ledger_card.dart';
import '../../../core/widgets/category_icon.dart';
import '../domain/transaction_model.dart';
import 'transactions_cubit.dart';
import '../../accounts/presentation/accounts_cubit.dart';
import '../../categories/presentation/categories_cubit.dart';
import '../../dashboard/presentation/dashboard_cubit.dart';
import '../../budgets/presentation/budgets_cubit.dart';

class TransactionEntrySheet extends StatefulWidget {
  final TransactionType initialType;
  final Transaction? existingTransaction;

  const TransactionEntrySheet({
    super.key,
    this.initialType = TransactionType.expense,
    this.existingTransaction,
  });

  static Future<void> show(
    BuildContext context, {
    TransactionType initialType = TransactionType.expense,
    Transaction? existingTransaction,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => TransactionEntrySheet(
        initialType: initialType,
        existingTransaction: existingTransaction,
      ),
    );
  }

  @override
  State<TransactionEntrySheet> createState() => _TransactionEntrySheetState();
}

class _TransactionEntrySheetState extends State<TransactionEntrySheet> {
  late TransactionType _type;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedAccountId;
  String? _selectedToAccountId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.existingTransaction != null) {
      final tx = widget.existingTransaction!;
      _type = tx.type;
      _amountController.text = (tx.amountMinor / 100.0).toStringAsFixed(2);
      _descController.text = tx.description;
      _notesController.text = tx.notes ?? '';
      _selectedCategoryId = tx.categoryId;
      _selectedAccountId = tx.accountId;
      _selectedToAccountId = tx.toAccountId;
      _selectedDate = tx.date;
    } else {
      _type = widget.initialType;
    }
  }

  void _addQuickAmount(int amountMajor) {
    final current = CurrencyFormatter.parseMajorToMinor(_amountController.text);
    final next = current + (amountMajor * 100);
    _amountController.text = (next / 100.0).toStringAsFixed(0);
  }

  Future<void> _save() async {
    final amountMinor = CurrencyFormatter.parseMajorToMinor(_amountController.text);
    if (amountMinor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: AppColors.expense),
      );
      return;
    }

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account'), backgroundColor: AppColors.expense),
      );
      return;
    }

    if (_type == TransactionType.transfer && _selectedToAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select destination account for transfer'), backgroundColor: AppColors.expense),
      );
      return;
    }

    final desc = _descController.text.trim().isEmpty
        ? (_type == TransactionType.transfer ? 'Transfer' : _type.displayName)
        : _descController.text.trim();

    final now = DateTime.now();
    final isEdit = widget.existingTransaction != null;

    final tx = Transaction(
      id: isEdit ? widget.existingTransaction!.id : const Uuid().v4(),
      type: _type,
      amountMinor: amountMinor,
      categoryId: _type == TransactionType.transfer ? null : _selectedCategoryId,
      accountId: _selectedAccountId!,
      toAccountId: _type == TransactionType.transfer ? _selectedToAccountId : null,
      date: _selectedDate,
      description: desc,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      tags: [],
      createdAt: isEdit ? widget.existingTransaction!.createdAt : now,
      updatedAt: now,
    );

    if (isEdit) {
      await context.read<TransactionsCubit>().updateTransaction(tx);
    } else {
      await context.read<TransactionsCubit>().addTransaction(tx);
    }

    if (!mounted) return;
    context.read<DashboardCubit>().loadDashboard();
    context.read<AccountsCubit>().loadAccounts();
    context.read<BudgetsCubit>().loadBudgets();

    Navigator.pop(context);
    final action = isEdit ? 'Updated' : 'Saved';
    final formatted = CurrencyFormatter.format(amountMinor);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.cardElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.income, width: 1.2),
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.income, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$action: $desc ($formatted)',
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
    final accountsState = context.watch<AccountsCubit>().state;
    final categoriesState = context.watch<CategoriesCubit>().state;

    final accounts = accountsState is AccountsLoaded ? accountsState.accounts : [];
    final categories = categoriesState is CategoriesLoaded
        ? (_type == TransactionType.income
            ? categoriesState.incomeCategories
            : categoriesState.expenseCategories)
        : [];

    if (_selectedAccountId == null && accounts.isNotEmpty) {
      _selectedAccountId = accounts.first.id;
    }
    if (_type == TransactionType.transfer && _selectedToAccountId == null && accounts.length > 1) {
      _selectedToAccountId = accounts[1].id;
    }
    if (_selectedCategoryId == null && categories.isNotEmpty && _type != TransactionType.transfer) {
      _selectedCategoryId = categories.first.id;
    }

    Color headerColor;
    switch (_type) {
      case TransactionType.expense:
        headerColor = AppColors.expense;
        break;
      case TransactionType.income:
        headerColor = AppColors.income;
        break;
      case TransactionType.transfer:
        headerColor = AppColors.transfer;
        break;
    }

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomInset + 20, left: 20, right: 20, top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.existingTransaction != null ? 'Edit Transaction' : 'Record Transaction',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _buildTypeButton(TransactionType.expense, 'Expense', AppColors.expense),
                _buildTypeButton(TransactionType.income, 'Income', AppColors.income),
                _buildTypeButton(TransactionType.transfer, 'Transfer', AppColors.transfer),
              ],
            ),
          ),
          const SizedBox(height: 20),

          LedgerCard(
            backgroundColor: AppColors.cardElevated,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₹',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: headerColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: IntrinsicWidth(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          autofocus: widget.existingTransaction == null,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: headerColor,
                            letterSpacing: -0.5,
                          ),
                          decoration: const InputDecoration(
                            hintText: '0',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            fillColor: Colors.transparent,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [100, 500, 1000, 2000].map((val) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ActionChip(
                        label: Text('+$val', style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.border),
                        padding: EdgeInsets.zero,
                        onPressed: () => _addQuickAmount(val),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_type != TransactionType.transfer) ...[
            const Text(
              'Category',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (ctx, idx) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final cat = categories[i];
                  final isSelected = _selectedCategoryId == cat.id;
                  return ChoiceChip(
                    selected: isSelected,
                    selectedColor: AppColors.gold.withValues(alpha: 0.25),
                    backgroundColor: AppColors.card,
                    side: BorderSide(color: isSelected ? AppColors.gold : AppColors.border),
                    avatar: CategoryIcon(iconName: cat.iconName, size: 22),
                    label: Text(
                      cat.name,
                      style: TextStyle(
                        color: isSelected ? AppColors.gold : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategoryId = cat.id);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (_type == TransactionType.transfer) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('From Account', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      _buildAccountDropdown(accounts, _selectedAccountId, (val) {
                        setState(() => _selectedAccountId = val);
                      }),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('To Account', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      _buildAccountDropdown(accounts, _selectedToAccountId, (val) {
                        setState(() => _selectedToAccountId = val);
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            const Text('Account', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            _buildAccountDropdown(accounts, _selectedAccountId, (val) {
              setState(() => _selectedAccountId = val);
            }),
          ],
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'e.g. Lunch with team',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.cardElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.gold),
                      const SizedBox(width: 8),
                      Text(
                        DateHelpers.isToday(_selectedDate)
                            ? 'Today'
                            : DateHelpers.isYesterday(_selectedDate)
                                ? 'Yesterday'
                                : DateHelpers.formatDate(_selectedDate),
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: headerColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              widget.existingTransaction != null ? 'Update Transaction' : 'Save Transaction',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(TransactionType type, String title, Color color) {
    final isSelected = _type == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _type = type),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.black : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountDropdown(List accounts, String? selectedId, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId,
          isExpanded: true,
          dropdownColor: AppColors.card,
          items: accounts.map<DropdownMenuItem<String>>((acc) {
            return DropdownMenuItem<String>(
              value: acc.id,
              child: Text(acc.name, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.gold,
              surface: AppColors.card,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }
}
