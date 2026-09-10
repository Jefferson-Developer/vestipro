import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/admin_portal_models.dart';
import '../cubit/admin_portal_cubit.dart';
import '../cubit/admin_portal_state.dart';

class AdminPortalPage extends StatefulWidget {
  const AdminPortalPage({super.key, required this.createCubit});

  final AdminPortalCubit Function() createCubit;

  @override
  State<AdminPortalPage> createState() => _AdminPortalPageState();
}

class _AdminPortalPageState extends State<AdminPortalPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminPortalCubit>(
      create: (_) {
        final cubit = widget.createCubit();
        unawaited(cubit.loadSession());
        return cubit;
      },
      child: BlocBuilder<AdminPortalCubit, AdminPortalState>(
        builder: (context, state) {
          if (state.status == AdminPortalStatus.loadingSession) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (state.status == AdminPortalStatus.denied) {
            return const Scaffold(
              body: AppEmptyState(
                icon: Icons.lock_outline,
                title: 'Acesso interno restrito',
                description:
                    'Esta area e exclusiva para operadores VestiPro autorizados.',
              ),
            );
          }

          return const Scaffold(
            body: AppAdminPageLayout(
              title: 'Portal administrativo VestiPro',
              filtersTitle: 'Escopo de suporte',
              filtersBuilder: _buildSupportScopePanel,
              content: _AdminPortalContent(),
            ),
          );
        },
      ),
    );
  }
}

Widget _buildSupportScopePanel(BuildContext context) {
  return const _SupportScopePanel();
}

class _SupportScopePanel extends StatelessWidget {
  const _SupportScopePanel();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdminPortalCubit>();
    final state = context.watch<AdminPortalCubit>().state;
    final colors = context.colors;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Justificativa',
            style: AppTypography.titleMedium.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          AppTextField(
            maxLines: 5,
            onChanged: cubit.updateReason,
            label: 'Motivo ou ticket',
            hintText: 'Ex.: SUP-4821 investigacao de sync',
            isRequired: true,
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppTextField(
            onChanged: cubit.updateTicketId,
            label: 'Ticket de suporte',
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppTextField(onChanged: cubit.updateTargetUserId, label: 'Usuario'),
          const SizedBox(height: AppSpacing.spacing16),
          AppTextField(onChanged: cubit.updateDeviceId, label: 'Dispositivo'),
          const SizedBox(height: AppSpacing.spacing16),
          AppTextField(
            onChanged: cubit.updateOutboxItemId,
            label: 'Item da Outbox',
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppStatusBadge(
            label: state.canViewSensitiveData
                ? 'Detalhes sensiveis liberados'
                : 'Detalhes sensiveis bloqueados',
            variant: state.canViewSensitiveData
                ? AppStatusBadgeVariant.success
                : AppStatusBadgeVariant.warning,
          ),
        ],
      ),
    );
  }
}

class _AdminPortalContent extends StatelessWidget {
  const _AdminPortalContent();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AdminPortalCubit>().state;
    final cubit = context.read<AdminPortalCubit>();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppSearchField(
            hintText: 'Buscar organizacao por nome ou ID',
            isSearching: state.status == AdminPortalStatus.searching,
            onSearch: cubit.search,
          ),
          const SizedBox(height: AppSpacing.spacing16),
          if (state.failure != null)
            _MessageBanner(
              icon: Icons.error_outline,
              message: state.failure!.message,
              isError: true,
            ),
          if (state.actionResult != null)
            _MessageBanner(
              icon: Icons.check_circle_outline,
              message: state.actionResult!.message,
            ),
          const SizedBox(height: AppSpacing.spacing8),
          _OrganizationResults(
            organizations: state.organizations,
            selected: state.selectedOrganization,
            isBusy: state.isBusy,
            onSelected: cubit.selectOrganization,
          ),
          const SizedBox(height: AppSpacing.spacing16),
          if (state.selectedOrganization != null)
            _DiagnosticsPanel(
              organization: state.selectedOrganization!,
              report: state.diagnosticReport,
              isLoading: state.status == AdminPortalStatus.loadingDiagnostic,
              isReprocessing: state.status == AdminPortalStatus.reprocessing,
              canViewSensitiveData: state.canViewSensitiveData,
              canReprocessOutbox: state.canReprocessOutbox,
              onLoadDiagnostic: cubit.loadDiagnostic,
              onReprocessOutbox: cubit.reprocessOutbox,
            ),
        ],
      ),
    );
  }
}

class _OrganizationResults extends StatelessWidget {
  const _OrganizationResults({
    required this.organizations,
    required this.selected,
    required this.isBusy,
    required this.onSelected,
  });

  final List<AdminOrganizationSummary> organizations;
  final AdminOrganizationSummary? selected;
  final bool isBusy;
  final ValueChanged<AdminOrganizationSummary> onSelected;

  @override
  Widget build(BuildContext context) {
    if (organizations.isEmpty && !isBusy) {
      return const AppEmptyState(
        icon: Icons.manage_search,
        title: 'Nenhuma organizacao carregada',
        description: 'Informe a justificativa e busque uma organizacao.',
      );
    }

    return Wrap(
      spacing: AppSpacing.spacing12,
      runSpacing: AppSpacing.spacing12,
      children: organizations
          .map(
            (organization) => _OrganizationCard(
              organization: organization,
              isSelected:
                  organization.organizationId == selected?.organizationId,
              onTap: () => onSelected(organization),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _OrganizationCard extends StatelessWidget {
  const _OrganizationCard({
    required this.organization,
    required this.isSelected,
    required this.onTap,
  });

  final AdminOrganizationSummary organization;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 320,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: isSelected ? colors.primary : colors.outline),
          borderRadius: BorderRadius.circular(AppRadius.radius8),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.radius8),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        organization.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    _HealthBadge(status: organization.healthStatus),
                  ],
                ),
                const SizedBox(height: AppSpacing.spacing12),
                _MetricRow(
                  label: 'Usuarios ativos',
                  value: organization.activeUsers.toString(),
                ),
                _MetricRow(
                  label: 'Erros de sync',
                  value: organization.syncErrors.toString(),
                ),
                _MetricRow(
                  label: 'Pedidos 30d',
                  value: organization.orderVolumeLast30Days.toString(),
                ),
                _MetricRow(
                  label: 'Tickets abertos',
                  value: organization.openTickets.toString(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiagnosticsPanel extends StatelessWidget {
  const _DiagnosticsPanel({
    required this.organization,
    required this.report,
    required this.isLoading,
    required this.isReprocessing,
    required this.canViewSensitiveData,
    required this.canReprocessOutbox,
    required this.onLoadDiagnostic,
    required this.onReprocessOutbox,
  });

  final AdminOrganizationSummary organization;
  final AdminPortalDiagnosticReport? report;
  final bool isLoading;
  final bool isReprocessing;
  final bool canViewSensitiveData;
  final bool canReprocessOutbox;
  final VoidCallback onLoadDiagnostic;
  final VoidCallback onReprocessOutbox;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Diagnostico de ${organization.displayName}',
              style: AppTypography.titleMedium.copyWith(
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing12),
            Wrap(
              spacing: AppSpacing.spacing12,
              runSpacing: AppSpacing.spacing12,
              children: <Widget>[
                AppButton(
                  label: 'Consultar sync',
                  leadingIcon: Icons.sync,
                  isLoading: isLoading,
                  isDisabled: !canViewSensitiveData,
                  onPressed: canViewSensitiveData ? onLoadDiagnostic : null,
                ),
                AppButton(
                  label: 'Reprocessar Outbox',
                  leadingIcon: Icons.replay,
                  variant: AppButtonVariant.secondary,
                  isLoading: isReprocessing,
                  isDisabled: !canReprocessOutbox,
                  onPressed: canReprocessOutbox ? onReprocessOutbox : null,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.spacing16),
            if (report == null)
              const Text(
                'Os detalhes tecnicos aparecem somente depois da justificativa auditada.',
              )
            else ...<Widget>[
              _MetricRow(label: 'Status', value: report!.syncStatus),
              _MetricRow(
                label: 'Outbox pendente',
                value: report!.pendingOutboxItems.toString(),
              ),
              _MetricRow(
                label: 'Outbox com falha',
                value: report!.failedOutboxItems.toString(),
              ),
              const SizedBox(height: AppSpacing.spacing12),
              Text(
                'Logs tecnicos',
                style: AppTypography.titleMedium.copyWith(
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing8),
              ...report!.technicalLogs.map(_TechnicalLogTile.new),
            ],
          ],
        ),
      ),
    );
  }
}

class _TechnicalLogTile extends StatelessWidget {
  const _TechnicalLogTile(this.log);

  final AdminPortalTechnicalLog log;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _LogLevelIcon(level: log.level),
      title: Text(
        log.message,
        style: AppTypography.bodyMedium.copyWith(color: colors.onSurface),
      ),
      subtitle: Text(
        log.correlationId ?? log.id,
        style: AppTypography.bodySmall.copyWith(color: colors.outline),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(color: colors.outline),
            ),
          ),
          Text(
            value,
            style: AppTypography.labelLarge.copyWith(color: colors.onSurface),
          ),
        ],
      ),
    );
  }
}

class _HealthBadge extends StatelessWidget {
  const _HealthBadge({required this.status});

  final AdminPortalHealthStatus status;

  @override
  Widget build(BuildContext context) {
    return AppStatusBadge(
      label: switch (status) {
        AdminPortalHealthStatus.healthy => 'Saudavel',
        AdminPortalHealthStatus.warning => 'Atencao',
        AdminPortalHealthStatus.critical => 'Critico',
      },
      variant: switch (status) {
        AdminPortalHealthStatus.healthy => AppStatusBadgeVariant.success,
        AdminPortalHealthStatus.warning => AppStatusBadgeVariant.warning,
        AdminPortalHealthStatus.critical => AppStatusBadgeVariant.error,
      },
    );
  }
}

class _LogLevelIcon extends StatelessWidget {
  const _LogLevelIcon({required this.level});

  final AdminPortalLogLevel level;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = switch (level) {
      AdminPortalLogLevel.info => colors.info,
      AdminPortalLogLevel.warning => colors.warning,
      AdminPortalLogLevel.error => colors.error,
    };
    return Icon(Icons.terminal, color: color);
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.icon,
    required this.message,
    this.isError = false,
  });

  final IconData icon;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = isError ? colors.error : colors.success;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacing12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            foreground.withValues(alpha: 0.12),
            colors.surface,
          ),
          borderRadius: BorderRadius.circular(AppRadius.radius8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing12),
          child: Row(
            children: <Widget>[
              Icon(icon, color: foreground),
              const SizedBox(width: AppSpacing.spacing8),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
