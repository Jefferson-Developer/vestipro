import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

/// "Ver comprovante" screen (EPIC-13, TASK-180) — renders the already-
/// encoded comprovante PDF bytes (`OrderReceiptPdfEncoder`, called by
/// whoever pushes this page) with `printing`'s [PdfPreview] widget, mirroring
/// `ReportPdfPreviewPage`'s own shape (TASK-148). Never re-encodes the
/// receipt itself — the bytes shown here already include the signature
/// image (when one exists) baked in.
class OrderReceiptPreviewPage extends StatelessWidget {
  const OrderReceiptPreviewPage({
    required this.bytes,
    required this.fileName,
    super.key,
  });

  final Uint8List bytes;
  final String fileName;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(fileName)),
    body: PdfPreview(
      key: const Key('order-receipt-preview'),
      build: (format) async => bytes,
      canChangeOrientation: false,
      canChangePageFormat: false,
      canDebug: false,
    ),
  );
}
