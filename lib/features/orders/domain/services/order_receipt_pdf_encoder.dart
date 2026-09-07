import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../entities/order.dart';
import '../entities/order_item.dart';
import '../entities/order_signature.dart';
import '../value_objects/order_signer_role.dart';

/// Pure Dart PDF encoder for one `Order`'s own comprovante/receipt
/// (EPIC-13, TASK-180) — mirrors `PdfReportEncoder`'s own "pure Dart, no
/// Flutter/Firebase dependency" shape (TASK-148), so it stays safe to run on
/// the calling isolate or a background one.
///
/// This is the first comprovante/PDF flow for an `Order` in this codebase
/// (see the CONCLUIDA doc's own "Decisões técnicas" for why one did not
/// already exist to extend, as `tasks.md`'s own "Exibir a assinatura como
/// parte do PDF/comprovante do pedido já gerado pelo fluxo existente" seemed
/// to assume) — intentionally minimal (cover data + itens + totals +
/// signature), not a fiscal document (nota fiscal) substitute.
///
/// Never recomputes anything: every value rendered here is exactly what
/// [Order] already carries (itself always reconciled from `submitOrder`'s
/// own server-side pricing engine) — this encoder only formats.
final class OrderReceiptPdfEncoder {
  const OrderReceiptPdfEncoder();

  Future<Uint8List> encodeToBytes({
    required Order order,
    OrderSignature? signature,
  }) async {
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Text(
              'VestiPro',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: _brandColor,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              order.orderNumber == null
                  ? 'Comprovante de pedido'
                  : 'Comprovante do pedido ${order.orderNumber}',
              style: const pw.TextStyle(fontSize: 13),
            ),
            pw.Divider(color: PdfColors.grey400),
          ],
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (context) => <pw.Widget>[
          _buildSummary(order),
          pw.SizedBox(height: 16),
          _buildItemsTable(order),
          pw.SizedBox(height: 16),
          _buildTotals(order),
          if (signature != null) ...<pw.Widget>[
            pw.SizedBox(height: 24),
            _buildSignature(signature),
          ],
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _buildSummary(Order order) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      pw.Text('Cliente: ${order.customerId}'),
      pw.Text('Vendedor: ${order.sellerId}'),
      pw.Text('Condição de pagamento: ${order.paymentTermId}'),
      if (order.notes != null && order.notes!.isNotEmpty)
        pw.Text('Observações: ${order.notes}'),
    ],
  );

  pw.Widget _buildItemsTable(Order order) => pw.TableHelper.fromTextArray(
    headers: const <String>['Produto', 'Qtd.', 'Preço unit.', 'Subtotal'],
    data: order.items
        .map((item) => _itemRow(item, order.currency))
        .toList(growable: false),
    headerStyle: pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
      fontSize: 9,
    ),
    headerDecoration: pw.BoxDecoration(color: _brandColor),
    cellStyle: const pw.TextStyle(fontSize: 9),
    cellAlignment: pw.Alignment.centerLeft,
  );

  List<String> _itemRow(OrderItem item, String currency) => <String>[
    item.productId,
    item.quantity.toString(),
    _formatCurrency(item.unitPrice, currency),
    _formatCurrency(item.subtotal, currency),
  ];

  pw.Widget _buildTotals(Order order) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: <pw.Widget>[
      pw.Text(
        'Subtotal dos itens: '
        '${_formatCurrency(order.itemsSubtotal, order.currency)}',
      ),
      pw.Text(
        'Desconto: ${_formatCurrency(order.discountAmount, order.currency)}',
      ),
      pw.Text(
        'Acréscimo: '
        '${_formatCurrency(order.surchargeAmount, order.currency)}',
      ),
      pw.Text(
        'Frete: ${_formatCurrency(order.shippingAmount, order.currency)}',
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        'Total: ${_formatCurrency(order.itemsSubtotal + order.surchargeAmount + order.shippingAmount - order.discountAmount, order.currency)}',
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
    ],
  );

  pw.Widget _buildSignature(OrderSignature signature) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      pw.Divider(color: PdfColors.grey400),
      pw.Text(
        'Assinatura eletrônica',
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
      ),
      pw.SizedBox(height: 8),
      pw.Container(
        height: 120,
        width: 240,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
        ),
        child: pw.Image(
          pw.MemoryImage(signature.imageBytes),
          fit: pw.BoxFit.contain,
        ),
      ),
      pw.SizedBox(height: 8),
      pw.Text(
        'Assinado por: ${signature.signedByName} '
        '(${signature.signerRole == OrderSignerRole.customer ? 'cliente' : 'vendedor'})',
        style: const pw.TextStyle(fontSize: 9),
      ),
      pw.Text(
        'Data/hora: ${_formatDateTime(signature.signedAt)}',
        style: const pw.TextStyle(fontSize: 9),
      ),
      pw.Text(
        'Hash do conteúdo no momento da assinatura: ${signature.contentHash}',
        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
      ),
    ],
  );

  static const PdfColor _brandColor = PdfColor.fromInt(0xFF0F172A);

  /// Hand-rolled, isolate-safe currency formatting (never `intl`/
  /// `CurrencyFormatter`) — same rationale `PdfReportEncoder` already
  /// documents for its own `_formatCurrency`: a PDF encoder may run on a
  /// background isolate (`compute`), where locale data is not guaranteed
  /// initialized. Always shows the explicit ISO 4217 [currencyCode]
  /// (TASK-175's own "nunca somar/depender apenas do símbolo" rule), with a
  /// `R$` symbol only for the `BRL` case most VestiPro orders actually use.
  String _formatCurrency(double value, String currencyCode) {
    final normalized = currencyCode.trim().toUpperCase();
    final formatted = normalized == 'BRL'
        ? value.toStringAsFixed(2).replaceAll('.', ',')
        : value.toStringAsFixed(2);
    final prefix = normalized == 'BRL' ? r'R$ ' : '';
    return '$prefix$formatted $normalized';
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    String pad(int v) => v.toString().padLeft(2, '0');
    return '${pad(local.day)}/${pad(local.month)}/${local.year} '
        '${pad(local.hour)}:${pad(local.minute)}';
  }
}
