import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../design_system/design_system.dart';
import '../../domain/entities/conflict_record.dart';
import '../cubit/conflict_resolution_cubit.dart';
import '../cubit/conflict_resolution_state.dart';
import '../presenters/conflict_presenter.dart';

/// Compares the local and remote versions of one blocked [ConflictRecord]
/// side by side (desktop) / stacked (mobile) and lets the user resolve it
/// explicitly (TASK-111, EPIC-14 — seção 5.5 de `tasks.md`): "Manter minha
/// versão", "Usar versão do servidor" and, when [allowsFieldMerge], "Mesclar
/// campo a campo".
///
/// Never applies a resolution without the explicit confirmation dialog
/// (TASK-111's own restriction: "ação de resolução só é irreversível após
/// confirmação explícita").
class ConflictDetailPage extends StatelessWidget {
  const ConflictDetailPage({
    required this.conflictId,
    required this.resolvedBy,
    required this.createCubit,
    this.onResolved,
    super.key,
  });

  final String conflictId;

  /// The id of the user resolving this conflict — recorded as
  /// `ConflictRecord.resolvedBy`/`ConflictAuditEntry.actor`.
  final String resolvedBy;

  final ConflictResolutionCubit Function() createCubit;

  /// Called once the resolution succeeds, so the host can pop back to
  /// `ConflictListRoute` and remove this item from that list's own state.
  final ValueChanged<ConflictRecord>? onResolved;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ConflictResolutionCubit>(
      create: (_) {
        final cubit = createCubit();
        unawaited(cubit.load(conflictId: conflictId));
        return cubit;
      },
      child: ConflictDetailView(
        conflictId: conflictId,
        resolvedBy: resolvedBy,
        onResolved: onResolved,
      ),
    );
  }
}

@visibleForTesting
class ConflictDetailView extends StatelessWidget {
  const ConflictDetailView({
    required this.conflictId,
    required this.resolvedBy,
    this.onResolved,
    super.key,
  });

  final String conflictId;
  final String resolvedBy;
  final ValueChanged<ConflictRecord>? onResolved;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Resolver conflito'),
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
      ),
      body: BlocConsumer<ConflictResolutionCubit, ConflictResolutionState>(
        listenWhen: (previous, current) =>
            previous.submitStatus != current.submitStatus,
        listener: (context, state) {
          if (state.submitStatus == ConflictResolutionSubmitStatus.success &&
              state.record != null) {
            AppSnackbar.show(
              context,
              message: 'Conflito resolvido com sucesso.',
              variant: AppSnackbarVariant.success,
            );
            onResolved?.call(state.record!);
          } else if (state.submitStatus ==
              ConflictResolutionSubmitStatus.failure) {
            AppSnackbar.show(
              context,
              message:
                  state.submitFailure?.message ??
                  'Não foi possível aplicar a resolução.',
              variant: AppSnackbarVariant.error,
            );
          }
        },
        builder: (context, state) {
          if (state.isInitialLoading) {
            return const _DetailLoading();
          }

          if (state.loadStatus == ConflictResolutionLoadStatus.notFound) {
            return const AppEmptyState(
              icon: Icons.search_off,
              title: 'Conflito não encontrado',
              description:
                  'Ele pode já ter sido resolvido em outro dispositivo ou '
                  'sessão.',
            );
          }

          if (state.loadStatus == ConflictResolutionLoadStatus.failure) {
            return AppErrorState(
              title: 'Não foi possível carregar o conflito',
              message:
                  state.loadFailure?.message ??
                  'Ocorreu um erro inesperado ao carregar os detalhes.',
              retryLabel: 'Tentar novamente',
              onRetry: () => context.read<ConflictResolutionCubit>().load(
                conflictId: conflictId,
              ),
            );
          }

          final record = state.record;
          if (record == null) return const _DetailLoading();

          if (state.isResolved) {
            return _ResolvedConfirmation(record: record);
          }

          return _ConflictComparison(record: record, resolvedBy: resolvedBy);
        },
      ),
    );
  }
}

class _DetailLoading extends StatelessWidget {
  const _DetailLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.spacing16),
      child: Column(
        children: <Widget>[
          AppSkeleton.card(),
          SizedBox(height: AppSpacing.spacing12),
          AppSkeleton.card(),
          SizedBox(height: AppSpacing.spacing12),
          AppSkeleton.card(),
        ],
      ),
    );
  }
}

class _ResolvedConfirmation extends StatelessWidget {
  const _ResolvedConfirmation({required this.record});

  final ConflictRecord record;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.check_circle,
              size: AppIconSizes.xxl,
              color: colors.success,
            ),
            const SizedBox(height: AppSpacing.spacing16),
            Text(
              'Conflito resolvido',
              style: AppTypography.titleMedium.copyWith(
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing8),
            Text(
              'A operação foi reenfileirada e será sincronizada novamente '
              'com os valores escolhidos.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: colors.outline),
            ),
          ],
        ),
      ),
    );
  }
}

/// The comparison + actions view for an unresolved [record] — the core of
/// TASK-111's screen. Kept as its own [StatefulWidget] because the
/// field-by-field merge action needs to remember, per divergent field,
/// which side the user picked before "Confirmar mesclagem" is enabled.
class _ConflictComparison extends StatefulWidget {
  const _ConflictComparison({required this.record, required this.resolvedBy});

  final ConflictRecord record;
  final String resolvedBy;

  @override
  State<_ConflictComparison> createState() => _ConflictComparisonState();
}

class _ConflictComparisonState extends State<_ConflictComparison> {
  /// Fields the user has explicitly chosen to keep the *local* value for,
  /// while in "mesclar campo a campo" mode — every other divergent field
  /// defaults to the remote value, mirroring
  /// `ConflictResolutionCubit.mergeFields`'s own "start from remote" rule.
  final Set<String> _fieldsFromLocal = <String>{};
  bool _isMergeMode = false;

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final isSubmitting = context
        .watch<ConflictResolutionCubit>()
        .state
        .isSubmitting;

    return AppResponsiveBuilder(
      builder: (context, breakpoint) {
        final isMobile = breakpoint == AppBreakpoint.mobile;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildHeader(context, record),
              const SizedBox(height: AppSpacing.spacing16),
              ...record.conflictingFields.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.spacing12),
                  child: _FieldComparisonRow(
                    field: field,
                    localValue: record.localSnapshot[field],
                    remoteValue: record.remoteSnapshot[field],
                    isMobile: isMobile,
                    isMergeMode: _isMergeMode,
                    keepsLocal: _fieldsFromLocal.contains(field),
                    onKeepsLocalChanged: (keepsLocal) {
                      setState(() {
                        if (keepsLocal) {
                          _fieldsFromLocal.add(field);
                        } else {
                          _fieldsFromLocal.remove(field);
                        }
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.spacing16),
              _buildActions(context, record, isSubmitting),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ConflictRecord record) {
    final colors = context.colors;
    final isCritical = isCriticalConflict(record);

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
          Row(
            children: <Widget>[
              Text(
                conflictEntityTypeLabel(record.entityType),
                style: AppTypography.titleLarge.copyWith(
                  color: colors.onSurface,
                ),
              ),
              if (isCritical) ...<Widget>[
                const SizedBox(width: AppSpacing.spacing8),
                const AppStatusBadge(
                  label: 'Crítico',
                  variant: AppStatusBadgeVariant.error,
                  icon: Icons.priority_high,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.spacing8),
          Text(
            'Detectado em ${conflictDetectedAtLabel(record.detectedAt)}. '
            'Escolha qual versão deve prevalecer para cada campo abaixo — '
            'a versão descartada não poderá ser recuperada depois de '
            'confirmada.',
            style: AppTypography.bodyMedium.copyWith(color: colors.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    ConflictRecord record,
    bool isSubmitting,
  ) {
    if (_isMergeMode) {
      return Wrap(
        alignment: WrapAlignment.end,
        spacing: AppSpacing.spacing12,
        runSpacing: AppSpacing.spacing12,
        children: <Widget>[
          AppButton(
            label: 'Cancelar mesclagem',
            variant: AppButtonVariant.text,
            isDisabled: isSubmitting,
            onPressed: () => setState(() {
              _isMergeMode = false;
              _fieldsFromLocal.clear();
            }),
          ),
          AppButton(
            label: 'Confirmar mesclagem',
            variant: AppButtonVariant.primary,
            isLoading: isSubmitting,
            onPressed: () => _confirmAndSubmit(
              context,
              title: 'Confirmar mesclagem de campos?',
              message:
                  'Os campos selecionados manterão o valor local; os demais '
                  'usarão o valor do servidor. Esta ação reenfileira a '
                  'operação para sincronização e não pode ser desfeita.',
              onConfirmed: () =>
                  context.read<ConflictResolutionCubit>().mergeFields(
                    fieldsFromLocal: _fieldsFromLocal,
                    resolvedBy: widget.resolvedBy,
                  ),
            ),
          ),
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.spacing12,
      runSpacing: AppSpacing.spacing12,
      children: <Widget>[
        if (allowsFieldMerge(record))
          AppButton(
            label: 'Mesclar campo a campo',
            variant: AppButtonVariant.secondary,
            isDisabled: isSubmitting,
            onPressed: () => setState(() => _isMergeMode = true),
          ),
        AppButton(
          label: 'Usar versão do servidor',
          variant: AppButtonVariant.secondary,
          isLoading: isSubmitting,
          onPressed: () => _confirmAndSubmit(
            context,
            title: 'Usar versão do servidor?',
            message:
                'Os valores alterados neste dispositivo enquanto offline '
                'serão descartados. Esta ação reenfileira a operação para '
                'sincronização e não pode ser desfeita.',
            onConfirmed: () => context
                .read<ConflictResolutionCubit>()
                .useRemote(resolvedBy: widget.resolvedBy),
          ),
        ),
        AppButton(
          label: 'Manter minha versão',
          variant: AppButtonVariant.primary,
          isLoading: isSubmitting,
          onPressed: () => _confirmAndSubmit(
            context,
            title: 'Manter sua versão?',
            message:
                'Os valores alterados no servidor por outro usuário/'
                'dispositivo serão descartados. Esta ação reenfileira a '
                'operação para sincronização e não pode ser desfeita.',
            onConfirmed: () => context
                .read<ConflictResolutionCubit>()
                .keepLocal(resolvedBy: widget.resolvedBy),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAndSubmit(
    BuildContext context, {
    required String title,
    required String message,
    required Future<void> Function() onConfirmed,
  }) async {
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: title,
      message: message,
      confirmLabel: 'Confirmar',
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    await onConfirmed();
  }
}

/// One divergent field: business label, local value, remote value —
/// side by side on desktop, stacked on mobile — never distinguishing local
/// from remote by color alone (labels are always shown). When
/// [isMergeMode], a switch lets the user pick which side to keep for this
/// specific field.
class _FieldComparisonRow extends StatelessWidget {
  const _FieldComparisonRow({
    required this.field,
    required this.localValue,
    required this.remoteValue,
    required this.isMobile,
    required this.isMergeMode,
    required this.keepsLocal,
    required this.onKeepsLocalChanged,
  });

  final String field;
  final Object? localValue;
  final Object? remoteValue;
  final bool isMobile;
  final bool isMergeMode;
  final bool keepsLocal;
  final ValueChanged<bool> onKeepsLocalChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final localSide = _ValueTile(
      label: 'Local (neste dispositivo)',
      value: localValue,
      isChosen: isMergeMode && keepsLocal,
    );
    final remoteSide = _ValueTile(
      label: 'Remoto (servidor)',
      value: remoteValue,
      isChosen: isMergeMode && !keepsLocal,
    );

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
            conflictFieldLabel(field),
            style: AppTypography.labelLarge.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.spacing12),
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    localSide,
                    const SizedBox(height: AppSpacing.spacing8),
                    remoteSide,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: localSide),
                    const SizedBox(width: AppSpacing.spacing16),
                    Expanded(child: remoteSide),
                  ],
                ),
          if (isMergeMode) ...<Widget>[
            const SizedBox(height: AppSpacing.spacing8),
            AppCheckbox(
              value: keepsLocal,
              onChanged: onKeepsLocalChanged,
              label: 'Manter valor local para este campo',
            ),
          ],
        ],
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  const _ValueTile({
    required this.label,
    required this.value,
    required this.isChosen,
  });

  final String label;
  final Object? value;
  final bool isChosen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing12),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        border: isChosen
            ? Border.all(color: colors.primary, width: 2)
            : Border.all(color: Colors.transparent, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: colors.outline,
                  ),
                ),
              ),
              if (isChosen)
                Icon(
                  Icons.check_circle,
                  size: AppIconSizes.sm,
                  color: colors.primary,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing4),
          Text(
            conflictFieldValueLabel(value),
            style: AppTypography.bodyMedium.copyWith(color: colors.onSurface),
          ),
        ],
      ),
    );
  }
}
