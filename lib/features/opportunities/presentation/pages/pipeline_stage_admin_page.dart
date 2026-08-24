import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/pipeline_stage.dart';
import '../../domain/value_objects/pipeline_stage_terminal_type.dart';
import '../bloc/pipeline_stage_admin_bloc.dart';
import '../bloc/pipeline_stage_admin_event.dart';
import '../bloc/pipeline_stage_admin_state.dart';

/// Preset color indicators offered when creating/renaming a stage — a
/// bounded palette (rather than a free hex field) so every stage color
/// stays legible against the Design System surfaces in both themes.
const List<(String label, String hex)> pipelineStageColorPresets =
    <(String, String)>[
      ('Azul', '#2563EB'),
      ('Verde', '#16A34A'),
      ('Laranja', '#F97316'),
      ('Vermelho', '#DC2626'),
      ('Roxo', '#7C3AED'),
      ('Cinza', '#6B7280'),
      ('Amarelo', '#CA8A04'),
      ('Rosa', '#DB2777'),
    ];

/// Administrative screen for the sales pipeline's [PipelineStage]s
/// (TASK-058): create, rename and drag-to-reorder, gated by
/// [Capability.pipelineStageManage] (OWNER/ADMIN/SALES_MANAGER only, see
/// `RolePermissionMatrix`).
class PipelineStageAdminPage extends StatelessWidget {
  const PipelineStageAdminPage({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    super.key,
  });

  final String organizationId;
  final String userId;
  final PermissionService permissionService;
  final PipelineStageAdminBloc Function() createBloc;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.pipelineStageManage,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<PipelineStageAdminBloc>(
          create: (_) => createBloc()
            ..add(
              PipelineStageAdminStarted(
                organizationId: organizationId,
                userId: userId,
              ),
            ),
          child: const _PipelineStageAdminScaffold(),
        );
      },
    );
  }
}

class _PipelineStageAdminScaffold extends StatelessWidget {
  const _PipelineStageAdminScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppAdminPageLayout(
        title: 'Estágios do funil',
        actions: <Widget>[
          AppButton(
            label: 'Novo estágio',
            leadingIcon: Icons.add,
            onPressed: () => _promptCreate(context),
          ),
        ],
        content: const _PipelineStageAdminContent(),
      ),
    );
  }

  Future<void> _promptCreate(BuildContext context) async {
    final bloc = context.read<PipelineStageAdminBloc>();
    final result = await _StageFormDialog.show(context);
    if (result == null) return;
    bloc.add(
      PipelineStageAdminStageCreated(
        name: result.name,
        colorHex: result.colorHex,
        terminalType: result.terminalType,
      ),
    );
  }
}

class _PipelineStageAdminContent extends StatelessWidget {
  const _PipelineStageAdminContent();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PipelineStageAdminBloc, PipelineStageAdminState>(
      listenWhen: (previous, current) =>
          previous.actionStatus != current.actionStatus &&
          current.actionStatus == PipelineStageAdminActionStatus.failure,
      listener: (context, state) {
        AppSnackbar.show(
          context,
          message:
              state.actionFailure?.message ??
              'Nao foi possivel salvar o estagio.',
          variant: AppSnackbarVariant.error,
        );
        context.read<PipelineStageAdminBloc>().add(
          const PipelineStageAdminActionDismissed(),
        );
      },
      builder: (context, state) {
        if (state.status == PipelineStageAdminLoadStatus.failure) {
          return AppErrorState(
            title: 'Nao foi possivel carregar os estagios',
            message: state.failure?.message ?? 'Tente novamente em breve.',
            retryLabel: 'Tentar novamente',
            onRetry: () => context.read<PipelineStageAdminBloc>().add(
              const PipelineStageAdminRetried(),
            ),
          );
        }
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.stages.isEmpty) {
          return const AppEmptyState(
            title: 'Nenhum estagio configurado',
            description: 'Crie o primeiro estagio do funil de vendas.',
            icon: Icons.view_column_outlined,
          );
        }

        final stages = List<PipelineStage>.of(state.stages)
          ..sort((a, b) => a.order.compareTo(b.order));

        return ReorderableListView.builder(
          itemCount: stages.length,
          itemBuilder: (context, index) => _StageAdminTile(
            key: ValueKey<String>(stages[index].id),
            stage: stages[index],
          ),
          onReorderItem: (oldIndex, newIndex) =>
              _handleReorder(context, stages, oldIndex, newIndex),
        );
      },
    );
  }

  void _handleReorder(
    BuildContext context,
    List<PipelineStage> stages,
    int oldIndex,
    int newIndex,
  ) {
    // `onReorderItem` already adjusts `newIndex` for the removed item at
    // `oldIndex` (unlike the deprecated `onReorder`), so no manual `-1`
    // correction is needed here.
    final reordered = List<PipelineStage>.of(stages);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    context.read<PipelineStageAdminBloc>().add(
      PipelineStageAdminStagesReordered(
        reordered.map((stage) => stage.id).toList(growable: false),
      ),
    );
  }
}

class _StageAdminTile extends StatelessWidget {
  const _StageAdminTile({required this.stage, super.key});

  final PipelineStage stage;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: AppSpacing.spacing8),
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        border: Border.all(color: colors.outline.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.drag_handle, color: colors.outline),
          const SizedBox(width: AppSpacing.spacing12),
          _ColorDot(hex: stage.colorHex),
          const SizedBox(width: AppSpacing.spacing12),
          Expanded(
            child: Text(
              stage.name,
              style: AppTypography.titleMedium.copyWith(
                color: colors.onSurface,
              ),
            ),
          ),
          if (stage.isTerminal) ...<Widget>[
            AppStatusBadge(
              label: pipelineStageTerminalTypeLabel(stage.terminalType),
              variant: stage.terminalType == PipelineStageTerminalType.won
                  ? AppStatusBadgeVariant.success
                  : AppStatusBadgeVariant.error,
            ),
            const SizedBox(width: AppSpacing.spacing12),
          ],
          AppButton(
            label: 'Editar',
            variant: AppButtonVariant.text,
            onPressed: () => _promptRename(context),
          ),
        ],
      ),
    );
  }

  Future<void> _promptRename(BuildContext context) async {
    final bloc = context.read<PipelineStageAdminBloc>();
    final result = await _StageFormDialog.show(context, stage: stage);
    if (result == null) return;
    bloc.add(
      PipelineStageAdminStageRenamed(
        stageId: stage.id,
        name: result.name,
        colorHex: result.colorHex,
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.hex});

  final String hex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: Color(int.parse('FF${hex.substring(1)}', radix: 16)),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Result of [_StageFormDialog]: the caller decides whether to dispatch a
/// create or a rename event depending on which flow opened it.
class _StageFormResult {
  const _StageFormResult({
    required this.name,
    required this.colorHex,
    required this.terminalType,
  });

  final String name;
  final String colorHex;
  final PipelineStageTerminalType terminalType;
}

class _StageFormDialog extends StatefulWidget {
  const _StageFormDialog({this.stage});

  final PipelineStage? stage;

  static Future<_StageFormResult?> show(
    BuildContext context, {
    PipelineStage? stage,
  }) {
    return showDialog<_StageFormResult>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _StageFormDialog(stage: stage),
    );
  }

  @override
  State<_StageFormDialog> createState() => _StageFormDialogState();
}

class _StageFormDialogState extends State<_StageFormDialog> {
  late final TextEditingController _nameController;
  late String _colorHex;
  late PipelineStageTerminalType _terminalType;
  String? _nameError;

  bool get _isEditing => widget.stage != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.stage?.name ?? '');
    _colorHex = widget.stage?.colorHex ?? pipelineStageColorPresets.first.$2;
    _terminalType =
        widget.stage?.terminalType ?? PipelineStageTerminalType.none;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _confirm() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Informe o nome do estagio.');
      return;
    }
    Navigator.of(context).pop(
      _StageFormResult(
        name: name,
        colorHex: _colorHex,
        terminalType: _terminalType,
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
              Text(
                _isEditing ? 'Editar estagio' : 'Novo estagio',
                style: AppTypography.titleLarge.copyWith(
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing16),
              AppTextField(
                controller: _nameController,
                label: 'Nome',
                hintText: 'Ex.: Negociacao',
                semanticLabel: 'Nome do estagio',
                isRequired: true,
                errorText: _nameError,
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
              ),
              const SizedBox(height: AppSpacing.spacing16),
              AppDropdown<String>(
                label: 'Cor',
                closeSemanticLabel: 'Fechar selecao de cor',
                enableSearch: false,
                options: pipelineStageColorPresets
                    .map(
                      (preset) => AppDropdownOption<String>(
                        value: preset.$2,
                        label: preset.$1,
                      ),
                    )
                    .toList(growable: false),
                selectedValues: <String>{_colorHex},
                onChanged: (selected) {
                  if (selected.isEmpty) return;
                  setState(() => _colorHex = selected.first);
                },
              ),
              if (!_isEditing) ...<Widget>[
                const SizedBox(height: AppSpacing.spacing16),
                AppDropdown<PipelineStageTerminalType>(
                  label: 'Tipo',
                  closeSemanticLabel: 'Fechar selecao de tipo',
                  enableSearch: false,
                  options: PipelineStageTerminalType.values
                      .map(
                        (type) => AppDropdownOption<PipelineStageTerminalType>(
                          value: type,
                          label: pipelineStageTerminalTypeLabel(type),
                        ),
                      )
                      .toList(growable: false),
                  selectedValues: <PipelineStageTerminalType>{_terminalType},
                  onChanged: (selected) {
                    if (selected.isEmpty) return;
                    setState(() => _terminalType = selected.first);
                  },
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

/// Human-readable label for [PipelineStageTerminalType], reused by the
/// admin form and the terminal badge so the two never drift apart.
String pipelineStageTerminalTypeLabel(PipelineStageTerminalType type) {
  return switch (type) {
    PipelineStageTerminalType.none => 'Estagio normal',
    PipelineStageTerminalType.won => 'Ganho (fechamento)',
    PipelineStageTerminalType.lost => 'Perdido (fechamento)',
  };
}
