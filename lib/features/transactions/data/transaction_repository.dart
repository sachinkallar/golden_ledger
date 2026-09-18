import '../../../../core/database/database_helper.dart';
import '../domain/transaction_model.dart';

class TransactionFilter {
  final String? searchQuery;
  final TransactionType? type;
  final String? categoryId;
  final String? accountId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? minAmountMinor;
  final int? maxAmountMinor;

  const TransactionFilter({
    this.searchQuery,
    this.type,
    this.categoryId,
    this.accountId,
    this.startDate,
    this.endDate,
    this.minAmountMinor,
    this.maxAmountMinor,
  });

  bool get isEmpty =>
      (searchQuery == null || searchQuery!.trim().isEmpty) &&
      type == null &&
      categoryId == null &&
      accountId == null &&
      startDate == null &&
      endDate == null &&
      minAmountMinor == null &&
      maxAmountMinor == null;
}

class TransactionRepository {
  final DatabaseHelper _dbHelper;

  TransactionRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<Transaction>> getTransactions({
    TransactionFilter? filter,
    int? limit,
  }) async {
    final db = await _dbHelper.database;
    
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (filter != null) {
      if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
        whereClauses.add('(description LIKE ? OR notes LIKE ? OR tags LIKE ?)');
        final q = '%${filter.searchQuery!.trim()}%';
        whereArgs.addAll([q, q, q]);
      }
      if (filter.type != null) {
        whereClauses.add('type = ?');
        whereArgs.add(filter.type!.name);
      }
      if (filter.categoryId != null) {
        whereClauses.add('category_id = ?');
        whereArgs.add(filter.categoryId);
      }
      if (filter.accountId != null) {
        whereClauses.add('(account_id = ? OR to_account_id = ?)');
        whereArgs.addAll([filter.accountId, filter.accountId]);
      }
      if (filter.startDate != null) {
        whereClauses.add('date_epoch_ms >= ?');
        whereArgs.add(filter.startDate!.millisecondsSinceEpoch);
      }
      if (filter.endDate != null) {
        whereClauses.add('date_epoch_ms <= ?');
        whereArgs.add(filter.endDate!.millisecondsSinceEpoch);
      }
      if (filter.minAmountMinor != null) {
        whereClauses.add('amount_minor >= ?');
        whereArgs.add(filter.minAmountMinor);
      }
      if (filter.maxAmountMinor != null) {
        whereClauses.add('amount_minor <= ?');
        whereArgs.add(filter.maxAmountMinor);
      }
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date_epoch_ms DESC, created_at DESC',
      limit: limit,
    );

    return maps.map((m) => Transaction.fromMap(m)).toList();
  }

  Future<void> addTransaction(Transaction transaction) async {
    final db = await _dbHelper.database;
    await db.insert('transactions', transaction.toMap());
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final db = await _dbHelper.database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await _dbHelper.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  /// Calculates monthly financial summary via database aggregations
  Future<Map<String, int>> getMonthlySummary(int year, int month) async {
    final db = await _dbHelper.database;
    final start = DateTime(year, month, 1).millisecondsSinceEpoch;
    final end = DateTime(year, month + 1, 1).millisecondsSinceEpoch - 1;

    // Total Income (transfers are strictly excluded)
    final incRes = await db.rawQuery('''
      SELECT COALESCE(SUM(amount_minor), 0) as total
      FROM transactions
      WHERE type = 'income' AND date_epoch_ms >= ? AND date_epoch_ms <= ?
    ''', [start, end]);
    final totalIncome = (incRes.first['total'] as num?)?.toInt() ?? 0;

    // Total Expenses (transfers are strictly excluded)
    final expRes = await db.rawQuery('''
      SELECT COALESCE(SUM(amount_minor), 0) as total
      FROM transactions
      WHERE type = 'expense' AND date_epoch_ms >= ? AND date_epoch_ms <= ?
    ''', [start, end]);
    final totalExpense = (expRes.first['total'] as num?)?.toInt() ?? 0;

    // Total Transfers
    final trfRes = await db.rawQuery('''
      SELECT COALESCE(SUM(amount_minor), 0) as total
      FROM transactions
      WHERE type = 'transfer' AND date_epoch_ms >= ? AND date_epoch_ms <= ?
    ''', [start, end]);
    final totalTransfer = (trfRes.first['total'] as num?)?.toInt() ?? 0;

    return {
      'income': totalIncome,
      'expense': totalExpense,
      'transfer': totalTransfer,
    };
  }

  /// Aggregates expenses grouped by category
  Future<Map<String, int>> getCategoryExpenses(int year, int month) async {
    final db = await _dbHelper.database;
    final start = DateTime(year, month, 1).millisecondsSinceEpoch;
    final end = DateTime(year, month + 1, 1).millisecondsSinceEpoch - 1;

    final results = await db.rawQuery('''
      SELECT category_id, COALESCE(SUM(amount_minor), 0) as total
      FROM transactions
      WHERE type = 'expense' AND date_epoch_ms >= ? AND date_epoch_ms <= ?
      GROUP BY category_id
      ORDER BY total DESC
    ''', [start, end]);

    final Map<String, int> map = {};
    for (final row in results) {
      final catId = (row['category_id'] as String?) ?? 'other';
      final total = (row['total'] as num?)?.toInt() ?? 0;
      map[catId] = total;
    }
    return map;
  }
}
