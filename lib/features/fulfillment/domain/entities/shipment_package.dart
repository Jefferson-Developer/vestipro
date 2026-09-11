import 'shipment_package_item.dart';

/// One volume/embalagem of a `Shipment`/romaneio (TASK-214, EPIC-32) —
/// immutable once created by `createShipment` (Cloud Function): the exact
/// items/quantities packed into it, so an eventual entrega parcial can always
/// be reconciled back to the physical volume it belongs to (`tasks.md`:
/// "Entrega parcial deve preservar itens/quantidades por volume para evitar
/// divergência no pós-venda").
final class ShipmentPackage {
  const ShipmentPackage({
    required this.packageNumber,
    required this.items,
    this.weightKg,
  });

  final int packageNumber;
  final List<ShipmentPackageItem> items;
  final double? weightKg;

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShipmentPackage &&
          other.packageNumber == packageNumber &&
          other.weightKg == weightKg &&
          _listEquals(other.items, items));

  @override
  int get hashCode =>
      Object.hash(packageNumber, weightKg, Object.hashAll(items));
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
