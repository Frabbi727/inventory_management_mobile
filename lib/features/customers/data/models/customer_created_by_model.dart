import 'package:json_annotation/json_annotation.dart';

part 'customer_created_by_model.g.dart';

@JsonSerializable()
class CustomerCreatedByModel {
  const CustomerCreatedByModel({this.id, this.name});

  final int? id;
  final String? name;

  factory CustomerCreatedByModel.fromJson(Map<String, dynamic> json) =>
      _$CustomerCreatedByModelFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerCreatedByModelToJson(this);
}
