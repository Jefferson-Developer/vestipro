import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_address.freezed.dart';

/// Delivery or billing address snapshot captured on an `Order` (TASK-095).
///
/// Deliberately a plain, order-owned snapshot instead of a reference to one
/// of the customer's registered addresses (`CustomerAddress`): once an order
/// is placed, its delivery/billing address must never silently change if the
/// customer's own registration is edited afterwards. Which entry point
/// copies a `CustomerAddress` into an `OrderAddress` (or lets the seller type
/// a one-off address) is a later EPIC-13 task's concern, not this one.
@freezed
abstract class OrderAddress with _$OrderAddress {
  const OrderAddress._();

  const factory OrderAddress({
    required String street,
    String? number,
    String? complement,
    String? district,
    required String city,
    required String state,
    required String zipCode,
    @Default('BR') String country,
  }) = _OrderAddress;

  String get summary {
    final numberLabel = number == null || number!.isEmpty ? 's/n' : number!;
    return '$street, $numberLabel - $city/$state';
  }
}
