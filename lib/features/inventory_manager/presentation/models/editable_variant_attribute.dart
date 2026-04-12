class EditableVariantAttribute {
  const EditableVariantAttribute({
    required this.id,
    this.serverId,
    this.name = '',
    this.values = const <String>[],
  });

  final String id;
  final int? serverId;
  final String name;
  final List<String> values;

  EditableVariantAttribute copyWith({
    String? id,
    int? serverId,
    bool clearServerId = false,
    String? name,
    List<String>? values,
  }) {
    return EditableVariantAttribute(
      id: id ?? this.id,
      serverId: clearServerId ? null : serverId ?? this.serverId,
      name: name ?? this.name,
      values: values ?? this.values,
    );
  }
}
