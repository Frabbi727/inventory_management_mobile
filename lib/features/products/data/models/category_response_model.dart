import 'package:json_annotation/json_annotation.dart';

part 'category_response_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CategoryResponseModel {
  @JsonKey(name: 'success')
  final bool? success;

  @JsonKey(name: 'data')
  final List<CategoryModel>? data;

  CategoryResponseModel({
    this.success,
    this.data,
  });

  factory CategoryResponseModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryResponseModelToJson(this);

  @override
  String toString() {
    return 'CategoryResponseModel{success: $success, data: $data}';
  }

}

@JsonSerializable()
class CategoryModel {
  @JsonKey(name: 'id')
  final int? id;

  @JsonKey(name: 'name')
  final String? name;

  CategoryModel({
    this.id,
    this.name,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryModelToJson(this);

  @override
  String toString() {
    return 'CategoryModel{id: $id, name: $name}';
  }


}