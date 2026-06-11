import 'package:json_annotation/json_annotation.dart';

import 'customer_created_by_model.dart';

part 'customer_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CustomerModel {
  const CustomerModel({
    this.id,
    this.name,
    this.phone,
    this.address,
    this.area,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.localMobileRef,
  });

  final int? id;
  final String? name;
  final String? phone;
  final String? address;
  final String? area;

  @JsonKey(name: 'created_by')
  final CustomerCreatedByModel? createdBy;

  @JsonKey(name: 'created_at')
  final String? createdAt;

  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  /// Local-only field: the UUID used as mobile_ref when this customer was created offline.
  /// Never serialized to/from API JSON.
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? localMobileRef;

  factory CustomerModel.fromJson(Map<String, dynamic> json) =>
      _$CustomerModelFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerModelToJson(this);
}
