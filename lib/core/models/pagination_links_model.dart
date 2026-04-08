import 'package:json_annotation/json_annotation.dart';

part 'pagination_links_model.g.dart';

@JsonSerializable()
class PaginationLinksModel {
  const PaginationLinksModel({this.first, this.last, this.prev, this.next});

  final String? first;
  final String? last;
  final String? prev;
  final String? next;

  factory PaginationLinksModel.fromJson(Map<String, dynamic> json) =>
      _$PaginationLinksModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationLinksModelToJson(this);
}
