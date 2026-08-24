import '../../../../core/errors/errors.dart';

/// Firestore document shape for an organization-scoped Product custom field
/// definition.
///
/// [id] is supplied from the document id and is never serialized inside
/// [toJson]. [organizationId] is duplicated in the payload so Security Rules
/// and queries can validate tenant scope without trusting a client value.
final class ProductCustomFieldDefinitionDto {
  const ProductCustomFieldDefinitionDto({
    required this.id,
    required this.organizationId,
    required this.key,
    required this.label,
    required this.type,
    required this.isRequired,
    this.options = const <String>[],
  });

  factory ProductCustomFieldDefinitionDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final key = json['key'];
    final label = json['label'];
    final type = json['type'];
    final isRequired = json['isRequired'];
    final rawOptions = json['options'];

    if (organizationId is! String ||
        key is! String ||
        label is! String ||
        type is! String ||
        isRequired is! bool ||
        (rawOptions != null &&
            (rawOptions is! List<dynamic> ||
                rawOptions.any((option) => option is! String)))) {
      throw const ValidationException(
        'Invalid product custom field definition payload.',
        code: 'invalid_product_custom_field_definition_payload',
      );
    }

    return ProductCustomFieldDefinitionDto(
      id: id,
      organizationId: organizationId,
      key: key,
      label: label,
      type: type,
      isRequired: isRequired,
      options: rawOptions == null
          ? const <String>[]
          : List<String>.unmodifiable(
              (rawOptions as List<dynamic>).cast<String>(),
            ),
    );
  }

  final String id;
  final String organizationId;
  final String key;
  final String label;
  final String type;
  final bool isRequired;
  final List<String> options;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'key': key,
      'label': label,
      'type': type,
      'isRequired': isRequired,
      'options': options,
    };
  }
}
