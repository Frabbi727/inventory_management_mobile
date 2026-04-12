class CreateOrUpdateBarcodeProductRequest {
  const CreateOrUpdateBarcodeProductRequest({
    required this.name,
    this.sku,
    required this.barcode,
    required this.categoryId,
    this.subcategoryId,
    required this.unitId,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.minimumStockAlert,
    required this.status,
    this.hasVariants,
    this.variantAttributes,
    this.variantQuantities,
  });

  final String name;

  final String? sku;

  final String barcode;

  final int categoryId;

  final int? subcategoryId;

  final int unitId;

  final num purchasePrice;

  final num sellingPrice;

  final int minimumStockAlert;

  final String status;
  final bool? hasVariants;
  final List<ProductVariantAttributePayload>? variantAttributes;
  final Map<String, int>? variantQuantities;

  factory CreateOrUpdateBarcodeProductRequest.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawAttributes = json['variant_attributes'];
    final rawQuantities = json['variant_quantities'];
    return CreateOrUpdateBarcodeProductRequest(
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String? ?? '',
      categoryId: _asInt(json['category_id']) ?? 0,
      subcategoryId: _asInt(json['subcategory_id']),
      unitId: _asInt(json['unit_id']) ?? 0,
      purchasePrice: _asNum(json['purchase_price']) ?? 0,
      sellingPrice: _asNum(json['selling_price']) ?? 0,
      minimumStockAlert: _asInt(json['minimum_stock_alert']) ?? 0,
      status: json['status'] as String? ?? 'active',
      hasVariants: _asBool(json['has_variants']),
      variantAttributes: rawAttributes is List
          ? rawAttributes
                .whereType<Map<String, dynamic>>()
                .map(ProductVariantAttributePayload.fromJson)
                .toList()
          : null,
      variantQuantities: rawQuantities is Map
          ? rawQuantities.map(
              (key, value) => MapEntry(
                key.toString(),
                _asInt(value) ?? 0,
              ),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final attributes = variantAttributes;
    return <String, dynamic>{
      'name': name,
      if (sku != null) 'sku': sku,
      'barcode': barcode,
      'category_id': categoryId,
      if (subcategoryId != null) 'subcategory_id': subcategoryId,
      'unit_id': unitId,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'minimum_stock_alert': minimumStockAlert,
      'status': status,
      if (hasVariants != null) 'has_variants': hasVariants,
      if (attributes != null)
        'variant_attributes': attributes
            .map((attribute) => attribute.toJson())
            .toList(),
      if (variantQuantities != null) 'variant_quantities': variantQuantities,
    };
  }

  Map<String, String> toMultipartFields() {
    final fields = <String, String>{
      'name': name,
      if (sku != null) 'sku': sku!,
      'barcode': barcode,
      'category_id': '$categoryId',
      if (subcategoryId != null) 'subcategory_id': '$subcategoryId',
      'unit_id': '$unitId',
      'purchase_price': '$purchasePrice',
      'selling_price': '$sellingPrice',
      'minimum_stock_alert': '$minimumStockAlert',
      'status': status,
    };

    if (hasVariants != null) {
      fields['has_variants'] = hasVariants! ? '1' : '0';
    }

    final attributes = variantAttributes ?? const <ProductVariantAttributePayload>[];
    for (var index = 0; index < attributes.length; index++) {
      final attribute = attributes[index];
      if (attribute.name.trim().isNotEmpty) {
        fields['variant_attributes[$index][name]'] = attribute.name.trim();
      }
      final values = attribute.values;
      for (var valueIndex = 0; valueIndex < values.length; valueIndex++) {
        fields['variant_attributes[$index][values][$valueIndex]'] =
            values[valueIndex];
      }
    }

    variantQuantities?.forEach((key, value) {
      fields['variant_quantities[$key]'] = '$value';
    });

    return fields;
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

  static num? _asNum(dynamic value) {
    if (value is num) {
      return value;
    }
    if (value is String) {
      return num.tryParse(value);
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
}

class ProductVariantAttributePayload {
  const ProductVariantAttributePayload({
    required this.name,
    required this.values,
  });

  final String name;
  final List<String> values;

  factory ProductVariantAttributePayload.fromJson(Map<String, dynamic> json) {
    final rawValues = json['values'];
    return ProductVariantAttributePayload(
      name: json['name'] as String? ?? '',
      values: rawValues is List
          ? rawValues.map((value) => value?.toString() ?? '').toList()
          : const <String>[],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'values': values,
    };
  }
}
