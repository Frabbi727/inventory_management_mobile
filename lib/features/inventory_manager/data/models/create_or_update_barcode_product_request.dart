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
    this.variants,
  });

  final String name;
  final String? sku;
  final String barcode;
  final int categoryId;
  final int? subcategoryId;
  final int unitId;
  final num? purchasePrice;
  final num? sellingPrice;
  final int minimumStockAlert;
  final String status;
  final bool? hasVariants;
  final List<ProductVariantRowPayload>? variants;

  factory CreateOrUpdateBarcodeProductRequest.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawVariants = json['variants'];
    return CreateOrUpdateBarcodeProductRequest(
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String? ?? '',
      categoryId: _asInt(json['category_id']) ?? 0,
      subcategoryId: _asInt(json['subcategory_id']),
      unitId: _asInt(json['unit_id']) ?? 0,
      purchasePrice: _asNum(json['purchase_price']),
      sellingPrice: _asNum(json['selling_price']),
      minimumStockAlert: _asInt(json['minimum_stock_alert']) ?? 0,
      status: json['status'] as String? ?? 'active',
      hasVariants: _asBool(json['has_variants']),
      variants: rawVariants is List
          ? rawVariants
                .whereType<Map<String, dynamic>>()
                .map(ProductVariantRowPayload.fromJson)
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
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
      if (variants != null)
        'variants': variants!.map((variant) => variant.toJson()).toList(),
    };
  }

  Map<String, String> toMultipartFields() {
    final fields = <String, String>{
      'name': name,
      'barcode': barcode,
      'category_id': '$categoryId',
      if (subcategoryId != null) 'subcategory_id': '$subcategoryId',
      'unit_id': '$unitId',
      'purchase_price': purchasePrice?.toString() ?? '',
      'selling_price': sellingPrice?.toString() ?? '',
      'minimum_stock_alert': '$minimumStockAlert',
      'status': status,
    };

    if (sku != null) {
      fields['sku'] = sku!;
    }

    if (hasVariants != null) {
      fields['has_variants'] = hasVariants! ? '1' : '0';
    }

    final rows = variants ?? const <ProductVariantRowPayload>[];
    for (var index = 0; index < rows.length; index++) {
      final variant = rows[index];
      variant.attributes.forEach((key, value) {
        fields['variants[$index][attributes][$key]'] = value;
      });
      if (variant.sku != null && variant.sku!.isNotEmpty) {
        fields['variants[$index][sku]'] = variant.sku!;
      }
      if (variant.barcode != null && variant.barcode!.isNotEmpty) {
        fields['variants[$index][barcode]'] = variant.barcode!;
      }
      fields['variants[$index][quantity]'] = '${variant.quantity}';
      fields['variants[$index][buying_price]'] = '${variant.buyingPrice}';
      fields['variants[$index][selling_price]'] = '${variant.sellingPrice}';
      fields['variants[$index][status]'] = variant.status;
    }

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

class ProductVariantRowPayload {
  const ProductVariantRowPayload({
    required this.attributes,
    this.sku,
    this.barcode,
    required this.quantity,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.status,
  });

  final Map<String, String> attributes;
  final String? sku;
  final String? barcode;
  final int quantity;
  final num buyingPrice;
  final num sellingPrice;
  final String status;

  factory ProductVariantRowPayload.fromJson(Map<String, dynamic> json) {
    return ProductVariantRowPayload(
      attributes: _asStringMap(json['attributes']),
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      quantity:
          CreateOrUpdateBarcodeProductRequest._asInt(json['quantity']) ?? 0,
      buyingPrice:
          CreateOrUpdateBarcodeProductRequest._asNum(
            json['buying_price'] ?? json['purchase_price'],
          ) ??
          0,
      sellingPrice:
          CreateOrUpdateBarcodeProductRequest._asNum(json['selling_price']) ??
          0,
      status: json['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'attributes': attributes,
      if (sku != null) 'sku': sku,
      if (barcode != null) 'barcode': barcode,
      'quantity': quantity,
      'buying_price': buyingPrice,
      'selling_price': sellingPrice,
      'status': status,
    };
  }

  static Map<String, String> _asStringMap(dynamic value) {
    if (value is! Map) {
      return const <String, String>{};
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
