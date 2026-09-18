import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class LedgerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isPrimary;
  final bool isLoading;
  final double? width;
  final Color? customColor;

  const LedgerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isPrimary = true,
    this.isLoading = false,
    this.width,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = customColor ?? AppColors.gold;

    Widget childContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: isPrimary ? Colors.black : effectiveColor,
            ),
          ),
        ],
      ],
    );

    final buttonStyle = isPrimary
        ? ElevatedButton.styleFrom(
            backgroundColor: effectiveColor,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          )
        : OutlinedButton.styleFrom(
            foregroundColor: effectiveColor,
            side: BorderSide(color: effectiveColor.withValues(alpha: 0.6), width: 1.2),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          );

    return SizedBox(
      width: width,
      child: isPrimary
          ? ElevatedButton(onPressed: isLoading ? null : onPressed, style: buttonStyle, child: childContent)
          : OutlinedButton(onPressed: isLoading ? null : onPressed, style: buttonStyle, child: childContent),
    );
  }
}
