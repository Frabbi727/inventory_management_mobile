class VariantCombinationDraft {
  const VariantCombinationDraft({
    required this.key,
    required this.label,
    required this.attributes,
    required this.quantity,
    this.attributeNameDraft = '',
    this.attributeValueDraft = '',
    this.sku,
    this.barcode,
    this.buyingPrice,
    this.sellingPrice,
    this.variantId,
    this.status = 'active',
    this.isSkuEdited = false,
  });

  final String key;
  final String label;
  final Map<String, String> attributes;
  final int quantity;
  final String attributeNameDraft;
  final String attributeValueDraft;
  final String? sku;
  final String? barcode;
  final num? buyingPrice;
  final num? sellingPrice;
  final int? variantId;
  final String status;
  final bool isSkuEdited;

  bool get isActive => status.toLowerCase() != 'inactive';

  VariantCombinationDraft copyWith({
    String? key,
    String? label,
    Map<String, String>? attributes,
    int? quantity,
    String? attributeNameDraft,
    String? attributeValueDraft,
    String? sku,
    bool clearSku = false,
    String? barcode,
    bool clearBarcode = false,
    num? buyingPrice,
    num? sellingPrice,
    int? variantId,
    bool clearVariantId = false,
    String? status,
    bool? isSkuEdited,
  }) {
    return VariantCombinationDraft(
      key: key ?? this.key,
      label: label ?? this.label,
      attributes: attributes ?? this.attributes,
      quantity: quantity ?? this.quantity,
      attributeNameDraft: attributeNameDraft ?? this.attributeNameDraft,
      attributeValueDraft: attributeValueDraft ?? this.attributeValueDraft,
      sku: clearSku ? null : sku ?? this.sku,
      barcode: clearBarcode ? null : barcode ?? this.barcode,
      buyingPrice: buyingPrice ?? this.buyingPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      variantId: clearVariantId ? null : variantId ?? this.variantId,
      status: status ?? this.status,
      isSkuEdited: isSkuEdited ?? this.isSkuEdited,
    );
  }
}
