import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/customer_import_job.dart';
import '../../domain/entities/customer_import_row_report.dart';
import '../../domain/value_objects/customer_import_duplicate_resolution.dart';
import '../../domain/value_objects/customer_import_job_status.dart';
import '../../domain/value_objects/customer_import_row_outcome.dart';
import '../bloc/customer_import_bloc.dart';
import '../bloc/customer_import_event.dart';
import '../bloc/customer_import_state.dart';

/// Step 3 of the customer-import wizard (TASK-167): live progress of the
/// async job (via `WatchCustomerImportJobUseCase`'s Firestore stream) and,
/// once finished, the full per-row report with the gestor's
/// merge/ignore/create-anyway decision for each pending duplicate.
class CustomerImportProgressReportStep extends StatelessWidget {
  const CustomerImportProgressReportStep({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerImportBloc, CustomerImportState>(
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

  final CustomerImportJob job;

  AppStatusBadgeVariant get _variant => switch (job.status) {
    CustomerImportJobStatus.queued => AppStatusBadgeVariant.neutral,
    CustomerImportJobStatus.processing => AppStatusBadgeVariant.info,
    CustomerImportJobStatus.completed => AppStatusBadgeVariant.success,
    CustomerImportJobStatus.failed => AppStatusBadgeVariant.error,
  };

  String get _label => switch (job.status) {
    CustomerImportJobStatus.queued => 'Na fila',
    CustomerImportJobStatus.processing => 'Processando',
    CustomerImportJobStatus.completed => 'Concluída',
    CustomerImportJobStatus.failed => 'Falhou',
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
              label: 'Importados',
              count: job.importedCount,
              variant: AppStatusBadgeVariant.success,
            ),
            _CountChip(
              label: 'Rejeitados',
              count: job.rejectedCount,
              variant: AppStatusBadgeVariant.error,
            ),
            _CountChip(
              label: 'Duplicados',
              count: job.duplicateCount,
              variant: AppStatusBadgeVariant.warning,
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

  final CustomerImportJob job;
  final CustomerImportState state;

  @override
  State<_ReportSection> createState() => _ReportSectionState();
}

class _ReportSectionState extends State<_ReportSection> {
  @override
  void initState() {
    super.initState();
    if (widget.state.reportStatus == CustomerImportReportStatus.idle) {
      context.read<CustomerImportBloc>().add(
        const CustomerImportReportRequested(),
      );
    }
  }

  String _outcomeLabel(CustomerImportRowOutcome outcome) {
    return switch (outcome) {
      CustomerImportRowOutcome.imported => 'Importado',
      CustomerImportRowOutcome.rejected => 'Rejeitado',
      CustomerImportRowOutcome.duplicateInFile => 'Duplicado no arquivo',
      CustomerImportRowOutcome.duplicateExisting => 'Já existe na base',
    };
  }

  AppStatusBadgeVariant _outcomeVariant(CustomerImportRowOutcome outcome) {
    return switch (outcome) {
      CustomerImportRowOutcome.imported => AppStatusBadgeVariant.success,
      CustomerImportRowOutcome.rejected => AppStatusBadgeVariant.error,
      CustomerImportRowOutcome.duplicateInFile ||
      CustomerImportRowOutcome.duplicateExisting =>
        AppStatusBadgeVariant.warning,
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    if (state.reportStatus == CustomerImportReportStatus.loading ||
        state.reportStatus == CustomerImportReportStatus.idle) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.reportStatus == CustomerImportReportStatus.failure) {
      return AppErrorState(
        title: 'Não foi possível carregar o relatório',
        message: state.reportFailure?.message ?? '',
        retryLabel: 'Tentar novamente',
        onRetry: () => context.read<CustomerImportBloc>().add(
          const CustomerImportReportRequested(),
        ),
      );
    }

    final report = state.report;
    if (report == null) return const SizedBox.shrink();

    return AppDataTable<CustomerImportRowReport>(
      rows: report.rows,
      rowIdBuilder: (row) => row.rowNumber,
      columns: <AppDataColumn<CustomerImportRowReport>>[
        AppDataColumn<CustomerImportRowReport>(
          label: 'Linha',
          cellBuilder: (context, row) => Text('${row.rowNumber}'),
        ),
        AppDataColumn<CustomerImportRowReport>(
          label: 'Status',
          cellBuilder: (context, row) => AppStatusBadge(
            label: _outcomeLabel(row.outcome),
            variant: _outcomeVariant(row.outcome),
          ),
        ),
        AppDataColumn<CustomerImportRowReport>(
          label: 'Motivo',
          cellBuilder: (context, row) => Text(row.reason ?? '-'),
        ),
        AppDataColumn<CustomerImportRowReport>(
          label: 'Ação',
          cellBuilder: (context, row) =>
              row.outcome == CustomerImportRowOutcome.duplicateExisting &&
                  row.resolution == null
              ? _DuplicateActions(row: row)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _DuplicateActions extends StatelessWidget {
  const _DuplicateActions({required this.row});

  final CustomerImportRowReport row;

  void _resolve(
    BuildContext context,
    CustomerImportDuplicateResolution resolution,
  ) {
    context.read<CustomerImportBloc>().add(
      CustomerImportDuplicateResolved(
        rowNumber: row.rowNumber,
        resolution: resolution,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.spacing4,
      children: <Widget>[
        AppButton(
          label: 'Ignorar',
          variant: AppButtonVariant.text,
          onPressed: () =>
              _resolve(context, CustomerImportDuplicateResolution.ignore),
        ),
        AppButton(
          label: 'Mesclar',
          variant: AppButtonVariant.text,
          onPressed: () =>
              _resolve(context, CustomerImportDuplicateResolution.merge),
        ),
        if (row.matchedByEmailOnly)
          AppButton(
            label: 'Criar mesmo assim',
            variant: AppButtonVariant.text,
            onPressed: () => _resolve(
              context,
              CustomerImportDuplicateResolution.createAnyway,
            ),
          ),
      ],
    );
  }
}
