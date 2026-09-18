import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  static Database? _database;
  static const String _dbName = 'golden_ledger.db';
  static const int _dbVersion = 2;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docsDir.path, 'GoldenLedger', _dbName);
    
    final file = File(dbPath);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }

    return await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Remove dummy/sample data and reset opening balances to zero
          await db.delete('transactions');
          await db.delete('budgets');
          await db.update('accounts', {'opening_balance_minor': 0});
        }
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        opening_balance_minor INTEGER NOT NULL DEFAULT 0,
        currency TEXT NOT NULL DEFAULT 'INR',
        icon_name TEXT NOT NULL DEFAULT 'bank',
        color_hex TEXT NOT NULL DEFAULT '#E5A93C',
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        parent_id TEXT,
        icon_name TEXT NOT NULL,
        color_hex TEXT NOT NULL,
        is_system INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (parent_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        amount_minor INTEGER NOT NULL,
        category_id TEXT,
        account_id TEXT NOT NULL,
        to_account_id TEXT,
        date_epoch_ms INTEGER NOT NULL,
        description TEXT NOT NULL,
        notes TEXT,
        tags TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE,
        FOREIGN KEY (to_account_id) REFERENCES accounts (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_trans_date ON transactions(date_epoch_ms)');
    await db.execute('CREATE INDEX idx_trans_type ON transactions(type)');
    await db.execute('CREATE INDEX idx_trans_account ON transactions(account_id)');
    await db.execute('CREATE INDEX idx_trans_category ON transactions(category_id)');

    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        amount_minor INTEGER NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    await _seedDefaults(db);
  }

  Future<void> _seedDefaults(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    const uuid = Uuid();

    final accounts = [
      {'id': 'acc_hdfc', 'name': 'HDFC Bank', 'type': 'bank', 'opening_balance_minor': 0, 'currency': 'INR', 'icon_name': 'bank', 'color_hex': '#38BDF8', 'is_active': 1, 'created_at': now},
      {'id': 'acc_cash', 'name': 'Cash in Wallet', 'type': 'cash', 'opening_balance_minor': 0, 'currency': 'INR', 'icon_name': 'cash', 'color_hex': '#10B981', 'is_active': 1, 'created_at': now},
      {'id': 'acc_upi', 'name': 'UPI Wallet', 'type': 'upi', 'opening_balance_minor': 0, 'currency': 'INR', 'icon_name': 'upi', 'color_hex': '#A855F7', 'is_active': 1, 'created_at': now},
      {'id': 'acc_credit', 'name': 'Credit Card', 'type': 'creditCard', 'opening_balance_minor': 0, 'currency': 'INR', 'icon_name': 'credit_card', 'color_hex': '#F43F5E', 'is_active': 1, 'created_at': now},
    ];

    for (final acc in accounts) {
      await db.insert('accounts', acc);
    }

    final expenseCategories = [
      {'id': 'cat_food', 'name': 'Food & Dining', 'type': 'expense', 'icon_name': 'food', 'color_hex': '#F97316', 'is_system': 1, 'is_archived': 0},
      {'id': 'cat_groceries', 'name': 'Groceries', 'type': 'expense', 'parent_id': 'cat_food', 'icon_name': 'groceries', 'color_hex': '#F59E0B', 'is_system': 1, 'is_archived': 0},
      {'id': 'cat_coffee', 'name': 'Coffee & Snacks', 'type': 'expense', 'parent_id': 'cat_food', 'icon_name': 'coffee', 'color_hex': '#D97706', 'is_system': 1, 'is_archived': 0},
      {'id': 'cat_transport', 'name': 'Transport & Travel', 'type': 'expense', 'icon_name': 'transport', 'color_hex': '#38BDF8', 'is_system': 1, 'is_archived': 0},
      {'id': 'cat_fuel', 'name': 'Fuel / Petrol', 'type': 'expense', 'parent_id': 'cat_transport', 'icon_name': 'fuel', 'color_hex': '#0284C7', 'is_system': 1, 'is_archived': 0},
      {'id': 'cat_bills', 'name': 'Bills & Utilities', 'type': 'expense', 'icon_name': 'bills', 'color_hex': '#EC4899', 'is_system': 1, 'is_archived': 0},
      {'id': 'cat_rent', 'name': 'Rent / Housing', 'type': 'expense', 'parent_id': 'cat_bills', 'icon_name': 'bills', 'color_hex': '#DB2777', 'is_system': 1, 'is_archived': 0},
      {'id': 'cat_subs', 'name': 'Subscriptions', 'type': 'expense', 'parent_id': 'cat_bills', 'icon_name': 'subscriptions', 'color_hex': '#8B5CF6', 'is_system': 1, 'is_archived': 0},
      {'id': 'cat_shopping', 'name': 'Shopping', 'type': 'expense', 'icon_name': 'shopping', 'color_hex': '#E5A93C', 'is_system': 1, 'is_archived': 0},
      {'id': 'cat_entertainment', 'name': 'Entertainment', 'type': 'expense', 'icon_name': 'entertainment', 'color_hex': '#6366F1', 'is_system': 1, 'is_archived': 0},
      {'id': 'cat_health', 'name': 'Health & Medical', 'type': 'expense', 'icon_name': 'health', 'color_hex': '#10B981', 'is_system': 1, 'is_archived': 0},
      {'id': 'cat_other_exp', 'name': 'Other Expense', 'type': 'expense', 'icon_name': 'category', 'color_hex': '#9CA3AF', 'is_system': 1, 'is_archived': 0},
    ];

    for (final cat in expenseCategories) {
      await db.insert('categories', cat);
    }

    final incomeCategories = [
      {'id': 'cat_salary', 'name': 'Salary', 'type': 'income', 'icon_name': 'salary', 'color_hex': '#10B981', 'is_system': 1, 'is_archived': 0},
      {'id': 'cat_freelance', 'name': 'Freelance / Consulting', 'type': 'income', 'icon_name': 'freelance', 'color_hex': '#34D399', 'is_system': 1, 'is_archived': 0},
      {'id': 'cat_business', 'name': 'Business Revenue', 'type': 'income', 'icon_name': 'business', 'color_hex': '#059669', 'is_system': 1, 'is_archived': 0},
      {'id': 'cat_investment', 'name': 'Interest & Dividend', 'type': 'income', 'icon_name': 'investment', 'color_hex': '#0284C7', 'is_system': 1, 'is_archived': 0},
      {'id': 'cat_cashback', 'name': 'Cashback & Rewards', 'type': 'income', 'icon_name': 'cashback', 'color_hex': '#FBBF24', 'is_system': 1, 'is_archived': 0},
      {'id': 'cat_other_inc', 'name': 'Other Income', 'type': 'income', 'icon_name': 'gift', 'color_hex': '#9CA3AF', 'is_system': 1, 'is_archived': 0},
    ];

    for (final cat in incomeCategories) {
      await db.insert('categories', cat);
    }
  }

  /// Clears all transactions, budgets, and resets account opening balances to zero
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('budgets');
    await db.update('accounts', {'opening_balance_minor': 0});
  }
}
