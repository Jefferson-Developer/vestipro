import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/opportunity.dart';
import '../../domain/entities/opportunity_outcome_reason.dart';
import '../../domain/entities/pipeline_column.dart';
import '../../domain/entities/pipeline_stage.dart';
import '../../domain/value_objects/opportunity_outcome_type.dart';
import '../../domain/value_objects/pipeline_stage_terminal_type.dart';
import '../bloc/sales_pipeline_bloc.dart';
import '../bloc/sales_pipeline_event.dart';
import '../bloc/sales_pipeline_state.dart';
import 'pipeline_stage_admin_page.dart' show pipelineStageTerminalTypeLabel;

final NumberFormat _currencyFormat = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: r'R$',
);

/// Sales pipeline/funnel board (TASK-058): configurable [PipelineStage]
/// columns with drag-and-drop on the Web and an equivalent explicit
/// "Mover para estagio" action on mobile, both funneling through the same
/// `SalesPipelineBloc` events — gated by [Capability.opportunityView].
class SalesPipelinePage extends StatelessWidget {
  const SalesPipelinePage({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    this.companyId,
    this.responsibleUserIds = const <String>{},
    this.onManageStages,
    super.key,
  });

  final String organizationId;
  final String? companyId;
  final String userId;
  final PermissionService permissionService;
  final SalesPipelineBloc Function() createBloc;
  final Set<String> responsibleUserIds;

  /// Called when the caller taps "Gerenciar estagios". `null` hides the
  /// action entirely, even when [Capability.pipelineStageManage] is
  /// granted, so a host that has not wired the admin route yet never shows
  /// a dead button.
  final VoidCallback? onManageStages;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.opportunityView,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return _SalesPipelineActionsGate(
          organizationId: organizationId,
          userId: userId,
          permissionService: permissionService,
          createBloc: createBloc,
          companyId: companyId,
          responsibleUserIds: responsibleUserIds,
          onManageStages: onManageStages,
        );
      },
    );
  }
}

class _SalesPipelineActionsGate extends StatefulWidget {
  const _SalesPipelineActionsGate({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    this.companyId,
    required this.responsibleUserIds,
    this.onManageStages,
  });

  final String organizationId;
  final String? companyId;
  final String userId;
  final PermissionService permissionService;
  final SalesPipelineBloc Function() createBloc;
  final Set<String> responsibleUserIds;
  final VoidCallback? onManageStages;

  @override
  State<_SalesPipelineActionsGate> createState() =>
      _SalesPipelineActionsGateState();
}

class _SalesPipelineActionsGateState extends State<_SalesPipelineActionsGate> {
  late final Future<_SalesPipelinePermissions> _permissions;

  @override
  void initState() {
    super.initState();
    _permissions = _resolvePermissions();
  }

  Future<_SalesPipelinePermissions> _resolvePermissions() async {
    final results = await Future.wait<bool>(<Future<bool>>[
      _hasCapability(Capability.opportunityManage),
      _hasCapability(Capability.pipelineStageManage),
    ]);
    return _SalesPipelinePermissions(
      canMove: results[0],
      canManageStages: results[1],
    );
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
    return FutureBuilder<_SalesPipelinePermissions>(
      future: _permissions,
      builder: (context, snapshot) {
        final permissions = snapshot.data ?? const _SalesPipelinePermissions();
        return BlocProvider<SalesPipelineBloc>(
          create: (_) => widget.createBloc()
            ..add(
              SalesPipelineStarted(
                organizationId: widget.organizationId,
                companyId: widget.companyId,
                userId: widget.userId,
                responsibleUserIds: widget.responsibleUserIds,
              ),
            ),
          child: _SalesPipelineScaffold(
            canMove: permissions.canMove,
            showManageStagesAction:
                permissions.canManageStages && widget.onManageStages != null,
            onManageStages: widget.onManageStages,
          ),
        );
      },
    );
  }
}

class _SalesPipelinePermissions {
  const _SalesPipelinePermissions({
    this.canMove = false,
    this.canManageStages = false,
  });

  final bool canMove;
  final bool canManageStages;
}

class _SalesPipelineScaffold extends StatelessWidget {
  const _SalesPipelineScaffold({
    required this.canMove,
    required this.showManageStagesAction,
    this.onManageStages,
  });

  final bool canMove;
  final bool showManageStagesAction;
  final VoidCallback? onManageStages;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppAdminPageLayout(
        title: 'Funil de vendas',
        actions: <Widget>[
          if (showManageStagesAction)
            AppButton(
              label: 'Gerenciar estagios',
              leadingIcon: Icons.tune,
              variant: AppButtonVariant.secondary,
              onPressed: onManageStages,
            ),
        ],
        content: _SalesPipelineContent(canMove: canMove),
      ),
    );
  }
}

class _SalesPipelineContent extends StatelessWidget {
  const _SalesPipelineContent({required this.canMove});

  final bool canMove;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SalesPipelineBloc, SalesPipelineState>(
      listenWhen: (previous, current) =>
          previous.actionStatus != current.actionStatus &&
          current.actionStatus == SalesPipelineActionStatus.failure,
      listener: (context, state) {
        AppSnackbar.show(
          context,
          message:
              state.actionFailure?.message ??
              'Nao foi possivel mover a oportunidade.',
          variant: AppSnackbarVariant.error,
        );
        context.read<SalesPipelineBloc>().add(
          const SalesPipelineActionDismissed(),
        );
      },
      builder: (context, state) {
        if (state.status == SalesPipelineLoadStatus.failure) {
          return AppErrorState(
            title: 'Nao foi possivel carregar o funil',
            message: state.failure?.message ?? 'Tente novamente em breve.',
            retryLabel: 'Tentar novamente',
            onRetry: () => context.read<SalesPipelineBloc>().add(
              const SalesPipelineRetried(),
            ),
          );
        }
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.columns.isEmpty) {
          return const AppEmptyState(
            title: 'Nenhum estagio configurado',
            description:
                'Peca a um administrador para configurar os estagios do funil.',
            icon: Icons.view_column_outlined,
          );
        }

        return AppResponsiveBuilder(
          builder: (context, breakpoint) {
            final isWeb =
                breakpoint == AppBreakpoint.desktop ||
                breakpoint == AppBreakpoint.largeDesktop;
            return isWeb
                ? _SalesPipelineBoard(
                    key: const Key('sales-pipeline-board'),
                    columns: state.columns,
                    canMove: canMove,
                    pendingOpportunityId: state.pendingActionOpportunityId,
                  )
                : _SalesPipelineMobileList(
                    key: const Key('sales-pipeline-mobile-list'),
                    columns: state.columns,
                    canMove: canMove,
                    pendingOpportunityId: state.pendingActionOpportunityId,
                  );
          },
        );
      },
    );
  }
}

/// Dispatches the right `SalesPipelineBloc` event for moving [opportunity]
/// onto [targetStage] — collecting the mandatory reason first when
/// [targetStage] is terminal. Shared by both the Web board (drag-and-drop)
/// and the mobile list (explicit action) so the two platforms never
/// duplicate this decision (TASK-058 business rule).
Future<void> _requestMove(
  BuildContext context, {
  required Opportunity opportunity,
  required PipelineStage targetStage,
}) async {
  if (opportunity.stageId == targetStage.id) return;
  final bloc = context.read<SalesPipelineBloc>();

  if (targetStage.isTerminal) {
    final outcomeType = _outcomeTypeForTerminal(targetStage.terminalType);
    if (outcomeType == null) return;
    final closeResult = await _CloseReasonDialog.show(
      context,
      opportunity: opportunity,
      targetStage: targetStage,
      reasons: bloc.state.outcomeReasons
          .where((reason) => reason.type == outcomeType && reason.isActive)
          .toList(growable: false),
    );
    if (closeResult == null) return;
    bloc.add(
      SalesPipelineOpportunityClosedWithReason(
        opportunityId: opportunity.id,
        targetStageId: targetStage.id,
        reasonId: closeResult.reasonId,
        note: closeResult.note,
      ),
    );
    return;
  }

  bloc.add(
    SalesPipelineOpportunityMoveRequested(
      opportunityId: opportunity.id,
      targetStageId: targetStage.id,
    ),
  );
}

OpportunityOutcomeType? _outcomeTypeForTerminal(
  PipelineStageTerminalType terminalType,
) {
  return switch (terminalType) {
    PipelineStageTerminalType.won => OpportunityOutcomeType.won,
    PipelineStageTerminalType.lost => OpportunityOutcomeType.lost,
    PipelineStageTerminalType.none => null,
  };
}

class _SalesPipelineBoard extends StatelessWidget {
  const _SalesPipelineBoard({
    required this.columns,
    required this.canMove,
    this.pendingOpportunityId,
    super.key,
  });

  final List<PipelineColumn> columns;
  final bool canMove;
  final String? pendingOpportunityId;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final column in columns)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.spacing16),
              child: _PipelineColumnView(
                key: Key('pipeline-column-${column.stage.id}'),
                column: column,
                canMove: canMove,
                pendingOpportunityId: pendingOpportunityId,
              ),
            ),
        ],
      ),
    );
  }
}

class _PipelineColumnView extends StatelessWidget {
  const _PipelineColumnView({
    required this.column,
    required this.canMove,
    this.pendingOpportunityId,
    super.key,
  });

  final PipelineColumn column;
  final bool canMove;
  final String? pendingOpportunityId;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Opportunity>(
      onWillAcceptWithDetails: (details) =>
          canMove && details.data.stageId != column.stage.id,
      onAcceptWithDetails: (details) => _requestMove(
        context,
        opportunity: details.data,
        targetStage: column.stage,
      ),
      builder: (context, candidateData, rejectedData) {
        final colors = context.colors;
        final isDropTarget = candidateData.isNotEmpty;
        return Container(
          width: 300,
          padding: const EdgeInsets.all(AppSpacing.spacing12),
          decoration: BoxDecoration(
            color: isDropTarget
                ? Color.alphaBlend(
                    colors.primary.withValues(alpha: 0.08),
                    colors.surfaceContainer,
                  )
                : colors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.radius12),
            border: Border.all(
              color: isDropTarget
                  ? colors.primary
                  : colors.outline.withValues(alpha: 0.16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _ColumnHeader(column: column),
              const SizedBox(height: AppSpacing.spacing12),
              for (final opportunity in column.opportunities)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
                  child: Draggable<Opportunity>(
                    data: opportunity,
                    maxSimultaneousDrags: canMove ? 1 : 0,
                    feedback: Material(
                      color: Colors.transparent,
                      child: SizedBox(
                        width: 276,
                        child: _OpportunityCard(opportunity: opportunity),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.4,
                      child: _OpportunityCard(opportunity: opportunity),
                    ),
                    child: _OpportunityCard(
                      key: Key('pipeline-card-${opportunity.id}'),
                      opportunity: opportunity,
                      isPending: pendingOpportunityId == opportunity.id,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SalesPipelineMobileList extends StatelessWidget {
  const _SalesPipelineMobileList({
    required this.columns,
    required this.canMove,
    this.pendingOpportunityId,
    super.key,
  });

  final List<PipelineColumn> columns;
  final bool canMove;
  final String? pendingOpportunityId;

  @override
  Widget build(BuildContext context) {
    final allStages = columns
        .map((column) => column.stage)
        .toList(growable: false);
    return ListView(
      children: <Widget>[
        for (final column in columns) ...<Widget>[
          Padding(
            key: Key('pipeline-group-${column.stage.id}'),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing8),
            child: _ColumnHeader(column: column),
          ),
          if (column.opportunities.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.spacing16),
              child: Text(
                'Nenhuma oportunidade neste estagio.',
                style: AppTypography.bodyMedium.copyWith(
                  color: context.colors.outline,
                ),
              ),
            )
          else
            for (final opportunity in column.opportunities)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.spacing12),
                child: _OpportunityCard(
                  key: Key('pipeline-card-${opportunity.id}'),
                  opportunity: opportunity,
                  isPending: pendingOpportunityId == opportunity.id,
                  trailing: canMove
                      ? AppButton(
                          label: 'Mover',
                          variant: AppButtonVariant.secondary,
                          leadingIcon: Icons.swap_horiz,
                          onPressed: () => _promptMove(
                            context,
                            opportunity: opportunity,
                            currentStage: column.stage,
                            allStages: allStages,
                          ),
                        )
                      : null,
                ),
              ),
        ],
      ],
    );
  }

  Future<void> _promptMove(
    BuildContext context, {
    required Opportunity opportunity,
    required PipelineStage currentStage,
    required List<PipelineStage> allStages,
  }) async {
    final targetStage = await _MoveToStageSheet.show(
      context,
      currentStage: currentStage,
      stages: allStages,
    );
    if (targetStage == null || !context.mounted) return;
    await _requestMove(
      context,
      opportunity: opportunity,
      targetStage: targetStage,
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader({required this.column});

  final PipelineColumn column;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final stage = column.stage;
    return Semantics(
      key: Key('pipeline-column-header-${stage.id}'),
      label:
          '${stage.name}: ${column.activeCount} oportunidades, '
          '${_currencyFormat.format(column.activeValueTotal)}',
      container: true,
      child: Row(
        children: <Widget>[
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Color(
                int.parse('FF${stage.colorHex.substring(1)}', radix: 16),
              ),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.spacing8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  stage.name,
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${column.activeCount} oportunidades - '
                  '${_currencyFormat.format(column.activeValueTotal)}',
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

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({
    required this.opportunity,
    this.isPending = false,
    this.trailing,
    super.key,
  });

  final Opportunity opportunity;
  final bool isPending;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        border: Border.all(color: colors.outline.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            opportunity.title,
            style: AppTypography.bodyLarge.copyWith(color: colors.onSurface),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.spacing4),
          Text(
            _currencyFormat.format(opportunity.estimatedValue),
            style: AppTypography.labelMedium.copyWith(color: colors.outline),
          ),
          if (isPending) ...<Widget>[
            const SizedBox(height: AppSpacing.spacing8),
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ] else if (trailing != null) ...<Widget>[
            const SizedBox(height: AppSpacing.spacing8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _MoveToStageSheet extends StatelessWidget {
  const _MoveToStageSheet({required this.currentStage, required this.stages});

  final PipelineStage currentStage;
  final List<PipelineStage> stages;

  static Future<PipelineStage?> show(
    BuildContext context, {
    required PipelineStage currentStage,
    required List<PipelineStage> stages,
  }) {
    return AppBottomSheet.show<PipelineStage>(
      context: context,
      title: 'Mover para estagio',
      builder: (_) =>
          _MoveToStageSheet(currentStage: currentStage, stages: stages),
    );
  }

  @override
  Widget build(BuildContext context) {
    final targets = stages.where((stage) => stage.id != currentStage.id);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final stage in targets)
          ListTile(
            leading: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Color(
                  int.parse('FF${stage.colorHex.substring(1)}', radix: 16),
                ),
                shape: BoxShape.circle,
              ),
            ),
            title: Text(stage.name),
            subtitle: stage.isTerminal
                ? Text(pipelineStageTerminalTypeLabel(stage.terminalType))
                : null,
            onTap: () => Navigator.of(context).pop(stage),
          ),
      ],
    );
  }
}

class _CloseReasonDialog extends StatefulWidget {
  const _CloseReasonDialog({
    required this.opportunity,
    required this.targetStage,
    required this.reasons,
  });

  final Opportunity opportunity;
  final PipelineStage targetStage;
  final List<OpportunityOutcomeReason> reasons;

  static Future<_CloseReasonDialogResult?> show(
    BuildContext context, {
    required Opportunity opportunity,
    required PipelineStage targetStage,
    required List<OpportunityOutcomeReason> reasons,
  }) {
    return showDialog<_CloseReasonDialogResult>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _CloseReasonDialog(
        opportunity: opportunity,
        targetStage: targetStage,
        reasons: reasons,
      ),
    );
  }

  @override
  State<_CloseReasonDialog> createState() => _CloseReasonDialogState();
}

class _CloseReasonDialogResult {
  const _CloseReasonDialogResult({required this.reasonId, this.note});

  final String reasonId;
  final String? note;
}

class _CloseReasonDialogState extends State<_CloseReasonDialog> {
  final _noteController = TextEditingController();
  String? _selectedReasonId;
  String? _errorText;

  bool get _isWon =>
      widget.targetStage.terminalType == PipelineStageTerminalType.won;

  @override
  void initState() {
    super.initState();
    _selectedReasonId = widget.reasons.firstOrNull?.id;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _confirm() {
    final reasonId = _selectedReasonId;
    if (reasonId == null || reasonId.isEmpty) {
      setState(
        () => _errorText = _isWon
            ? 'Informe o motivo do ganho.'
            : 'Informe o motivo da perda.',
      );
      return;
    }
    final note = _noteController.text.trim();
    Navigator.of(context).pop(
      _CloseReasonDialogResult(
        reasonId: reasonId,
        note: note.isEmpty ? null : note,
      ),
    );
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
                  Icon(
                    _isWon
                        ? Icons.emoji_events_outlined
                        : Icons.cancel_outlined,
                    color: _isWon ? colors.success : colors.error,
                  ),
                  const SizedBox(width: AppSpacing.spacing12),
                  Expanded(
                    child: Text(
                      _isWon
                          ? 'Marcar "${widget.opportunity.title}" como ganha?'
                          : 'Marcar "${widget.opportunity.title}" como perdida?',
                      style: AppTypography.titleLarge.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.spacing16),
              if (widget.reasons.isEmpty)
                AppEmptyState(
                  title: _isWon
                      ? 'Nenhum motivo de ganho ativo'
                      : 'Nenhum motivo de perda ativo',
                  description:
                      'Cadastre um motivo ativo antes de fechar a oportunidade.',
                  icon: Icons.fact_check_outlined,
                )
              else ...<Widget>[
                AppDropdown<String>(
                  label: 'Motivo',
                  closeSemanticLabel: 'Fechar selecao de motivo',
                  enableSearch: false,
                  options: widget.reasons
                      .map(
                        (reason) => AppDropdownOption<String>(
                          value: reason.id,
                          label: reason.description,
                        ),
                      )
                      .toList(growable: false),
                  selectedValues: _selectedReasonId == null
                      ? const <String>{}
                      : <String>{_selectedReasonId!},
                  errorText: _errorText,
                  onChanged: (selected) {
                    setState(() {
                      _selectedReasonId = selected.firstOrNull;
                      _errorText = null;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.spacing16),
                AppTextField(
                  controller: _noteController,
                  label: 'Observacao',
                  hintText: _isWon
                      ? 'Ex.: cliente valorizou pronta entrega'
                      : 'Ex.: retornar na proxima colecao',
                  semanticLabel: 'Observacao do fechamento',
                  maxLines: 3,
                ),
              ],
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
                    label: _isWon ? 'Marcar como ganha' : 'Marcar como perdida',
                    variant: _isWon
                        ? AppButtonVariant.primary
                        : AppButtonVariant.destructive,
                    onPressed: widget.reasons.isEmpty ? null : _confirm,
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
