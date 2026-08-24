import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/product_custom_field_type.dart';

part 'product_custom_field_definition.freezed.dart';

/// Organization-scoped configuration of a Product custom attribute.
///
/// Definitions never leak between tenants: every lookup/listing must be
/// scoped by [organizationId], resolved from the authenticated session, never
/// from client input.
@freezed
abstract class ProductCustomFieldDefinition
    with _$ProductCustomFieldDefinition {
  const factory ProductCustomFieldDefinition({
    required String id,
    required String organizationId,
    required String key,
    required String label,
    required ProductCustomFieldType type,
    required bool isRequired,
    @Default(<String>[]) List<String> options,
  }) = _ProductCustomFieldDefinition;
}
