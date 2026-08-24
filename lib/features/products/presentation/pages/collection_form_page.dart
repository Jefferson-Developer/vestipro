import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/collection.dart';
import '../bloc/collection_form_bloc.dart';
import '../bloc/collection_form_event.dart';
import '../bloc/collection_form_state.dart';

/// Create/edit bottom sheet for `Collection` (TASK-066): name, season
/// (picked from the same `Season` vocabulary `SeasonsPage` manages), year
/// and an optional start/end date range. RBAC is enforced by the caller
/// (`CollectionsPage`, gated by `Capability.catalogManage`).
class CollectionFormPage {
  const CollectionFormPage._();

  static Future<Collection?> showBottomSheet({
    required BuildContext context,
    required String organizationId,
    required String userId,
    required CollectionFormBloc Function() createBloc,
    Collection? initialCollection,
  }) {
    return AppBottomSheet.show<Collection>(
      context: context,
      title: initialCollection == null ? 'Nova coleção' : 'Editar coleção',
      closeSemanticLabel: 'Fechar formulário de coleção',
      builder: (_) => BlocProvider<CollectionFormBloc>(
        create: (_) => createBloc()
          ..add(
            CollectionFormStarted(
              organizationId: organizationId,
              userId: userId,
              initialCollection: initialCollection,
            ),
          ),
        child: const _CollectionFormView(),
      ),
    );
  }
}

class _CollectionFormView extends StatelessWidget {
  const _CollectionFormView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CollectionFormBloc, CollectionFormState>(
      listenWhen: (previous, current) =>
          previous.submissionStatus != current.submissionStatus,
      listener: (context, state) {
        if (state.submissionStatus == CollectionFormSubmissionStatus.failure) {
          AppSnackbar.show(
            context,
            message: state.failure?.message ?? 'Revise os campos da coleção.',
            variant: AppSnackbarVariant.error,
          );
        }
        if (state.submissionStatus == CollectionFormSubmissionStatus.success &&
            state.savedCollection != null) {
          AppSnackbar.show(
            context,
            message: 'Coleção salva.',
            variant: AppSnackbarVariant.success,
          );
          Navigator.of(context).pop(state.savedCollection);
        }
      },
      builder: (context, state) {
        return switch (state.loadStatus) {
          CollectionFormLoadStatus.loading => const Padding(
            padding: EdgeInsets.all(AppSpacing.spacing24),
            child: Center(child: CircularProgressIndicator()),
          ),
          CollectionFormLoadStatus.failure => AppErrorState(
            title: 'Não foi possível carregar as estações',
            message: state.failure?.message ?? 'Tente novamente em breve.',
          ),
          CollectionFormLoadStatus.ready => _CollectionFormContent(
            state: state,
          ),
        };
      },
    );
  }
}

class _CollectionFormContent extends StatelessWidget {
  const _CollectionFormContent({required this.state});

  final CollectionFormState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CollectionFormBloc>();
    final isSubmitting = state.isSubmitting;

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _CollectionNameField(
              name: state.name,
              isDisabled: isSubmitting,
              errorText: state.fieldErrors['name'],
              onChanged: (value) => bloc.add(CollectionFormNameChanged(value)),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            AppDropdown<String>(
              label: 'Estação',
              hintText: 'Selecione uma estação',
              options: state.seasons
                  .map(
                    (season) => AppDropdownOption<String>(
                      value: season.id,
                      label: season.name,
                    ),
                  )
                  .toList(growable: false),
              selectedValues: state.seasonId == null
                  ? const <String>{}
                  : <String>{state.seasonId!},
              onChanged: isSubmitting
                  ? (_) {}
                  : (selected) => bloc.add(
                      CollectionFormSeasonSelected(
                        selected.isEmpty ? null : selected.first,
                      ),
                    ),
              closeSemanticLabel: 'Fechar seleção de estação',
              searchHintText: 'Buscar estação',
              noResultsLabel: 'Nenhuma estação encontrada',
              errorText: state.fieldErrors['seasonId'],
              isDisabled: isSubmitting,
            ),
            const SizedBox(height: AppSpacing.spacing16),
            _CollectionYearField(
              year: state.year,
              isDisabled: isSubmitting,
              errorText: state.fieldErrors['year'],
              onChanged: (value) => bloc.add(CollectionFormYearChanged(value)),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            _CollectionDateRangeRow(state: state),
            if (state.fieldErrors['endDate'] != null) ...<Widget>[
              const SizedBox(height: AppSpacing.spacing4),
              Text(
                state.fieldErrors['endDate']!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.spacing24),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                label: state.isEditing ? 'Salvar alterações' : 'Criar coleção',
                leadingIcon: Icons.save_outlined,
                isLoading: isSubmitting,
                onPressed: isSubmitting
                    ? null
                    : () => bloc.add(const CollectionFormSubmitted()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionDateRangeRow extends StatelessWidget {
  const _CollectionDateRangeRow({required this.state});

  final CollectionFormState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CollectionFormBloc>();
    final isSubmitting = state.isSubmitting;

    return Row(
      children: <Widget>[
        Expanded(
          child: AppButton(
            label: 'Início: ${_label(state.startDate)}',
            leadingIcon: Icons.event_outlined,
            variant: AppButtonVariant.secondary,
            isDisabled: isSubmitting,
            onPressed: isSubmitting
                ? null
                : () async {
                    final picked = await _pickDate(context, state.startDate);
                    if (picked != null) {
                      bloc.add(CollectionFormStartDateChanged(picked));
                    }
                  },
          ),
        ),
        const SizedBox(width: AppSpacing.spacing12),
        Expanded(
          child: AppButton(
            label: 'Fim: ${_label(state.endDate)}',
            leadingIcon: Icons.event_outlined,
            variant: AppButtonVariant.secondary,
            isDisabled: isSubmitting,
            onPressed: isSubmitting
                ? null
                : () async {
                    final picked = await _pickDate(context, state.endDate);
                    if (picked != null) {
                      bloc.add(CollectionFormEndDateChanged(picked));
                    }
                  },
          ),
        ),
      ],
    );
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime? initial) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 5),
    );
  }

  String _label(DateTime? date) {
    if (date == null) return 'sem data';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _CollectionNameField extends StatefulWidget {
  const _CollectionNameField({
    required this.name,
    required this.isDisabled,
    required this.errorText,
    required this.onChanged,
  });

  final String name;
  final bool isDisabled;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  State<_CollectionNameField> createState() => _CollectionNameFieldState();
}

class _CollectionNameFieldState extends State<_CollectionNameField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.name);
  }

  @override
  void didUpdateWidget(covariant _CollectionNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.name != _controller.text) {
      _controller.text = widget.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      label: 'Nome da coleção',
      hintText: 'Ex.: Verão 2026',
      isRequired: true,
      isDisabled: widget.isDisabled,
      errorText: widget.errorText,
      textInputAction: TextInputAction.next,
      onChanged: widget.onChanged,
    );
  }
}

class _CollectionYearField extends StatefulWidget {
  const _CollectionYearField({
    required this.year,
    required this.isDisabled,
    required this.errorText,
    required this.onChanged,
  });

  final int? year;
  final bool isDisabled;
  final String? errorText;
  final ValueChanged<int?> onChanged;

  @override
  State<_CollectionYearField> createState() => _CollectionYearFieldState();
}

class _CollectionYearFieldState extends State<_CollectionYearField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.year?.toString() ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      label: 'Ano',
      hintText: 'Ex.: 2026',
      isDisabled: widget.isDisabled,
      errorText: widget.errorText,
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final trimmed = value.trim();
        widget.onChanged(trimmed.isEmpty ? null : int.tryParse(trimmed));
      },
    );
  }
}
