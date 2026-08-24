import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_custom_field_value.freezed.dart';

/// A single organization-defined custom attribute value attached to a
/// [Product], linked back to its [ProductCustomFieldDefinition] by
/// [fieldDefinitionId].
///
/// [value] holds a `String`, `num`, `bool` or `List<String>` depending on the
/// definition's `ProductCustomFieldType`; the caller is responsible for
/// validating it against the definition before persisting.
@freezed
abstract class ProductCustomFieldValue with _$ProductCustomFieldValue {
  const factory ProductCustomFieldValue({
    required String fieldDefinitionId,
    required Object? value,
  }) = _ProductCustomFieldValue;
}
