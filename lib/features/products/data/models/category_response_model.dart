import '../../../../core/models/api_list_response_model.dart';

class CategoryResponseModel extends ApiListResponseModel<CategoryModel> {
  const CategoryResponseModel({super.success, super.message, super.data});

  factory CategoryResponseModel.fromJson(Map<String, dynamic> json) {
    final parsed = ApiListResponseModel<CategoryModel>.fromJson(
      json,
      CategoryModel.fromJson,
    );

    return CategoryResponseModel(
      success: parsed.success,
      message: parsed.message,
      data: parsed.data,
    );
  }

  Map<String, dynamic> toJson() =>
      super.toResponseJson((category) => category.toJson());

  @override
  String toString() {
    return 'CategoryResponseModel{success: $success, data: $data}';
  }
}

class CategoryModel {
  final int? id;
  final String? name;

  const CategoryModel({this.id, this.name});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(id: _asInt(json['id']), name: json['name'] as String?);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{'id': id, 'name': name};

  @override
  String toString() {
    return 'CategoryModel{id: $id, name: $name}';
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
}
