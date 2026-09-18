import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../domain/category_model.dart';
import '../data/category_repository.dart';

abstract class CategoriesState extends Equatable {
  const CategoriesState();
  @override
  List<Object?> get props => [];
}

class CategoriesInitial extends CategoriesState {}
class CategoriesLoading extends CategoriesState {}

class CategoriesLoaded extends CategoriesState {
  final List<Category> categories;

  const CategoriesLoaded(this.categories);

  List<Category> get expenseCategories =>
      categories.where((c) => c.type == CategoryType.expense).toList();

  List<Category> get incomeCategories =>
      categories.where((c) => c.type == CategoryType.income).toList();

  Category? findById(String? id) {
    if (id == null) return null;
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [categories];
}

class CategoriesError extends CategoriesState {
  final String message;
  const CategoriesError(this.message);
  @override
  List<Object?> get props => [message];
}

class CategoriesCubit extends Cubit<CategoriesState> {
  final CategoryRepository _categoryRepo;

  CategoriesCubit({required CategoryRepository categoryRepository})
      : _categoryRepo = categoryRepository,
        super(CategoriesInitial());

  Future<void> loadCategories() async {
    try {
      emit(CategoriesLoading());
      final cats = await _categoryRepo.getAllCategories();
      emit(CategoriesLoaded(cats));
    } catch (e) {
      emit(CategoriesError('Unable to load categories'));
    }
  }

  Future<void> addCategory(Category category) async {
    try {
      await _categoryRepo.createCategory(category);
      await loadCategories();
    } catch (e) {
      emit(CategoriesError('Failed to create category'));
    }
  }
}
