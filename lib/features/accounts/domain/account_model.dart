import 'package:equatable/equatable.dart';

enum AccountType {
  cash,
  bank,
  savings,
  upi,
  creditCard,
  loan,
  investment,
  other;

  String get displayName {
    switch (this) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.bank:
        return 'Bank Account';
      case AccountType.savings:
        return 'Savings Account';
      case AccountType.upi:
        return 'UPI / Wallet';
      case AccountType.creditCard:
        return 'Credit Card';
      case AccountType.loan:
        return 'Loan';
      case AccountType.investment:
        return 'Investment';
      case AccountType.other:
        return 'Other';
    }
  }

  bool get isLiability => this == AccountType.creditCard || this == AccountType.loan;
}

class Account extends Equatable {
  final String id;
  final String name;
  final AccountType type;
  final int openingBalanceMinor;
  final int currentBalanceMinor;
  final String currency;
  final String iconName;
  final String colorHex;
  final bool isActive;
  final DateTime createdAt;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.openingBalanceMinor,
    this.currentBalanceMinor = 0,
    this.currency = 'INR',
    this.iconName = 'bank',
    this.colorHex = '#E5A93C',
    this.isActive = true,
    required this.createdAt,
  });

  bool get isLiability => type.isLiability;

  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    int? openingBalanceMinor,
    int? currentBalanceMinor,
    String? currency,
    String? iconName,
    String? colorHex,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      openingBalanceMinor: openingBalanceMinor ?? this.openingBalanceMinor,
      currentBalanceMinor: currentBalanceMinor ?? this.currentBalanceMinor,
      currency: currency ?? this.currency,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'opening_balance_minor': openingBalanceMinor,
      'currency': currency,
      'icon_name': iconName,
      'color_hex': colorHex,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map, {int currentBalanceMinor = 0}) {
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      type: AccountType.values.byName(map['type'] as String),
      openingBalanceMinor: map['opening_balance_minor'] as int,
      currentBalanceMinor: currentBalanceMinor,
      currency: map['currency'] as String? ?? 'INR',
      iconName: map['icon_name'] as String? ?? 'bank',
      colorHex: map['color_hex'] as String? ?? '#E5A93C',
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        openingBalanceMinor,
        currentBalanceMinor,
        currency,
        iconName,
        colorHex,
        isActive,
        createdAt,
      ];
}
