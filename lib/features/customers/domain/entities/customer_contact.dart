import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/customer_contact_type.dart';

part 'customer_contact.freezed.dart';

@freezed
abstract class CustomerContact with _$CustomerContact {
  const CustomerContact._();

  const factory CustomerContact({
    required String id,
    required CustomerContactType type,
    required String name,
    String? role,
    String? phone,
    String? email,
    @Default(false) bool isPrimary,
  }) = _CustomerContact;

  String get preferredChannel => phone ?? email ?? '';
}
