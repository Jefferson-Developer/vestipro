import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/season.dart';
import '../bloc/season_form_bloc.dart';
import '../bloc/season_form_event.dart';
import '../bloc/season_form_state.dart';

/// Create/edit bottom sheet for `Season` (TASK-066). RBAC is enforced by the
/// caller (`SeasonsPage`, gated by `Capability.catalogManage`) — this sheet
/// carries no permission check of its own, the same split `TeamFormPage`
/// already applies between its full-page form and its `showBottomSheet`
/// entry point.
class SeasonFormPage {
  const SeasonFormPage._();

  static Future<Season?> showBottomSheet({
    required BuildContext context,
    required String organizationId,
    required String userId,
    required SeasonFormBloc Function() createBloc,
    Season? initialSeason,
  }) {
    return AppBottomSheet.show<Season>(
      context: context,
      title: initialSeason == null ? 'Nova estação' : 'Editar estação',
      closeSemanticLabel: 'Fechar formulário de estação',
      builder: (_) => BlocProvider<SeasonFormBloc>(
        create: (_) => createBloc()
          ..add(
            SeasonFormStarted(
              organizationId: organizationId,
              userId: userId,
              initialSeason: initialSeason,
            ),
          ),
        child: const _SeasonFormView(),
      ),
    );
  }
}

class _SeasonFormView extends StatelessWidget {
  const _SeasonFormView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SeasonFormBloc, SeasonFormState>(
      listenWhen: (previous, current) =>
          previous.submissionStatus != current.submissionStatus,
      listener: (context, state) {
        if (state.submissionStatus == SeasonFormSubmissionStatus.failure) {
          AppSnackbar.show(
            context,
            message: state.failure?.message ?? 'Revise os campos da estação.',
            variant: AppSnackbarVariant.error,
          );
        }
        if (state.submissionStatus == SeasonFormSubmissionStatus.success &&
            state.savedSeason != null) {
          AppSnackbar.show(
            context,
            message: 'Estação salva.',
            variant: AppSnackbarVariant.success,
          );
          Navigator.of(context).pop(state.savedSeason);
        }
      },
      builder: (context, state) {
        final bloc = context.read<SeasonFormBloc>();
        final isSubmitting = state.isSubmitting;

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _SeasonNameField(
                  name: state.name,
                  isDisabled: isSubmitting,
                  errorText: state.fieldErrors['name'],
                  onChanged: (value) => bloc.add(SeasonFormNameChanged(value)),
                ),
                const SizedBox(height: AppSpacing.spacing24),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton(
                    label: state.isEditing
                        ? 'Salvar alterações'
                        : 'Criar estação',
                    leadingIcon: Icons.save_outlined,
                    isLoading: isSubmitting,
                    onPressed: isSubmitting
                        ? null
                        : () => bloc.add(const SeasonFormSubmitted()),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SeasonNameField extends StatefulWidget {
  const _SeasonNameField({
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
  State<_SeasonNameField> createState() => _SeasonNameFieldState();
}

class _SeasonNameFieldState extends State<_SeasonNameField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.name);
  }

  @override
  void didUpdateWidget(covariant _SeasonNameField oldWidget) {
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
      label: 'Nome da estação',
      hintText: 'Ex.: Verão, Inverno, Alto Verão',
      isRequired: true,
      isDisabled: widget.isDisabled,
      errorText: widget.errorText,
      textInputAction: TextInputAction.done,
      onChanged: widget.onChanged,
    );
  }
}
