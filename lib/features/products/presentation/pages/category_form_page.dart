import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/category.dart';
import '../bloc/category_form_bloc.dart';
import '../bloc/category_form_event.dart';
import '../bloc/category_form_state.dart';

/// Create/edit bottom sheet for `Category` (TASK-067): name and an optional
/// parent picked from the rest of the organization's tree, excluding the
/// Category itself and any of its descendants (a cycle `UpdateCategoryUseCase`
/// would reject anyway). RBAC is enforced by the caller (`CategoriesPage`,
/// gated by `Capability.catalogManage`) — this sheet carries no permission
/// check of its own, the same split `SeasonFormPage`/`CollectionFormPage`
/// already apply.
class CategoryFormPage {
  const CategoryFormPage._();

  static Future<Category?> showBottomSheet({
    required BuildContext context,
    required String organizationId,
    required String userId,
    required CategoryFormBloc Function() createBloc,
    Category? initialCategory,
    String? initialParentId,
  }) {
    return AppBottomSheet.show<Category>(
      context: context,
      title: initialCategory == null ? 'Nova categoria' : 'Editar categoria',
      closeSemanticLabel: 'Fechar formulário de categoria',
      builder: (_) => BlocProvider<CategoryFormBloc>(
        create: (_) => createBloc()
          ..add(
            CategoryFormStarted(
              organizationId: organizationId,
              userId: userId,
              initialCategory: initialCategory,
              initialParentId: initialParentId,
            ),
          ),
        child: const _CategoryFormView(),
      ),
    );
  }
}

class _CategoryFormView extends StatelessWidget {
  const _CategoryFormView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CategoryFormBloc, CategoryFormState>(
      listenWhen: (previous, current) =>
          previous.submissionStatus != current.submissionStatus,
      listener: (context, state) {
        if (state.submissionStatus == CategoryFormSubmissionStatus.failure) {
          AppSnackbar.show(
            context,
            message: state.failure?.message ?? 'Revise os campos da categoria.',
            variant: AppSnackbarVariant.error,
          );
        }
        if (state.submissionStatus == CategoryFormSubmissionStatus.success &&
            state.savedCategory != null) {
          AppSnackbar.show(
            context,
            message: 'Categoria salva.',
            variant: AppSnackbarVariant.success,
          );
          Navigator.of(context).pop(state.savedCategory);
        }
      },
      builder: (context, state) {
        return switch (state.loadStatus) {
          CategoryFormLoadStatus.loading => const Padding(
            padding: EdgeInsets.all(AppSpacing.spacing24),
            child: Center(child: CircularProgressIndicator()),
          ),
          CategoryFormLoadStatus.failure => AppErrorState(
            title: 'Não foi possível carregar as categorias',
            message: state.failure?.message ?? 'Tente novamente em breve.',
          ),
          CategoryFormLoadStatus.ready => _CategoryFormContent(state: state),
        };
      },
    );
  }
}

class _CategoryFormContent extends StatelessWidget {
  const _CategoryFormContent({required this.state});

  final CategoryFormState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CategoryFormBloc>();
    final isSubmitting = state.isSubmitting;

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _CategoryNameField(
              name: state.name,
              isDisabled: isSubmitting,
              errorText: state.fieldErrors['name'],
              onChanged: (value) => bloc.add(CategoryFormNameChanged(value)),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            AppDropdown<String>(
              label: 'Categoria pai',
              hintText: 'Nenhuma (categoria de nível principal)',
              options: state.availableParents
                  .map(
                    (category) => AppDropdownOption<String>(
                      value: category.id,
                      label: category.name,
                    ),
                  )
                  .toList(growable: false),
              selectedValues: state.parentId == null
                  ? const <String>{}
                  : <String>{state.parentId!},
              onChanged: isSubmitting
                  ? (_) {}
                  : (selected) => bloc.add(
                      CategoryFormParentSelected(
                        selected.isEmpty ? null : selected.first,
                      ),
                    ),
              closeSemanticLabel: 'Fechar seleção de categoria pai',
              searchHintText: 'Buscar categoria',
              noResultsLabel: 'Nenhuma categoria encontrada',
              errorText: state.fieldErrors['parentId'],
              isDisabled: isSubmitting,
            ),
            const SizedBox(height: AppSpacing.spacing24),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                label: state.isEditing
                    ? 'Salvar alterações'
                    : 'Criar categoria',
                leadingIcon: Icons.save_outlined,
                isLoading: isSubmitting,
                onPressed: isSubmitting
                    ? null
                    : () => bloc.add(const CategoryFormSubmitted()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryNameField extends StatefulWidget {
  const _CategoryNameField({
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
  State<_CategoryNameField> createState() => _CategoryNameFieldState();
}

class _CategoryNameFieldState extends State<_CategoryNameField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.name);
  }

  @override
  void didUpdateWidget(covariant _CategoryNameField oldWidget) {
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
      label: 'Nome da categoria',
      hintText: 'Ex.: Feminino, Calças, Camisetas',
      isRequired: true,
      isDisabled: widget.isDisabled,
      errorText: widget.errorText,
      textInputAction: TextInputAction.done,
      onChanged: widget.onChanged,
    );
  }
}
