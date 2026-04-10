import 'package:flutter/material.dart';

enum ProductStockStatus {
  inStock,
  lowStock,
  outOfStock;

  static ProductStockStatus? fromApiValue(String? value) {
    return switch (value) {
      'in_stock' => ProductStockStatus.inStock,
      'low_stock' => ProductStockStatus.lowStock,
      'out_of_stock' => ProductStockStatus.outOfStock,
      _ => null,
    };
  }

  static String? toApiValue(ProductStockStatus? value) => value?.apiValue;

  static ProductStockStatus resolve({
    ProductStockStatus? apiStatus,
    int? currentStock,
    int? minimumStockAlert,
  }) {
    if (apiStatus != null) {
      return apiStatus;
    }

    if (currentStock == null) {
      return ProductStockStatus.inStock;
    }

    if (currentStock <= 0) {
      return ProductStockStatus.outOfStock;
    }

    final alertThreshold = minimumStockAlert ?? 0;
    if (alertThreshold > 0 && currentStock <= alertThreshold) {
      return ProductStockStatus.lowStock;
    }

    return ProductStockStatus.inStock;
  }

  String get apiValue => switch (this) {
    ProductStockStatus.inStock => 'in_stock',
    ProductStockStatus.lowStock => 'low_stock',
    ProductStockStatus.outOfStock => 'out_of_stock',
  };

  String get displayLabel => switch (this) {
    ProductStockStatus.inStock => 'In Stock',
    ProductStockStatus.lowStock => 'Low Stock',
    ProductStockStatus.outOfStock => 'Out of Stock',
  };

  Color get badgeColor => switch (this) {
    ProductStockStatus.inStock => const Color(0xFFE7F6EE),
    ProductStockStatus.lowStock => const Color(0xFFFFF4DB),
    ProductStockStatus.outOfStock => const Color(0xFFFCE8E6),
  };

  Color get textColor => switch (this) {
    ProductStockStatus.inStock => const Color(0xFF166534),
    ProductStockStatus.lowStock => const Color(0xFF9A6700),
    ProductStockStatus.outOfStock => const Color(0xFFB42318),
  };

  Color get accentColor => switch (this) {
    ProductStockStatus.inStock => const Color(0xFF16A34A),
    ProductStockStatus.lowStock => const Color(0xFFF59E0B),
    ProductStockStatus.outOfStock => const Color(0xFFDC2626),
  };

  Color get surfaceTintColor => switch (this) {
    ProductStockStatus.inStock => const Color(0xFFF1FCF5),
    ProductStockStatus.lowStock => const Color(0xFFFFF9ED),
    ProductStockStatus.outOfStock => const Color(0xFFFFF1F1),
  };

  Color get borderColor => switch (this) {
    ProductStockStatus.inStock => const Color(0xFFB7E4C7),
    ProductStockStatus.lowStock => const Color(0xFFF8D89A),
    ProductStockStatus.outOfStock => const Color(0xFFF2B8B5),
  };

  IconData get icon => switch (this) {
    ProductStockStatus.inStock => Icons.check_circle_rounded,
    ProductStockStatus.lowStock => Icons.warning_amber_rounded,
    ProductStockStatus.outOfStock => Icons.cancel_rounded,
  };
}
