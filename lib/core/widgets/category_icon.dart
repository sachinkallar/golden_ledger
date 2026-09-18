import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CategoryIcon extends StatelessWidget {
  final String iconName;
  final Color? color;
  final double size;

  const CategoryIcon({
    super.key,
    required this.iconName,
    this.color,
    this.size = 40,
  });

  static IconData getIconData(String name) {
    switch (name.toLowerCase()) {
      case 'food':
      case 'dining':
      case 'lunch':
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'groceries':
      case 'grocery':
        return Icons.shopping_basket_rounded;
      case 'coffee':
      case 'tea':
        return Icons.local_cafe_rounded;
      case 'transport':
      case 'travel':
      case 'commute':
        return Icons.directions_bus_rounded;
      case 'fuel':
      case 'petrol':
        return Icons.local_gas_station_rounded;
      case 'cab':
      case 'uber':
      case 'taxi':
        return Icons.local_taxi_rounded;
      case 'bills':
      case 'rent':
      case 'housing':
        return Icons.receipt_long_rounded;
      case 'electricity':
        return Icons.bolt_rounded;
      case 'subscriptions':
      case 'ott':
        return Icons.subscriptions_rounded;
      case 'shopping':
      case 'ecommerce':
        return Icons.shopping_bag_rounded;
      case 'entertainment':
      case 'movies':
        return Icons.movie_rounded;
      case 'health':
      case 'medicine':
        return Icons.medical_services_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'salary':
        return Icons.account_balance_wallet_rounded;
      case 'freelance':
        return Icons.laptop_mac_rounded;
      case 'business':
        return Icons.store_rounded;
      case 'investment':
        return Icons.trending_up_rounded;
      case 'refund':
      case 'cashback':
        return Icons.replay_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'bank':
        return Icons.account_balance_rounded;
      case 'cash':
        return Icons.payments_rounded;
      case 'upi':
        return Icons.qr_code_rounded;
      case 'credit_card':
        return Icons.credit_card_rounded;
      case 'loan':
        return Icons.money_off_rounded;
      case 'transfer':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.gold;
    final iconData = getIconData(iconName);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(
          color: effectiveColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          iconData,
          color: effectiveColor,
          size: size * 0.52,
        ),
      ),
    );
  }
}
