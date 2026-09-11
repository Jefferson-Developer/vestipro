import '../../../orders/domain/entities/order_item.dart';
import 'line_sheet.dart';

final class LineSheetOrderFormCell {
  const LineSheetOrderFormCell({
    required this.productId,
    required this.variantId,
    required this.quantity,
    required this.unitPrice,
  });

  final String productId;
  final String variantId;
  final int quantity;
  final double unitPrice;

  double get subtotal => quantity * unitPrice;
}

final class LineSheetOrderFormDraft {
  const LineSheetOrderFormDraft({
    required this.lineSheetId,
    required this.lineSheetVersion,
    required this.collectionId,
    required this.cells,
  });

  final String lineSheetId;
  final int lineSheetVersion;
  final String collectionId;
  final Map<String, LineSheetOrderFormCell> cells;

  int get totalPieces =>
      cells.values.fold(0, (sum, cell) => sum + cell.quantity);

  double get totalAmount =>
      cells.values.fold(0, (sum, cell) => sum + cell.subtotal);

  LineSheetOrderFormDraft changeQuantity({
    required String productId,
    required String variantId,
    required int quantity,
    required double unitPrice,
  }) {
    final nextCells = Map<String, LineSheetOrderFormCell>.of(cells);
    if (quantity <= 0) {
      nextCells.remove(variantId);
    } else {
      nextCells[variantId] = LineSheetOrderFormCell(
        productId: productId,
        variantId: variantId,
        quantity: quantity,
        unitPrice: unitPrice,
      );
    }
    return LineSheetOrderFormDraft(
      lineSheetId: lineSheetId,
      lineSheetVersion: lineSheetVersion,
      collectionId: collectionId,
      cells: nextCells,
    );
  }

  List<OrderItem> toOrderItems() {
    return cells.values
        .map(
          (cell) => OrderItem(
            id: '${lineSheetId}_${lineSheetVersion}_${cell.variantId}',
            variantId: cell.variantId,
            productId: cell.productId,
            quantity: cell.quantity,
            unitPrice: cell.unitPrice,
            subtotal: cell.subtotal,
          ),
        )
        .toList(growable: false);
  }

  Map<String, Object?> versionSnapshot() => <String, Object?>{
    'line_sheet_id': lineSheetId,
    'line_sheet_version': lineSheetVersion,
    'collection_id': collectionId,
  };
}

final class LineSheetOrderFormSession {
  const LineSheetOrderFormSession({required this.view, required this.draft});

  final LineSheetView view;
  final LineSheetOrderFormDraft draft;
}
