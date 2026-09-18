import 'package:equatable/equatable.dart';

enum CategoryType {
  expense,
  income;

  String get displayName {
    switch (this) {
      case CategoryType.expense:
        return 'Expense';
      case CategoryType.income:
        return 'Income';
    }
  }
}

class Category extends Equatable {
  final String id;
  final String name;
  final CategoryType type;
  final String? parentId;
  final String iconName;
  final String colorHex;
  final bool isSystem;
  final bool isArchived;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
    required this.iconName,
    required this.colorHex,
    this.isSystem = false,
    this.isArchived = false,
  });

  Category copyWith({
    String? id,
    String? name,
    CategoryType? type,
    String? parentId,
    String? iconName,
    String? colorHex,
    bool? isSystem,
    bool? isArchived,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      isSystem: isSystem ?? this.isSystem,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'parent_id': parentId,
      'icon_name': iconName,
      'color_hex': colorHex,
      'is_system': isSystem ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      type: CategoryType.values.byName(map['type'] as String),
      parentId: map['parent_id'] as String?,
      iconName: map['icon_name'] as String? ?? 'category',
      colorHex: map['color_hex'] as String? ?? '#E5A93C',
      isSystem: (map['is_system'] as int? ?? 0) == 1,
      isArchived: (map['is_archived'] as int? ?? 0) == 1,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        parentId,
        iconName,
        colorHex,
        isSystem,
        isArchived,
      ];
}
