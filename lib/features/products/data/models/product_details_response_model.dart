import 'package:json_annotation/json_annotation.dart';

import 'product_model.dart';

part 'product_details_response_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ProductDetailsResponseModel {
  const ProductDetailsResponseModel({this.data});

  final ProductModel? data;

  factory ProductDetailsResponseModel.fromJson(Map<String, dynamic> json) =>
      _$ProductDetailsResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductDetailsResponseModelToJson(this);
}
