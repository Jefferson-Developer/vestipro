import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/customer_import_preview.dart';
import '../bloc/customer_import_bloc.dart';
import '../bloc/customer_import_event.dart';
import '../bloc/customer_import_state.dart';

/// Step 1 of the customer-import wizard (TASK-167): upload a CSV/XLSX file.
/// Only ever reads the picked file's bytes and forwards them to
/// [CustomerImportBloc] — parsing/validation happens entirely in the domain
/// layer, this widget has no business logic of its own.
class CustomerImportUploadStep extends StatelessWidget {
  const CustomerImportUploadStep({super.key});

  Future<void> _pickFile(BuildContext context) async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['csv', 'xlsx'],
    );
    if (files.isEmpty) return;
    final file = files.first;
    final bytes = await file.readAsBytes();
    if (!context.mounted) return;
    context.read<CustomerImportBloc>().add(
      CustomerImportFileSelected(fileName: file.name, bytes: bytes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocBuilder<CustomerImportBloc, CustomerImportState>(
      builder: (context, state) {
        final isParsing = state.fileStatus == CustomerImportFileStatus.parsing;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Envie a planilha de clientes (.csv ou .xlsx) que deseja '
              'importar para esta organização.',
              style: AppTypography.bodyMedium.copyWith(color: colors.outline),
            ),
            const SizedBox(height: AppSpacing.spacing8),
            Text(
              'Tamanho máximo: '
              '${(kCustomerImportMaxFileSizeBytes / (1024 * 1024)).toStringAsFixed(0)} MB. '
              'Para bases maiores, divida a planilha em partes.',
              style: AppTypography.bodySmall.copyWith(color: colors.outline),
            ),
            const SizedBox(height: AppSpacing.spacing24),
            DottedUploadArea(
              isLoading: isParsing,
              onTap: isParsing ? null : () => _pickFile(context),
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

/// A simple upload affordance following the same "outlined, dashed-looking
/// container with an icon and a primary action" shape the Design System's
/// `README.md` describes for upload/galeria components — kept local to this
/// feature since no second screen needs it yet (revisit and promote to
/// `lib/core/design_system` if a second upload flow appears).
class DottedUploadArea extends StatelessWidget {
  const DottedUploadArea({
    required this.onTap,
    this.isLoading = false,
    super.key,
  });

  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.radius12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.spacing32),
        decoration: BoxDecoration(
          border: Border.all(color: colors.outline.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(AppRadius.radius12),
          color: colors.surfaceContainer,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (isLoading)
              const CircularProgressIndicator()
            else
              Icon(
                Icons.upload_file_outlined,
                size: AppIconSizes.xl,
                color: colors.primary,
              ),
            const SizedBox(height: AppSpacing.spacing16),
            Text(
              isLoading ? 'Lendo arquivo...' : 'Selecionar arquivo',
              style: AppTypography.titleMedium.copyWith(
                color: colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
