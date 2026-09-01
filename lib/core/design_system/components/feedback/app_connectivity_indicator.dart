import 'package:flutter/material.dart';

import '../../../connectivity/presentation/cubit/connectivity_indicator_state.dart';
import '../../../sync/domain/entities/outbox_summary.dart';
import '../badges/app_status_badge.dart';
import '../../foundations/foundations.dart';
import '../../theme/theme.dart';

/// Persistent, non-blocking connectivity banner for TASK-113.
class AppConnectivityIndicator extends StatelessWidget {
  const AppConnectivityIndicator({
    required this.status,
    required this.outboxSummary,
    this.onTap,
    super.key,
  });

  final ConnectivityIndicatorStatus status;
  final OutboxSummary outboxSummary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final copy = connectivityIndicatorCopyFor(status, outboxSummary);
    final foreground = switch (copy.variant) {
      AppStatusBadgeVariant.success => colors.success,
      AppStatusBadgeVariant.error => colors.error,
      AppStatusBadgeVariant.warning => colors.warning,
      AppStatusBadgeVariant.info => colors.info,
      AppStatusBadgeVariant.neutral => colors.onSurface,
    };
    final background = Color.alphaBlend(
      foreground.withValues(alpha: 0.14),
      colors.surfaceContainer,
    );

    return Material(
      color: background,
      child: SafeArea(
        bottom: false,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing16,
              vertical: AppSpacing.spacing8,
            ),
            child: Row(
              children: <Widget>[
                Icon(copy.icon, color: foreground, size: AppIconSizes.md),
                const SizedBox(width: AppSpacing.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        copy.label,
                        style: AppTypography.labelLarge.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spacing4),
                      Text(
                        copy.detail,
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.spacing8),
                Icon(
                  Icons.chevron_right,
                  color: colors.outline,
                  size: AppIconSizes.md,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

typedef ConnectivityIndicatorCopy = ({
  String label,
  String detail,
  AppStatusBadgeVariant variant,
  IconData icon,
});

ConnectivityIndicatorCopy connectivityIndicatorCopyFor(
  ConnectivityIndicatorStatus status,
  OutboxSummary outboxSummary,
) {
  final unsyncedCount = outboxSummary.totalUnsyncedCount;

  return switch (status) {
    ConnectivityIndicatorStatus.onlineSynced => (
      label: 'Online e sincronizado',
      detail: 'Nenhuma pendência aguardando envio.',
      variant: AppStatusBadgeVariant.success,
      icon: Icons.cloud_done_outlined,
    ),
    ConnectivityIndicatorStatus.onlineSyncing => (
      label: 'Online, sincronizando',
      detail: _pendingDetail(unsyncedCount, isOnline: true),
      variant: AppStatusBadgeVariant.info,
      icon: Icons.sync_outlined,
    ),
    ConnectivityIndicatorStatus.offlinePending => (
      label: 'Offline com pendências',
      detail: _pendingDetail(unsyncedCount, isOnline: false),
      variant: AppStatusBadgeVariant.warning,
      icon: Icons.cloud_off_outlined,
    ),
    ConnectivityIndicatorStatus.offlineNoPending => (
      label: 'Offline',
      detail: 'Sem pendências no momento. Novas ações ficam locais.',
      variant: AppStatusBadgeVariant.warning,
      icon: Icons.wifi_off_outlined,
    ),
  };
}

String _pendingDetail(int unsyncedCount, {required bool isOnline}) {
  final noun = unsyncedCount == 1 ? 'pendência' : 'pendências';
  final tail = switch ((isOnline, unsyncedCount == 1)) {
    (true, _) => 'aguardando sincronização.',
    (false, true) => 'salva localmente até a conexão voltar.',
    (false, false) => 'salvas localmente até a conexão voltar.',
  };
  return '$unsyncedCount $noun $tail';
}
