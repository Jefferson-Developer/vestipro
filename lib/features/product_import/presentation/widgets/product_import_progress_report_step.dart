import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/product_import_job.dart';
import '../../domain/entities/product_import_row_report.dart';
import '../../domain/value_objects/product_import_job_status.dart';
import '../../domain/value_objects/product_import_row_outcome.dart';
import '../bloc/product_import_bloc.dart';
import '../bloc/product_import_event.dart';
import '../bloc/product_import_state.dart';

/// Step 3 of the product-import wizard (TASK-168): live progress of the
/// async job (via `WatchProductImportJobUseCase`'s Firestore stream) and,
/// once finished, the full per-row report plus the list of images that
/// matched no SKU/referência.
class ProductImportProgressReportStep extends StatelessWidget {
  const ProductImportProgressReportStep({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductImportBloc, ProductImportState>(
      builder: (context, state) {
        final job = state.job;
        if (job == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _JobStatusHeader(job: job),
            const SizedBox(height: AppSpacing.spacing24),
            if (job.status.isFinished)
              _ReportSection(job: job, state: state)
            else
              Text(
                'A importação continua em segundo plano — você pode sair '
                'desta tela e conferir o andamento depois pelo histórico de '
                'importações.',
                style: AppTypography.bodyMedium.copyWith(
                  color: context.colors.outline,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _JobStatusHeader extends StatelessWidget {
  const _JobStatusHeader({required this.job});

  final ProductImportJob job;

  AppStatusBadgeVariant get _variant => switch (job.status) {
    ProductImportJobStatus.queued => AppStatusBadgeVariant.neutral,
    ProductImportJobStatus.processing => AppStatusBadgeVariant.info,
    ProductImportJobStatus.completed => AppStatusBadgeVariant.success,
    ProductImportJobStatus.failed => AppStatusBadgeVariant.error,
  };

  String get _label => switch (job.status) {
    ProductImportJobStatus.queued => 'Na fila',
    ProductImportJobStatus.processing => 'Processando',
    ProductImportJobStatus.completed => 'Concluída',
    ProductImportJobStatus.failed => 'Falhou',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ratio = job.progressRatio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            AppStatusBadge(label: _label, variant: _variant),
            const SizedBox(width: AppSpacing.spacing12),
            Expanded(
              child: Text(
                job.fileName,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spacing12),
        LinearProgressIndicator(value: ratio),
        const SizedBox(height: AppSpacing.spacing8),
        Text(
          job.totalRows == null
              ? '${job.processedRows} linhas processadas'
              : '${job.processedRows} de ${job.totalRows} linhas processadas',
          style: AppTypography.bodySmall.copyWith(color: colors.outline),
        ),
        const SizedBox(height: AppSpacing.spacing16),
        Wrap(
          spacing: AppSpacing.spacing16,
          runSpacing: AppSpacing.spacing8,
          children: <Widget>[
            _CountChip(
              label: 'Produtos criados',
              count: job.createdProductsCount,
              variant: AppStatusBadgeVariant.success,
            ),
            _CountChip(
              label: 'Variantes criadas',
              count: job.createdVariantsCount,
              variant: AppStatusBadgeVariant.success,
            ),
            _CountChip(
              label: 'Imagens associadas',
              count: job.imagesAssociatedCount,
              variant: AppStatusBadgeVariant.info,
            ),
            _CountChip(
              label: 'Imagens órfãs',
              count: job.imagesOrphanCount,
              variant: AppStatusBadgeVariant.warning,
            ),
            _CountChip(
              label: 'Rejeitados',
              count: job.rejectedCount,
              variant: AppStatusBadgeVariant.error,
            ),
          ],
        ),
        if (job.errorMessage != null) ...<Widget>[
          const SizedBox(height: AppSpacing.spacing16),
          AppErrorState(
            title: 'A importação falhou',
            message: job.errorMessage!,
          ),
        ],
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.count,
    required this.variant,
  });

  final String label;
  final int count;
  final AppStatusBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    return AppStatusBadge(label: '$label: $count', variant: variant);
  }
}

class _ReportSection extends StatefulWidget {
  const _ReportSection({required this.job, required this.state});

  final ProductImportJob job;
  final ProductImportState state;

  @override
  State<_ReportSection> createState() => _ReportSectionState();
}

class _ReportSectionState extends State<_ReportSection> {
  @override
  void initState() {
    super.initState();
    if (widget.state.reportStatus == ProductImportReportStatus.idle) {
      context.read<ProductImportBloc>().add(
        const ProductImportReportRequested(),
      );
    }
  }

  String _outcomeLabel(ProductImportRowOutcome outcome) {
    return switch (outcome) {
      ProductImportRowOutcome.created => 'Criado',
      ProductImportRowOutcome.rejected => 'Rejeitado',
    };
  }

  AppStatusBadgeVariant _outcomeVariant(ProductImportRowOutcome outcome) {
    return switch (outcome) {
      ProductImportRowOutcome.created => AppStatusBadgeVariant.success,
      ProductImportRowOutcome.rejected => AppStatusBadgeVariant.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    if (state.reportStatus == ProductImportReportStatus.loading ||
        state.reportStatus == ProductImportReportStatus.idle) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.reportStatus == ProductImportReportStatus.failure) {
      return AppErrorState(
        title: 'Não foi possível carregar o relatório',
        message: state.reportFailure?.message ?? '',
        retryLabel: 'Tentar novamente',
        onRetry: () => context.read<ProductImportBloc>().add(
          const ProductImportReportRequested(),
        ),
      );
    }

    final report = state.report;
    if (report == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppDataTable<ProductImportRowReport>(
          rows: report.rows,
          rowIdBuilder: (row) => row.rowNumber,
          columns: <AppDataColumn<ProductImportRowReport>>[
            AppDataColumn<ProductImportRowReport>(
              label: 'Linha',
              cellBuilder: (context, row) => Text('${row.rowNumber}'),
            ),
            AppDataColumn<ProductImportRowReport>(
              label: 'SKU',
              cellBuilder: (context, row) => Text(row.sku ?? '-'),
            ),
            AppDataColumn<ProductImportRowReport>(
              label: 'Status',
              cellBuilder: (context, row) => AppStatusBadge(
                label: _outcomeLabel(row.outcome),
                variant: _outcomeVariant(row.outcome),
              ),
            ),
            AppDataColumn<ProductImportRowReport>(
              label: 'Motivo',
              cellBuilder: (context, row) => Text(row.reason ?? '-'),
            ),
            AppDataColumn<ProductImportRowReport>(
              label: 'Imagem',
              cellBuilder: (context, row) =>
                  Text(row.imageAssociated ? 'Associada' : '-'),
            ),
          ],
        ),
        if (report.orphanImageFileNames.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.spacing24),
          Text(
            'Imagens sem produto correspondente',
            style: AppTypography.titleMedium.copyWith(
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          Wrap(
            spacing: AppSpacing.spacing8,
            runSpacing: AppSpacing.spacing8,
            children: report.orphanImageFileNames
                .map(
                  (fileName) => AppStatusBadge(
                    label: fileName,
                    variant: AppStatusBadgeVariant.warning,
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}
