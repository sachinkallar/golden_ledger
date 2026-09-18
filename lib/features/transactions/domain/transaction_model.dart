import 'package:equatable/equatable.dart';

enum TransactionType {
  expense,
  income,
  transfer;

  String get displayName {
    switch (this) {
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.income:
        return 'Income';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }
}

class Transaction extends Equatable {
  final String id;
  final TransactionType type;
  final int amountMinor;
  final String? categoryId;
  final String accountId;
  final String? toAccountId; // For transfers
  final DateTime date;
  final String description;
  final String? notes;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Transaction({
    required this.id,
    required this.type,
    required this.amountMinor,
    this.categoryId,
    required this.accountId,
    this.toAccountId,
    required this.date,
    required this.description,
    this.notes,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Transaction copyWith({
    String? id,
    TransactionType? type,
    int? amountMinor,
    String? categoryId,
    String? accountId,
    String? toAccountId,
    DateTime? date,
    String? description,
    String? notes,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amountMinor: amountMinor ?? this.amountMinor,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      date: date ?? this.date,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'amount_minor': amountMinor,
      'category_id': categoryId,
      'account_id': accountId,
      'to_account_id': toAccountId,
      'date_epoch_ms': date.millisecondsSinceEpoch,
      'description': description,
      'notes': notes,
      'tags': tags.join(','),
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    final tagsString = map['tags'] as String?;
    final tagsList = tagsString != null && tagsString.isNotEmpty
        ? tagsString.split(',').where((t) => t.isNotEmpty).toList()
        : <String>[];

    return Transaction(
      id: map['id'] as String,
      type: TransactionType.values.byName(map['type'] as String),
      amountMinor: map['amount_minor'] as int,
      categoryId: map['category_id'] as String?,
      accountId: map['account_id'] as String,
      toAccountId: map['to_account_id'] as String?,
      date: DateTime.fromMillisecondsSinceEpoch(map['date_epoch_ms'] as int),
      description: map['description'] as String,
      notes: map['notes'] as String?,
      tags: tagsList,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        amountMinor,
        categoryId,
        accountId,
        toAccountId,
        date,
        description,
        notes,
        tags,
        createdAt,
        updatedAt,
      ];
}
