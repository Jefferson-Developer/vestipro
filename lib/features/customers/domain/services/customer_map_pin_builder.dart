import '../entities/customer.dart';
import '../entities/customer_address.dart';
import '../entities/customer_map_pin.dart';

/// Builds the pins the customer map (TASK-176) actually plots, from the same
/// filtered/paginated carteira list already loaded by
/// `ListCustomerPortfolioUseCase` for the list view — no separate query, so
/// list and map can never diverge on which customers are visible.
///
/// A customer without any geocoded address is simply skipped here: it still
/// appears in the list view (unaffected), it just never becomes a pin. Use
/// [CustomerMapPinBuilder.customersWithoutLocationCount] to show the "N
/// clientes sem localização" notice the task requires.
final class CustomerMapPinBuilder {
  const CustomerMapPinBuilder();

  List<CustomerMapPin> build(List<Customer> customers) {
    final pins = <CustomerMapPin>[];
    for (final customer in customers) {
      final address = _bestGeocodedAddress(customer);
      if (address == null) continue;
      pins.add(
        CustomerMapPin(
          customerId: customer.id,
          displayName: customer.displayName,
          status: customer.status,
          potential: customer.potential,
          lastPurchaseAt: customer.lastPurchaseAt,
          coordinates: address.coordinates!,
        ),
      );
    }
    return List.unmodifiable(pins);
  }

  int customersWithoutLocationCount(List<Customer> customers) {
    var count = 0;
    for (final customer in customers) {
      if (_bestGeocodedAddress(customer) == null) count += 1;
    }
    return count;
  }

  /// Prefers the primary address when it is geocoded; otherwise falls back
  /// to the first other geocoded address, if any.
  CustomerAddress? _bestGeocodedAddress(Customer customer) {
    CustomerAddress? fallback;
    for (final address in customer.addresses) {
      if (!address.hasCoordinates) continue;
      if (address.isPrimary) return address;
      fallback ??= address;
    }
    return fallback;
  }
}
