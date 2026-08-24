import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_list_filters.dart';
import '../../domain/value_objects/lead_source.dart';
import '../../domain/value_objects/lead_status.dart';
import '../bloc/lead_list_bloc.dart';
import '../bloc/lead_list_event.dart';
import '../bloc/lead_list_state.dart';

/// Lead listing page (TASK-056): combinable origin/status/responsible
/// filters, debounced search, cursor pagination and the qualify/disqualify
/// contextual action, gated by [Capability.leadView].
///
/// Whether the qualify/disqualify buttons render at all is resolved once,
/// up front, from [Capability.leadQualify] — the same "UI only
/// shows/enables, never authorizes" contract every other RBAC gate in
/// VestiPro follows (`PermissionBuilder` docs): `QualifyLeadUseCase`/
/// `DisqualifyLeadUseCase` and their future Cloud Function/Security Rule
/// (TASK-030) re-validate the same decision independently.
class LeadListPage extends StatelessWidget {
  const LeadListPage({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    this.companyId,
    this.initialSearchQuery = '',
    this.initialFilters = LeadListFilters.empty,
    this.onCreateLead,
    super.key,
  });

  final String organizationId;
  final String? companyId;
  final String userId;
  final PermissionService permissionService;
  final LeadListBloc Function() createBloc;
  final String initialSearchQuery;
  final LeadListFilters initialFilters;

  /// Called when the caller taps "Novo lead". `null` hides the action
  /// entirely, even when [Capability.leadCreate] is granted, so a host that
  /// has not wired lead creation yet never shows a dead button.
  final VoidCallback? onCreateLead;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.leadView,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return _LeadListActionsGate(
          organizationId: organizationId,
          userId: userId,
          permissionService: permissionService,
          createBloc: createBloc,
          companyId: companyId,
          initialSearchQuery: initialSearchQuery,
          initialFilters: initialFilters,
          onCreateLead: onCreateLead,
        );
      },
    );
  }
}

class _LeadListActionsGate extends StatefulWidget {
  const _LeadListActionsGate({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    this.companyId,
    required this.initialSearchQuery,
    required this.initialFilters,
    this.onCreateLead,
  });

  final String organizationId;
  final String? companyId;
  final String userId;
  final PermissionService permissionService;
  final LeadListBloc Function() createBloc;
  final String initialSearchQuery;
  final LeadListFilters initialFilters;
  final VoidCallback? onCreateLead;

  @override
  State<_LeadListActionsGate> createState() => _LeadListActionsGateState();
}

class _LeadListActionsGateState extends State<_LeadListActionsGate> {
  late final Future<_LeadListPermissions> _permissions;

  @override
  void initState() {
    super.initState();
    _permissions = _resolvePermissions();
  }

  Future<_LeadListPermissions> _resolvePermissions() async {
    final results = await Future.wait<bool>(<Future<bool>>[
      _hasCapability(Capability.leadQualify),
      _hasCapability(Capability.leadCreate),
    ]);
    return _LeadListPermissions(canQualify: results[0], canCreate: results[1]);
  }

  Future<bool> _hasCapability(Capability capability) {
    return widget.permissionService
        .hasPermission(
          organizationId: widget.organizationId,
          userId: widget.userId,
          capability: capability,
        )
        .then(
          (result) => result.fold(
            onSuccess: (granted) => granted,
            onFailure: (_) => false,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_LeadListPermissions>(
      future: _permissions,
      builder: (context, snapshot) {
        final permissions = snapshot.data ?? const _LeadListPermissions();
        return BlocProvider<LeadListBloc>(
          create: (_) => widget.createBloc()
            ..add(
              LeadListStarted(
                organizationId: widget.organizationId,
                companyId: widget.companyId,
                userId: widget.userId,
                searchQuery: widget.initialSearchQuery,
                filters: widget.initialFilters,
              ),
            ),
          child: _LeadListScaffold(
            canQualify: permissions.canQualify,
            showCreateAction:
                permissions.canCreate && widget.onCreateLead != null,
            onCreateLead: widget.onCreateLead,
          ),
        );
      },
    );
  }
}

class _LeadListPermissions {
  const _LeadListPermissions({this.canQualify = false, this.canCreate = false});

  final bool canQualify;
  final bool canCreate;
}

class _LeadListScaffold extends StatelessWidget {
  const _LeadListScaffold({
    required this.canQualify,
    required this.showCreateAction,
    this.onCreateLead,
  });

  final bool canQualify;
  final bool showCreateAction;
  final VoidCallback? onCreateLead;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeadListBloc, LeadListState>(
      builder: (context, state) {
        return Scaffold(
          body: AppAdminPageLayout(
            title: 'Leads',
            actions: <Widget>[
              if (showCreateAction)
                AppButton(
                  label: 'Novo lead',
                  leadingIcon: Icons.person_add_alt_1_outlined,
                  onPressed: onCreateLead,
                ),
            ],
            filtersTitle: 'Filtros de leads',
            filtersBuilder: (_) => _LeadFilters(state: state),
            content: _LeadListContent(state: state, canQualify: canQualify),
          ),
        );
      },
    );
  }
}

class _LeadListContent extends StatefulWidget {
  const _LeadListContent({required this.state, required this.canQualify});

  final LeadListState state;
  final bool canQualify;

  @override
  State<_LeadListContent> createState() => _LeadListContentState();
}

class _LeadListContentState extends State<_LeadListContent> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_requestNextPageNearEnd);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_requestNextPageNearEnd)
      ..dispose();
    super.dispose();
  }

  void _requestNextPageNearEnd() {
    if (_scrollController.position.extentAfter < 420) {
      context.read<LeadListBloc>().add(const LeadListNextPageRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeadListBloc, LeadListState>(
      listenWhen: (previous, current) =>
          previous.actionStatus != current.actionStatus &&
          current.actionStatus == LeadListActionStatus.failure,
      listener: (context, state) {
        AppSnackbar.show(
          context,
          message:
              state.actionFailure?.message ??
              'Nao foi possivel atualizar o lead.',
          variant: AppSnackbarVariant.error,
        );
        context.read<LeadListBloc>().add(const LeadListActionDismissed());
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final state = widget.state;
    if (state.status == LeadListLoadStatus.failure) {
      return AppErrorState(
        title: 'Nao foi possivel carregar os leads',
        message: state.failure?.message ?? 'Tente novamente em breve.',
        retryLabel: 'Tentar novamente',
        onRetry: () =>
            context.read<LeadListBloc>().add(const LeadListRetried()),
      );
    }
    if (state.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.leads.isEmpty) {
      return const AppEmptyState(
        title: 'Nenhum lead encontrado',
        description: 'Ajuste os filtros ou cadastre um novo lead.',
        icon: Icons.person_search_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (state.isFromLocalCache) const _OfflineCacheBanner(),
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            itemCount: state.leads.length + (state.isLoadingMore ? 1 : 0),
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.spacing12),
            itemBuilder: (context, index) {
              if (index >= state.leads.length) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.spacing16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final lead = state.leads[index];
              return _LeadCard(
                lead: lead,
                responsibleName: _responsibleName(lead.responsibleUserId),
                canQualify: widget.canQualify,
                isActionPending: state.isActionPending(lead.id),
                onQualify: () => context.read<LeadListBloc>().add(
                  LeadListLeadQualified(lead.id),
                ),
                onDisqualify: () => _promptDisqualify(context, lead),
              );
            },
          ),
        ),
      ],
    );
  }

  String? _responsibleName(String responsibleUserId) {
    for (final user in widget.state.responsibleUsers) {
      if (user.userId == responsibleUserId) return user.name;
    }
    return null;
  }

  Future<void> _promptDisqualify(BuildContext context, Lead lead) async {
    final bloc = context.read<LeadListBloc>();
    final reason = await _DisqualifyReasonDialog.show(context, lead: lead);
    if (reason == null) return;
    bloc.add(LeadListLeadDisqualified(leadId: lead.id, reason: reason));
  }
}

class _LeadFilters extends StatefulWidget {
  const _LeadFilters({required this.state});

  final LeadListState state;

  @override
  State<_LeadFilters> createState() => _LeadFiltersState();
}

class _LeadFiltersState extends State<_LeadFilters> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.state.searchQuery);
  }

  @override
  void didUpdateWidget(covariant _LeadFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_searchController.text != widget.state.searchQuery) {
      _searchController.text = widget.state.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<LeadListBloc>();
    final filters = widget.state.filters;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTextField(
            controller: _searchController,
            label: 'Busca',
            hintText: 'Nome ou documento',
            semanticLabel: 'Buscar lead por nome ou documento',
            prefixIcon: const Icon(Icons.search),
            onChanged: (value) => bloc.add(LeadListSearchChanged(value)),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppDropdown<LeadStatus>(
            multiple: true,
            label: 'Status',
            hintText: 'Todos',
            semanticLabel: 'Filtrar por status',
            closeSemanticLabel: 'Fechar filtro de status',
            enableSearch: false,
            options: LeadStatus.values
                .map(
                  (status) => AppDropdownOption<LeadStatus>(
                    value: status,
                    label: leadStatusLabel(status),
                  ),
                )
                .toList(growable: false),
            selectedValues: filters.statuses,
            onChanged: (selected) =>
                _changeFilters(filters.copyWith(statuses: selected)),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppDropdown<String>(
            multiple: true,
            label: 'Origem',
            hintText: 'Todas',
            semanticLabel: 'Filtrar por origem',
            closeSemanticLabel: 'Fechar filtro de origem',
            enableSearch: false,
            options: LeadSource.defaults
                .map(
                  (source) => AppDropdownOption<String>(
                    value: source.code,
                    label: source.label,
                  ),
                )
                .toList(growable: false),
            selectedValues: filters.sourceCodes,
            onChanged: (selected) =>
                _changeFilters(filters.copyWith(sourceCodes: selected)),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppDropdown<String>(
            multiple: true,
            label: 'Responsavel',
            hintText: 'Todos',
            semanticLabel: 'Filtrar por responsavel',
            closeSemanticLabel: 'Fechar filtro de responsavel',
            searchHintText: 'Buscar responsavel',
            noResultsLabel: 'Nenhum responsavel disponivel',
            options: widget.state.responsibleUsers
                .map(
                  (user) => AppDropdownOption<String>(
                    value: user.userId,
                    label: user.name,
                  ),
                )
                .toList(growable: false),
            selectedValues: filters.responsibleUserIds,
            onChanged: (selected) =>
                _changeFilters(filters.copyWith(responsibleUserIds: selected)),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppButton(
            label: 'Limpar filtros',
            leadingIcon: Icons.clear,
            variant: AppButtonVariant.text,
            onPressed: () {
              _searchController.clear();
              bloc
                ..add(const LeadListSearchChanged(''))
                ..add(const LeadListFiltersChanged(LeadListFilters.empty));
            },
          ),
        ],
      ),
    );
  }

  void _changeFilters(LeadListFilters filters) {
    context.read<LeadListBloc>().add(LeadListFiltersChanged(filters));
  }
}

class _OfflineCacheBanner extends StatelessWidget {
  const _OfflineCacheBanner();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.spacing12),
      padding: const EdgeInsets.all(AppSpacing.spacing12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colors.warning.withValues(alpha: 0.14),
          colors.surface,
        ),
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        border: Border.all(color: colors.warning.withValues(alpha: 0.34)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.cloud_off_outlined, color: colors.warning),
          const SizedBox(width: AppSpacing.spacing12),
          Expanded(
            child: Text(
              'Exibindo leads locais.',
              style: AppTypography.bodyMedium.copyWith(color: colors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  const _LeadCard({
    required this.lead,
    required this.responsibleName,
    required this.canQualify,
    required this.isActionPending,
    required this.onQualify,
    required this.onDisqualify,
  });

  final Lead lead;
  final String? responsibleName;
  final bool canQualify;
  final bool isActionPending;
  final VoidCallback onQualify;
  final VoidCallback onDisqualify;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        border: Border.all(color: colors.outline.withValues(alpha: 0.22)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                lead.name,
                style: AppTypography.titleMedium.copyWith(
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing4),
              Text(
                'Responsavel: ${responsibleName ?? lead.responsibleUserId}',
                style: AppTypography.bodyMedium.copyWith(color: colors.outline),
              ),
            ],
          );
          final badges = Wrap(
            spacing: AppSpacing.spacing8,
            runSpacing: AppSpacing.spacing8,
            children: <Widget>[
              AppStatusBadge(
                label: leadStatusLabel(lead.status),
                variant: _statusVariant(lead.status),
                icon: _statusIcon(lead.status),
              ),
              AppStatusBadge(
                label: lead.source.label,
                variant: AppStatusBadgeVariant.neutral,
                icon: Icons.share_outlined,
              ),
            ],
          );
          final actions = _LeadCardActions(
            lead: lead,
            canQualify: canQualify,
            isActionPending: isActionPending,
            onQualify: onQualify,
            onDisqualify: onDisqualify,
          );
          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                title,
                const SizedBox(height: AppSpacing.spacing12),
                badges,
                const SizedBox(height: AppSpacing.spacing12),
                actions,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: title),
              const SizedBox(width: AppSpacing.spacing16),
              Flexible(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.spacing12,
                  runSpacing: AppSpacing.spacing8,
                  children: <Widget>[badges, actions],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  AppStatusBadgeVariant _statusVariant(LeadStatus status) {
    return switch (status) {
      LeadStatus.newLead => AppStatusBadgeVariant.neutral,
      LeadStatus.contacted => AppStatusBadgeVariant.info,
      LeadStatus.qualified => AppStatusBadgeVariant.success,
      LeadStatus.disqualified => AppStatusBadgeVariant.error,
      LeadStatus.converted => AppStatusBadgeVariant.success,
    };
  }

  IconData _statusIcon(LeadStatus status) {
    return switch (status) {
      LeadStatus.newLead => Icons.fiber_new_outlined,
      LeadStatus.contacted => Icons.phone_in_talk_outlined,
      LeadStatus.qualified => Icons.verified_outlined,
      LeadStatus.disqualified => Icons.block_outlined,
      LeadStatus.converted => Icons.celebration_outlined,
    };
  }
}

class _LeadCardActions extends StatelessWidget {
  const _LeadCardActions({
    required this.lead,
    required this.canQualify,
    required this.isActionPending,
    required this.onQualify,
    required this.onDisqualify,
  });

  final Lead lead;
  final bool canQualify;
  final bool isActionPending;
  final VoidCallback onQualify;
  final VoidCallback onDisqualify;

  @override
  Widget build(BuildContext context) {
    if (!canQualify) return const SizedBox.shrink();

    final canGoQualified = lead.canTransitionTo(LeadStatus.qualified);
    final canGoDisqualified = lead.canTransitionTo(LeadStatus.disqualified);
    if (!canGoQualified && !canGoDisqualified) return const SizedBox.shrink();

    if (isActionPending) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacing8),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.spacing8,
      children: <Widget>[
        if (canGoQualified)
          AppButton(
            label: 'Qualificar',
            leadingIcon: Icons.check_circle_outline,
            variant: AppButtonVariant.secondary,
            onPressed: onQualify,
          ),
        if (canGoDisqualified)
          AppButton(
            label: 'Desqualificar',
            leadingIcon: Icons.cancel_outlined,
            variant: AppButtonVariant.destructive,
            onPressed: onDisqualify,
          ),
      ],
    );
  }
}

class _DisqualifyReasonDialog extends StatefulWidget {
  const _DisqualifyReasonDialog({required this.lead});

  final Lead lead;

  static Future<String?> show(BuildContext context, {required Lead lead}) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _DisqualifyReasonDialog(lead: lead),
    );
  }

  @override
  State<_DisqualifyReasonDialog> createState() =>
      _DisqualifyReasonDialogState();
}

class _DisqualifyReasonDialogState extends State<_DisqualifyReasonDialog> {
  final _reasonController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _confirm() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _errorText = 'Informe o motivo da desqualificacao.');
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isMobile = context.breakpoint == AppBreakpoint.mobile;
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.spacing16 : AppSpacing.spacing24,
        vertical: AppSpacing.spacing24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radius16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.cancel_outlined, color: colors.error),
                  const SizedBox(width: AppSpacing.spacing12),
                  Expanded(
                    child: Text(
                      'Desqualificar ${widget.lead.name}?',
                      style: AppTypography.titleLarge.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.spacing16),
              AppTextField(
                controller: _reasonController,
                label: 'Motivo',
                hintText: 'Ex.: Sem fit com o portfolio',
                semanticLabel: 'Motivo da desqualificacao',
                isRequired: true,
                errorText: _errorText,
                maxLines: 3,
                onChanged: (_) {
                  if (_errorText != null) setState(() => _errorText = null);
                },
              ),
              const SizedBox(height: AppSpacing.spacing24),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.spacing12,
                runSpacing: AppSpacing.spacing12,
                children: <Widget>[
                  AppButton(
                    label: 'Cancelar',
                    variant: AppButtonVariant.text,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  AppButton(
                    label: 'Desqualificar',
                    variant: AppButtonVariant.destructive,
                    onPressed: _confirm,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Human-readable label for [LeadStatus], reused by the filter dropdown and
/// the card badge so the two never drift apart.
String leadStatusLabel(LeadStatus status) {
  return switch (status) {
    LeadStatus.newLead => 'Novo',
    LeadStatus.contacted => 'Em contato',
    LeadStatus.qualified => 'Qualificado',
    LeadStatus.disqualified => 'Desqualificado',
    LeadStatus.converted => 'Convertido',
  };
}
