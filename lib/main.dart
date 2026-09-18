import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/database/database_helper.dart';
import 'features/accounts/data/account_repository.dart';
import 'features/accounts/presentation/accounts_cubit.dart';
import 'features/accounts/presentation/accounts_screen.dart';
import 'features/categories/data/category_repository.dart';
import 'features/categories/presentation/categories_cubit.dart';
import 'features/transactions/data/transaction_repository.dart';
import 'features/transactions/presentation/transactions_cubit.dart';
import 'features/transactions/presentation/transactions_screen.dart';
import 'features/transactions/presentation/transaction_entry_sheet.dart';
import 'features/dashboard/presentation/dashboard_cubit.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/budgets/data/budget_repository.dart';
import 'features/budgets/presentation/budgets_cubit.dart';
import 'features/budgets/presentation/budgets_screen.dart';
import 'features/reports/presentation/reports_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbHelper = DatabaseHelper.instance;
  await dbHelper.database;

  final accountRepo = AccountRepository(dbHelper: dbHelper);
  final categoryRepo = CategoryRepository(dbHelper: dbHelper);
  final transactionRepo = TransactionRepository(dbHelper: dbHelper);
  final budgetRepo = BudgetRepository(dbHelper: dbHelper);

  runApp(
    GoldenLedgerApp(
      accountRepository: accountRepo,
      categoryRepository: categoryRepo,
      transactionRepository: transactionRepo,
      budgetRepository: budgetRepo,
    ),
  );
}

class GoldenLedgerApp extends StatelessWidget {
  final AccountRepository accountRepository;
  final CategoryRepository categoryRepository;
  final TransactionRepository transactionRepository;
  final BudgetRepository budgetRepository;

  const GoldenLedgerApp({
    super.key,
    required this.accountRepository,
    required this.categoryRepository,
    required this.transactionRepository,
    required this.budgetRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AccountsCubit(accountRepository: accountRepository)..loadAccounts(),
        ),
        BlocProvider(
          create: (_) => CategoriesCubit(categoryRepository: categoryRepository)..loadCategories(),
        ),
        BlocProvider(
          create: (_) => TransactionsCubit(transactionRepository: transactionRepository)..loadTransactions(),
        ),
        BlocProvider(
          create: (_) => DashboardCubit(
            transactionRepository: transactionRepository,
            accountRepository: accountRepository,
            categoryRepository: categoryRepository,
          )..loadDashboard(),
        ),
        BlocProvider(
          create: (_) => BudgetsCubit(
            budgetRepository: budgetRepository,
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
          )..loadBudgets(),
        ),
      ],
      child: MaterialApp(
        title: 'Golden Ledger',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AppShell(),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    TransactionsScreen(),
    ReportsScreen(),
    BudgetsScreen(),
    AccountsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 750;

        if (isWideScreen) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
                  backgroundColor: AppColors.surface,
                  selectedIconTheme: const IconThemeData(color: AppColors.gold),
                  unselectedIconTheme: const IconThemeData(color: AppColors.textMuted),
                  selectedLabelTextStyle: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600, fontSize: 13),
                  unselectedLabelTextStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.black, size: 24),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Golden\nLedger',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: FloatingActionButton(
                          mini: true,
                          onPressed: () => TransactionEntrySheet.show(context),
                          child: const Icon(Icons.add_rounded, size: 24),
                        ),
                      ),
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      selectedIcon: Icon(Icons.receipt_long_rounded),
                      label: Text('Transactions'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.bar_chart_outlined),
                      selectedIcon: Icon(Icons.bar_chart_rounded),
                      label: Text('Reports'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.savings_outlined),
                      selectedIcon: Icon(Icons.savings_rounded),
                      label: Text('Budgets'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.account_balance_outlined),
                      selectedIcon: Icon(Icons.account_balance_rounded),
                      label: Text('Accounts'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, color: AppColors.border),
                Expanded(child: _screens[_currentIndex]),
              ],
            ),
          );
        }

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (idx) {
              if (idx == 2) {
                TransactionEntrySheet.show(context);
              } else {
                setState(() => _currentIndex = idx > 2 ? idx - 1 : idx);
              }
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard_rounded),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long_rounded),
                label: 'Transactions',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.black, size: 24),
                ),
                label: '',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart_rounded),
                label: 'Reports',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                activeIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Accounts',
              ),
            ],
          ),
        );
      },
    );
  }
}
