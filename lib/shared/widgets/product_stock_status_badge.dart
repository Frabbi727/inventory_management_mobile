import 'package:flutter/material.dart';

import '../../features/products/data/models/product_stock_status.dart';

class ProductStockStatusBadge extends StatelessWidget {
  const ProductStockStatusBadge({
    super.key,
    required this.status,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.showIcon = false,
  });

  final ProductStockStatus status;
  final EdgeInsetsGeometry padding;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: status.badgeColor,
        border: Border.all(color: status.borderColor),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(status.icon, size: 14, color: status.textColor),
            const SizedBox(width: 4),
          ],
          Text(
            status.displayLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: status.textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
