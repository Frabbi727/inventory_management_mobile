import 'package:json_annotation/json_annotation.dart';

import 'pagination_meta_link_model.dart';

part 'pagination_meta_model.g.dart';

@JsonSerializable(explicitToJson: true)
class PaginationMetaModel {
  const PaginationMetaModel({
    this.currentPage,
    this.from,
    this.lastPage,
    this.links,
    this.path,
    this.perPage,
    this.to,
    this.total,
  });

  @JsonKey(name: 'current_page')
  final int? currentPage;

  final int? from;

  @JsonKey(name: 'last_page')
  final int? lastPage;

  final List<PaginationMetaLinkModel>? links;
  final String? path;

  @JsonKey(name: 'per_page')
  final int? perPage;

  final int? to;
  final int? total;

  factory PaginationMetaModel.fromJson(Map<String, dynamic> json) =>
      _$PaginationMetaModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationMetaModelToJson(this);
}
