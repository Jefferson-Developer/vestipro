import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/opportunity_outcome_reason.dart';
import '../../domain/value_objects/opportunity_outcome_type.dart';
import '../bloc/opportunity_outcome_reason_admin_bloc.dart';
import '../bloc/opportunity_outcome_reason_admin_event.dart';
import '../bloc/opportunity_outcome_reason_admin_state.dart';

class OpportunityOutcomeReasonAdminPage extends StatelessWidget {
  const OpportunityOutcomeReasonAdminPage({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    super.key,
  });

  final String organizationId;
  final String userId;
  final PermissionService permissionService;
  final OpportunityOutcomeReasonAdminBloc Function() createBloc;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.pipelineStageManage,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<OpportunityOutcomeReasonAdminBloc>(
          create: (_) => createBloc()
            ..add(
              OpportunityOutcomeReasonAdminStarted(
                organizationId: organizationId,
                userId: userId,
              ),
            ),
          child: const _OutcomeReasonAdminScaffold(),
        );
      },
    );
  }
}

class _OutcomeReasonAdminScaffold extends StatelessWidget {
  const _OutcomeReasonAdminScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppAdminPageLayout(
        title: 'Motivos de ganho e perda',
        actions: <Widget>[
          AppButton(
            label: 'Novo motivo',
            leadingIcon: Icons.add,
            onPressed: () => _promptCreate(context),
          ),
        ],
        content: const _OutcomeReasonAdminContent(),
      ),
    );
  }

  Future<void> _promptCreate(BuildContext context) async {
    final bloc = context.read<OpportunityOutcomeReasonAdminBloc>();
    final result = await _ReasonFormDialog.show(context);
    if (result == null) return;
    bloc.add(
      OpportunityOutcomeReasonAdminReasonCreated(
        type: result.type,
        description: result.description,
      ),
    );
  }
}

class _OutcomeReasonAdminContent extends StatelessWidget {
  const _OutcomeReasonAdminContent();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<
      OpportunityOutcomeReasonAdminBloc,
      OpportunityOutcomeReasonAdminState
    >(
      listenWhen: (previous, current) =>
          previous.actionStatus != current.actionStatus &&
          current.actionStatus ==
              OpportunityOutcomeReasonAdminActionStatus.failure,
      listener: (context, state) {
        AppSnackbar.show(
          context,
          message:
              state.actionFailure?.message ??
              'Nao foi possivel salvar o motivo.',
          variant: AppSnackbarVariant.error,
        );
        context.read<OpportunityOutcomeReasonAdminBloc>().add(
          const OpportunityOutcomeReasonAdminActionDismissed(),
        );
      },
      builder: (context, state) {
        if (state.status == OpportunityOutcomeReasonAdminLoadStatus.failure) {
          return AppErrorState(
            title: 'Nao foi possivel carregar os motivos',
            message: state.failure?.message ?? 'Tente novamente em breve.',
            retryLabel: 'Tentar novamente',
            onRetry: () => context
                .read<OpportunityOutcomeReasonAdminBloc>()
                .add(const OpportunityOutcomeReasonAdminRetried()),
          );
        }
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.reasons.isEmpty) {
          return const AppEmptyState(
            title: 'Nenhum motivo cadastrado',
            description:
                'Cadastre motivos de ganho e perda para padronizar o funil.',
            icon: Icons.fact_check_outlined,
          );
        }

        final wonReasons = state.reasons
            .where((reason) => reason.type == OpportunityOutcomeType.won)
            .toList(growable: false);
        final lostReasons = state.reasons
            .where((reason) => reason.type == OpportunityOutcomeType.lost)
            .toList(growable: false);

        return ListView(
          children: <Widget>[
            _ReasonSection(title: 'Ganhos', reasons: wonReasons),
            const SizedBox(height: AppSpacing.spacing16),
            _ReasonSection(title: 'Perdas', reasons: lostReasons),
          ],
        );
      },
    );
  }
}

class _ReasonSection extends StatelessWidget {
  const _ReasonSection({required this.title, required this.reasons});

  final String title;
  final List<OpportunityOutcomeReason> reasons;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(title, style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.spacing8),
        if (reasons.isEmpty)
          Text(
            'Nenhum motivo deste tipo.',
            style: AppTypography.bodyMedium.copyWith(
              color: context.colors.outline,
            ),
          )
        else
          for (final reason in reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
              child: _ReasonTile(
                key: Key('outcome-reason-${reason.id}'),
                reason: reason,
              ),
            ),
      ],
    );
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({required this.reason, super.key});

  final OpportunityOutcomeReason reason;

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
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.spacing12,
        runSpacing: AppSpacing.spacing12,
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 180, maxWidth: 520),
            child: Text(
              reason.description,
              style: AppTypography.bodyLarge.copyWith(color: colors.onSurface),
            ),
          ),
          AppStatusBadge(
            label: reason.isActive ? 'Ativo' : 'Inativo',
            variant: reason.isActive
                ? AppStatusBadgeVariant.success
                : AppStatusBadgeVariant.neutral,
          ),
          AppButton(
            label: 'Editar',
            variant: AppButtonVariant.text,
            onPressed: () => _promptEdit(context),
          ),
          if (reason.isActive)
            AppButton(
              label: 'Desativar',
              variant: AppButtonVariant.destructive,
              onPressed: () =>
                  context.read<OpportunityOutcomeReasonAdminBloc>().add(
                    OpportunityOutcomeReasonAdminReasonDeactivated(reason.id),
                  ),
            ),
        ],
      ),
    );
  }

  Future<void> _promptEdit(BuildContext context) async {
    final bloc = context.read<OpportunityOutcomeReasonAdminBloc>();
    final result = await _ReasonFormDialog.show(context, reason: reason);
    if (result == null) return;
    bloc.add(
      OpportunityOutcomeReasonAdminReasonRenamed(
        reasonId: reason.id,
        description: result.description,
      ),
    );
  }
}

class _ReasonFormResult {
  const _ReasonFormResult({required this.type, required this.description});

  final OpportunityOutcomeType type;
  final String description;
}

class _ReasonFormDialog extends StatefulWidget {
  const _ReasonFormDialog({this.reason});

  final OpportunityOutcomeReason? reason;

  static Future<_ReasonFormResult?> show(
    BuildContext context, {
    OpportunityOutcomeReason? reason,
  }) {
    return showDialog<_ReasonFormResult>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _ReasonFormDialog(reason: reason),
    );
  }

  @override
  State<_ReasonFormDialog> createState() => _ReasonFormDialogState();
}

class _ReasonFormDialogState extends State<_ReasonFormDialog> {
  late final TextEditingController _descriptionController;
  late OpportunityOutcomeType _type;
  String? _descriptionError;

  bool get _isEditing => widget.reason != null;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.reason?.description ?? '',
    );
    _type = widget.reason?.type ?? OpportunityOutcomeType.won;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _confirm() {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      setState(() => _descriptionError = 'Informe a descricao do motivo.');
      return;
    }
    Navigator.of(
      context,
    ).pop(_ReasonFormResult(type: _type, description: description));
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
              Text(
                _isEditing ? 'Editar motivo' : 'Novo motivo',
                style: AppTypography.titleLarge.copyWith(
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing16),
              if (!_isEditing) ...<Widget>[
                AppDropdown<OpportunityOutcomeType>(
                  label: 'Tipo',
                  closeSemanticLabel: 'Fechar selecao de tipo',
                  enableSearch: false,
                  options: OpportunityOutcomeType.values
                      .map(
                        (type) => AppDropdownOption<OpportunityOutcomeType>(
                          value: type,
                          label: opportunityOutcomeTypeLabel(type),
                        ),
                      )
                      .toList(growable: false),
                  selectedValues: <OpportunityOutcomeType>{_type},
                  onChanged: (selected) {
                    if (selected.isEmpty) return;
                    setState(() => _type = selected.first);
                  },
                ),
                const SizedBox(height: AppSpacing.spacing16),
              ],
              AppTextField(
                controller: _descriptionController,
                label: 'Descricao',
                hintText: _type == OpportunityOutcomeType.won
                    ? 'Ex.: Produto aderente a colecao'
                    : 'Ex.: Preco acima do esperado',
                semanticLabel: 'Descricao do motivo',
                isRequired: true,
                errorText: _descriptionError,
                onChanged: (_) {
                  if (_descriptionError != null) {
                    setState(() => _descriptionError = null);
                  }
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
                  AppButton(label: 'Salvar', onPressed: _confirm),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String opportunityOutcomeTypeLabel(OpportunityOutcomeType type) {
  return switch (type) {
    OpportunityOutcomeType.won => 'Ganho',
    OpportunityOutcomeType.lost => 'Perda',
  };
}
