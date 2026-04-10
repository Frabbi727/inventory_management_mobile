class PurchaseCreatorModel {
  const PurchaseCreatorModel({this.id, this.name});

  final int? id;
  final String? name;

  factory PurchaseCreatorModel.fromJson(Map<String, dynamic> json) {
    return PurchaseCreatorModel(
      id: json['id'] as int?,
      name: json['name'] as String?,
    );
  }
}
