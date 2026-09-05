import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';

import '../../domain/entities/report_export_result.dart';
import '../bloc/report_builder_bloc.dart';
import '../bloc/report_builder_event.dart';

/// Pré-visualização screen for a PDF report export (TASK-148) — shown after
/// `ReportPdfPreviewRequested` produces a [LocalReportPdfPreview]. Renders
/// the already-encoded bytes with `printing`'s [PdfPreview] widget (no
/// print/share affordances of its own: this screen only ever offers
/// "Cancelar" or "Exportar", per TASK-148's own acceptance criteria) and
/// never re-encodes the report itself — confirming dispatches
/// [ReportPdfExportConfirmed], which persists the *same* bytes already
/// shown here.
class ReportPdfPreviewPage extends StatelessWidget {
  const ReportPdfPreviewPage({required this.preview, super.key});

  final LocalReportPdfPreview preview;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Pré-visualização — ${preview.fileName}'),
      actions: [
        TextButton(
          key: const Key('pdf-preview-cancel'),
          onPressed: () => _cancel(context),
          child: const Text('Cancelar'),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FilledButton.icon(
            key: const Key('pdf-preview-confirm'),
            onPressed: () => _confirm(context),
            icon: const Icon(Icons.download_outlined),
            label: const Text('Exportar'),
          ),
        ),
      ],
    ),
    body: PdfPreview(
      key: const Key('report-pdf-preview'),
      build: (format) async => Uint8List.fromList(preview.bytes),
      allowPrinting: false,
      allowSharing: false,
      canChangeOrientation: false,
      canChangePageFormat: false,
      canDebug: false,
      useActions: false,
    ),
  );

  void _cancel(BuildContext context) {
    context.read<ReportBuilderBloc>().add(const ReportPdfPreviewCancelled());
    Navigator.of(context).pop();
  }

  void _confirm(BuildContext context) {
    context.read<ReportBuilderBloc>().add(const ReportPdfExportConfirmed());
    Navigator.of(context).pop();
  }
}
