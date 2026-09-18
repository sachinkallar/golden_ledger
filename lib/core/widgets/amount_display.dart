import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/currency_formatter.dart';

enum AmountVariant {
  neutral,
  income,
  expense,
  gold,
}

class AmountDisplay extends StatelessWidget {
  final int amountMinor;
  final AmountVariant variant;
  final double fontSize;
  final FontWeight fontWeight;
  final bool showSign;
  final bool compact;

  const AmountDisplay({
    super.key,
    required this.amountMinor,
    this.variant = AmountVariant.neutral,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.showSign = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor;
    String sign = '';

    switch (variant) {
      case AmountVariant.income:
        textColor = AppColors.income;
        if (showSign) sign = '+';
        break;
      case AmountVariant.expense:
        textColor = AppColors.expense;
        if (showSign) sign = '-';
        break;
      case AmountVariant.gold:
        textColor = AppColors.gold;
        break;
      case AmountVariant.neutral:
        textColor = AppColors.textPrimary;
        break;
    }

    final formatted = CurrencyFormatter.format(
      amountMinor.abs(),
      compact: compact,
    );

    return Text(
      '$sign$formatted',
      style: TextStyle(
        color: textColor,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
