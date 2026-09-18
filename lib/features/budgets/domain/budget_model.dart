import 'package:equatable/equatable.dart';

enum BudgetStatus {
  normal, // < 70%
  warning, // 70% - 99%
  exceeded, // >= 100%
}

class Budget extends Equatable {
  final String id;
  final String categoryId;
  final int amountMinor;
  final int month;
  final int year;

  const Budget({
    required this.id,
    required this.categoryId,
    required this.amountMinor,
    required this.month,
    required this.year,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'amount_minor': amountMinor,
      'month': month,
      'year': year,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      amountMinor: map['amount_minor'] as int,
      month: map['month'] as int,
      year: map['year'] as int,
    );
  }

  @override
  List<Object?> get props => [id, categoryId, amountMinor, month, year];
}
