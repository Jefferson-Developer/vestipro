import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/cep.dart';
import '../value_objects/customer_address_type.dart';

part 'customer_address.freezed.dart';

@freezed
abstract class CustomerAddress with _$CustomerAddress {
  const CustomerAddress._();

  const factory CustomerAddress({
    required String id,
    required CustomerAddressType type,
    required String street,
    String? number,
    String? complement,
    String? district,
    required String city,
    required String state,
    required Cep zipCode,
    @Default('BR') String country,
    @Default(false) bool isPrimary,
  }) = _CustomerAddress;

  String get summary {
    final numberLabel = number == null || number!.isEmpty ? 's/n' : number!;
    return '$street, $numberLabel - $city/$state';
  }
}
