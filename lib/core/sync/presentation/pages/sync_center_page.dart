import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../design_system/design_system.dart';
import '../../../offline/domain/entities/offline_package_entity_status.dart';
import '../cubit/sync_center_cubit.dart';
import '../cubit/sync_center_state.dart';
import '../presenters/sync_center_presenter.dart';
import '../widgets/outbox_failed_item_card.dart';

/// Central de Sincronização (TASK-112, EPIC-14 — seção 5.4 de `tasks.md`):
/// full transparency over the on-device offline state — última
/// sincronização, pendências da Outbox (TASK-108), falhas com retry manual
/// (TASK-109) e o atalho para os conflitos abertos (TASK-110/TASK-111) — for
/// one `organizationId`/`companyId` scope.
class SyncCenterPage extends StatelessWidget {
  const SyncCenterPage({
    required this.organizationId,
    required this.companyId,
    required this.createCubit,
    required this.onOpenConflicts,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final SyncCenterCubit Function() createCubit;

  /// Called when the user taps the open-conflicts shortcut — the host wires
  /// this to `ConflictListRoute`.
  final VoidCallback onOpenConflicts;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SyncCenterCubit>(
      create: (_) {
        final cubit = createCubit();
        unawaited(
          cubit.load(organizationId: organizationId, companyId: companyId),
        );
        return cubit;
      },
      child: SyncCenterView(onOpenConflicts: onOpenConflicts),
    );
  }
}

@visibleForTesting
class SyncCenterView extends StatelessWidget {
  const SyncCenterView({required this.onOpenConflicts, super.key});

  final VoidCallback onOpenConflicts;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Central de sincronização'),
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
      ),
      body: BlocConsumer<SyncCenterCubit, SyncCenterState>(
        listenWhen: (previous, current) =>
            previous.lastManualCycleAt != current.lastManualCycleAt &&
            current.lastManualCycleAt != null,
        listener: (context, state) {
          final report = state.lastManualCycleReport;
          if (report == null) return;
          final hasIssues = report.push.failed > 0 || report.push.conflicts > 0;
          AppSnackbar.show(
            context,
            message: hasIssues
                ? 'Sincronização concluída com pendências. Veja os detalhes '
                      'abaixo.'
                : 'Sincronização concluída com sucesso.',
            variant: hasIssues
                ? AppSnackbarVariant.warning
                : AppSnackbarVariant.success,
          );
        },
        builder: (context, state) {
          if (state.isInitialLoading) {
            return _buildLoading();
          }

          if (state.loadStatus == SyncCenterLoadStatus.failure) {
            return AppErrorState(
              title: 'Não foi possível carregar a central de sincronização',
              message:
                  state.failure?.message ??
                  'Ocorreu um erro inesperado ao carregar os dados de '
                      'sincronização.',
              retryLabel: 'Tentar novamente',
              onRetry: () => context.read<SyncCenterCubit>().refresh(),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<SyncCenterCubit>().refresh(),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.spacing16),
              children: <Widget>[
                if (!state.isOnline) ...<Widget>[
                  const _OfflineBanner(),
                  const SizedBox(height: AppSpacing.spacing16),
                ],
                _SummaryCard(state: state),
                if (state.hasConflicts) ...<Widget>[
                  const SizedBox(height: AppSpacing.spacing16),
                  _ConflictsBanner(
                    count: state.openConflictCount,
                    onTap: onOpenConflicts,
                  ),
                ],
                const SizedBox(height: AppSpacing.spacing16),
                _EntityStatusesSection(entityStatuses: state.entityStatuses),
                if (state.hasFailures) ...<Widget>[
                  const SizedBox(height: AppSpacing.spacing16),
                  _FailedItemsSection(state: state),
                ] else if (state.isFullySynced) ...<Widget>[
                  const SizedBox(height: AppSpacing.spacing32),
                  const AppEmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'Tudo sincronizado',
                    description:
                        'Todas as alterações feitas neste dispositivo já '
                        'foram enviadas e confirmadas pelo servidor.',
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      children: List<Widget>.generate(
        3,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.spacing12),
          child: AppSkeleton.card(),
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colors.warning.withValues(alpha: 0.12),
          colors.surface,
        ),
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        border: Border.all(color: colors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.cloud_off, color: colors.warning),
          const SizedBox(width: AppSpacing.spacing12),
          Expanded(
            child: Text(
              'Você está offline. Nenhuma tentativa de sincronização será '
              'feita até que a conexão seja restabelecida — suas alterações '
              'continuam salvas neste dispositivo.',
              style: AppTypography.bodyMedium.copyWith(color: colors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state});

  final SyncCenterState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lastFullSyncAt = state.lastFullSyncAt;
    final summary = state.outboxSummary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            lastFullSyncAt == null
                ? 'Nenhuma sincronização completa registrada ainda'
                : 'Última sincronização em '
                      '${syncDateTimeLabel(lastFullSyncAt)}',
            style: AppTypography.titleMedium.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.spacing12),
          Wrap(
            spacing: AppSpacing.spacing8,
            runSpacing: AppSpacing.spacing8,
            children: <Widget>[
              _summaryBadge(
                'Pendentes',
                summary.pendingCount,
                AppStatusBadgeVariant.info,
              ),
              _summaryBadge(
                'Sincronizando',
                summary.syncingCount,
                AppStatusBadgeVariant.info,
              ),
              _summaryBadge(
                'Falharam',
                summary.failedCount,
                AppStatusBadgeVariant.error,
              ),
              _summaryBadge(
                'Conflitos',
                summary.conflictCount,
                AppStatusBadgeVariant.warning,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppButton(
            label: 'Sincronizar agora',
            leadingIcon: Icons.sync,
            isLoading: state.isSyncing,
            isDisabled: !state.isOnline,
            onPressed: () => context.read<SyncCenterCubit>().syncNow(),
          ),
        ],
      ),
    );
  }

  Widget _summaryBadge(String label, int count, AppStatusBadgeVariant variant) {
    return AppStatusBadge(label: '$label: $count', variant: variant);
  }
}

class _ConflictsBanner extends StatelessWidget {
  const _ConflictsBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = count == 1
        ? '1 conflito de sincronização precisa da sua decisão'
        : '$count conflitos de sincronização precisam da sua decisão';

    return Card(
      color: colors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        side: BorderSide(color: colors.error.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          child: Row(
            children: <Widget>[
              Icon(Icons.priority_high, color: colors.error),
              const SizedBox(width: AppSpacing.spacing12),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: colors.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntityStatusesSection extends StatelessWidget {
  const _EntityStatusesSection({required this.entityStatuses});

  final List<OfflinePackageEntityStatus> entityStatuses;

  @override
  Widget build(BuildContext context) {
    if (entityStatuses.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Última carga completa por dado',
            style: AppTypography.labelLarge.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.spacing12),
          for (final status in entityStatuses)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      offlinePackageEntityKindLabel(status.kind),
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    status.isComplete && status.lastCompletedAt != null
                        ? syncDateTimeLabel(status.lastCompletedAt!)
                        : 'Não disponível ainda',
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.outline,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FailedItemsSection extends StatelessWidget {
  const _FailedItemsSection({required this.state});

  final SyncCenterState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final retryEnabled = state.isOnline && !state.isSyncing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Itens com falha',
                style: AppTypography.labelLarge.copyWith(
                  color: colors.onSurface,
                ),
              ),
            ),
            AppButton(
              label: 'Tentar novamente todos',
              variant: AppButtonVariant.text,
              isLoading: state.isSyncing,
              isDisabled: !retryEnabled,
              onPressed: () => context.read<SyncCenterCubit>().retryAllFailed(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spacing8),
        for (final operation in state.failedOperations)
          OutboxFailedItemCard(
            operation: operation,
            isRetrying: state.retryingOperationIds.contains(operation.id),
            isRetryEnabled:
                retryEnabled &&
                !state.retryingOperationIds.contains(operation.id),
            onRetry: () =>
                context.read<SyncCenterCubit>().retryOperation(operation.id),
          ),
      ],
    );
  }
}
