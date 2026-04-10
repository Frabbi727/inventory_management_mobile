import 'package:flutter/material.dart';

import '../../features/products/data/models/product_stock_status.dart';

class ProductStockStatusBadge extends StatelessWidget {
  const ProductStockStatusBadge({
    super.key,
    required this.status,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  final ProductStockStatus status;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: status.badgeColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.displayLabel,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: status.textColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
