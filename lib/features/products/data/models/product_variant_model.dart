import 'product_stock_status.dart';

class ProductVariantModel {
  const ProductVariantModel({
    this.id,
    this.combinationKey,
    this.combinationLabel,
    this.optionValues,
    this.isActive,
    this.currentStock,
    this.stockStatus,
  });

  final int? id;
  final String? combinationKey;
  final String? combinationLabel;
  final Map<String, String>? optionValues;
  final bool? isActive;
  final int? currentStock;
  final ProductStockStatus? stockStatus;

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      id: _asInt(json['id']),
      combinationKey: json['combination_key'] as String?,
      combinationLabel: json['combination_label'] as String?,
      optionValues: _asStringMap(json['option_values']),
      isActive: _asBool(json['is_active']),
      currentStock: _asInt(json['current_stock']),
      stockStatus: ProductStockStatus.fromApiValue(
        json['stock_status'] as String?,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'combination_key': combinationKey,
      'combination_label': combinationLabel,
      'option_values': optionValues,
      'is_active': isActive,
      'current_stock': currentStock,
      'stock_status': ProductStockStatus.toApiValue(stockStatus),
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

  static bool? _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }
    return null;
  }

  static Map<String, String>? _asStringMap(dynamic value) {
    if (value is! Map) {
      return null;
    }
    final result = <String, String>{};
    for (final entry in value.entries) {
      if (entry.key == null || entry.value == null) {
        continue;
      }
      result[entry.key.toString()] = entry.value.toString();
    }
    return result;
  }
}
