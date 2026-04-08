import 'package:json_annotation/json_annotation.dart';

part 'pagination_meta_link_model.g.dart';

@JsonSerializable()
class PaginationMetaLinkModel {
  const PaginationMetaLinkModel({this.url, this.label, this.page, this.active});

  final String? url;
  final String? label;
  final int? page;
  final bool? active;

  factory PaginationMetaLinkModel.fromJson(Map<String, dynamic> json) =>
      _$PaginationMetaLinkModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationMetaLinkModelToJson(this);
}
