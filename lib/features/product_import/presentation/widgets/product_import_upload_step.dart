import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/product_import_preview.dart';
import '../bloc/product_import_bloc.dart';
import '../bloc/product_import_event.dart';
import '../bloc/product_import_state.dart';

/// Step 1 of the product-import wizard (TASK-168): upload a CSV/XLSX file
/// with one row per product+color+size variant. Only ever reads the picked
/// file's bytes and forwards them to [ProductImportBloc] — parsing/
/// validation happens entirely in the domain layer.
class ProductImportUploadStep extends StatelessWidget {
  const ProductImportUploadStep({super.key});

  Future<void> _pickFile(BuildContext context) async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['csv', 'xlsx'],
    );
    if (files.isEmpty) return;
    final file = files.first;
    final bytes = await file.readAsBytes();
    if (!context.mounted) return;
    context.read<ProductImportBloc>().add(
      ProductImportFileSelected(fileName: file.name, bytes: bytes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocBuilder<ProductImportBloc, ProductImportState>(
      builder: (context, state) {
        final isParsing = state.fileStatus == ProductImportFileStatus.parsing;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Envie a planilha de produtos (.csv ou .xlsx) com uma linha '
              'por variante (produto + cor + tamanho).',
              style: AppTypography.bodyMedium.copyWith(color: colors.outline),
            ),
            const SizedBox(height: AppSpacing.spacing8),
            Text(
              'Tamanho máximo: '
              '${(kProductImportMaxFileSizeBytes / (1024 * 1024)).toStringAsFixed(0)} MB. '
              'O pacote de imagens (opcional) é enviado na próxima etapa.',
              style: AppTypography.bodySmall.copyWith(color: colors.outline),
            ),
            const SizedBox(height: AppSpacing.spacing24),
            InkWell(
              onTap: isParsing ? null : () => _pickFile(context),
              borderRadius: BorderRadius.circular(AppRadius.radius12),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.spacing32),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colors.outline.withValues(alpha: 0.4),
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.radius12),
                  color: colors.surfaceContainer,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (isParsing)
                      const CircularProgressIndicator()
                    else
                      Icon(
                        Icons.upload_file_outlined,
                        size: AppIconSizes.xl,
                        color: colors.primary,
                      ),
                    const SizedBox(height: AppSpacing.spacing16),
                    Text(
                      isParsing ? 'Lendo arquivo...' : 'Selecionar arquivo',
                      style: AppTypography.titleMedium.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (state.fileFailure != null) ...<Widget>[
              const SizedBox(height: AppSpacing.spacing16),
              AppErrorState(
                title: 'Não foi possível ler o arquivo',
                message: state.fileFailure!.message,
              ),
            ],
          ],
        );
      },
    );
  }
}
