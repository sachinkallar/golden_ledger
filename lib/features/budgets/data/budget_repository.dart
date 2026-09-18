import '../../../../core/database/database_helper.dart';
import '../domain/budget_model.dart';

class BudgetRepository {
  final DatabaseHelper _dbHelper;

  BudgetRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<Budget>> getBudgetsForMonth(int year, int month) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'budgets',
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
    );
    return maps.map((m) => Budget.fromMap(m)).toList();
  }

  Future<void> saveBudget(Budget budget) async {
    final db = await _dbHelper.database;
    await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: null, // we can replace or update
    );
  }

  Future<void> deleteBudget(String id) async {
    final db = await _dbHelper.database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }
}
