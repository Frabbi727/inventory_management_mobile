class ProductVariantSummaryModel {
  const ProductVariantSummaryModel({
    this.totalVariants,
    this.inStockCount,
    this.lowStockCount,
    this.outOfStockCount,
  });

  final int? totalVariants;
  final int? inStockCount;
  final int? lowStockCount;
  final int? outOfStockCount;

  factory ProductVariantSummaryModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantSummaryModel(
      totalVariants: _asInt(json['total_variants']),
      inStockCount: _asInt(json['in_stock_count']),
      lowStockCount: _asInt(json['low_stock_count']),
      outOfStockCount: _asInt(json['out_of_stock_count']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'total_variants': totalVariants,
      'in_stock_count': inStockCount,
      'low_stock_count': lowStockCount,
      'out_of_stock_count': outOfStockCount,
    };
  }

  static int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}
