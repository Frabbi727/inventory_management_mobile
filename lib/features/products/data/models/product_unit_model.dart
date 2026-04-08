import 'package:json_annotation/json_annotation.dart';

part 'product_unit_model.g.dart';

@JsonSerializable()
class ProductUnitModel {
  const ProductUnitModel({this.id, this.name, this.shortName});

  final int? id;
  final String? name;

  @JsonKey(name: 'short_name')
  final String? shortName;

  factory ProductUnitModel.fromJson(Map<String, dynamic> json) =>
      _$ProductUnitModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductUnitModelToJson(this);
}
