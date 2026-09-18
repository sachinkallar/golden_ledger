import '../../../../core/database/database_helper.dart';
import '../domain/category_model.dart';

class CategoryRepository {
  final DatabaseHelper _dbHelper;

  CategoryRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<Category>> getAllCategories() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'is_archived = ?',
      whereArgs: [0],
      orderBy: 'name ASC',
    );
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  Future<List<Category>> getCategoriesByType(CategoryType type) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'type = ? AND is_archived = ?',
      whereArgs: [type.name, 0],
      orderBy: 'name ASC',
    );
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  Future<void> createCategory(Category category) async {
    final db = await _dbHelper.database;
    await db.insert('categories', category.toMap());
  }

  Future<void> updateCategory(Category category) async {
    final db = await _dbHelper.database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> archiveCategory(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'categories',
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
