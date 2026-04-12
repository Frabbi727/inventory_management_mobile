class VariantCombinationDraft {
  const VariantCombinationDraft({
    required this.key,
    required this.label,
    required this.optionValues,
    required this.quantity,
    this.variantId,
    this.isActive = true,
  });

  final String key;
  final String label;
  final Map<String, String> optionValues;
  final int quantity;
  final int? variantId;
  final bool isActive;

  VariantCombinationDraft copyWith({
    String? key,
    String? label,
    Map<String, String>? optionValues,
    int? quantity,
    int? variantId,
    bool clearVariantId = false,
    bool? isActive,
  }) {
    return VariantCombinationDraft(
      key: key ?? this.key,
      label: label ?? this.label,
      optionValues: optionValues ?? this.optionValues,
      quantity: quantity ?? this.quantity,
      variantId: clearVariantId ? null : variantId ?? this.variantId,
      isActive: isActive ?? this.isActive,
    );
  }
}
