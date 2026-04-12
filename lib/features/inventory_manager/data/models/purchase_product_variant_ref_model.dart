class PurchaseProductVariantRefModel {
  const PurchaseProductVariantRefModel({
    this.id,
    this.label,
    this.optionValues,
  });

  final int? id;
  final String? label;
  final Map<String, String>? optionValues;

  factory PurchaseProductVariantRefModel.fromJson(Map<String, dynamic> json) {
    return PurchaseProductVariantRefModel(
      id: _asInt(json['id']),
      label: json['label'] as String?,
      optionValues: _asStringMap(json['option_values']),
    );
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
