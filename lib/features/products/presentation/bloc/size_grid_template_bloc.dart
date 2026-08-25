import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/size_grid_template.dart';
import '../../domain/usecases/create_size_grid_template_use_case.dart';
import '../../domain/usecases/duplicate_size_grid_template_use_case.dart';
import '../../domain/usecases/list_size_grid_templates_use_case.dart';
import '../../domain/usecases/reorder_size_grid_template_sizes_use_case.dart';
import '../../domain/usecases/update_size_grid_template_use_case.dart';
import 'size_grid_template_event.dart';
import 'size_grid_template_state.dart';

@injectable
final class SizeGridTemplateBloc
    extends Bloc<SizeGridTemplateEvent, SizeGridTemplateState> {
  SizeGridTemplateBloc({
    required this.listSizeGridTemplates,
    required this.createSizeGridTemplate,
    required this.updateSizeGridTemplate,
    required this.duplicateSizeGridTemplate,
    required this.reorderSizeGridTemplateSizes,
  }) : super(const SizeGridTemplateState()) {
    on<SizeGridTemplateStarted>(_onStarted, transformer: restartable());
    on<SizeGridTemplateSearchChanged>(
      _onSearchChanged,
      transformer: sequential(),
    );
    on<SizeGridTemplateCreateRequested>(
      _onCreateRequested,
      transformer: sequential(),
    );
    on<SizeGridTemplateEditRequested>(
      _onEditRequested,
      transformer: sequential(),
    );
    on<SizeGridTemplateFormChanged>(_onFormChanged, transformer: sequential());
    on<SizeGridTemplateSubmitted>(_onSubmitted, transformer: droppable());
    on<SizeGridTemplateDuplicateRequested>(
      _onDuplicateRequested,
      transformer: droppable(),
    );
    on<SizeGridTemplateReordered>(_onReordered, transformer: droppable());
    on<SizeGridTemplateConfirmationAccepted>(
      _onConfirmationAccepted,
      transformer: droppable(),
    );
  }

  final ListSizeGridTemplatesUseCase listSizeGridTemplates;
  final CreateSizeGridTemplateUseCase createSizeGridTemplate;
  final UpdateSizeGridTemplateUseCase updateSizeGridTemplate;
  final DuplicateSizeGridTemplateUseCase duplicateSizeGridTemplate;
  final ReorderSizeGridTemplateSizesUseCase reorderSizeGridTemplateSizes;
  final Uuid _uuid = const Uuid();

  Future<void> _onStarted(
    SizeGridTemplateStarted event,
    Emitter<SizeGridTemplateState> emit,
  ) async {
    emit(
      state.copyWith(
        loadStatus: SizeGridTemplateLoadStatus.loading,
        organizationId: event.organizationId,
        userId: event.userId,
        clearFailure: true,
      ),
    );
    await _load(emit);
  }

  Future<void> _load(Emitter<SizeGridTemplateState> emit) async {
    final result = await listSizeGridTemplates(state.organizationId);
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<List<SizeGridTemplate>>(value: final templates):
        emit(
          state.copyWith(
            loadStatus: SizeGridTemplateLoadStatus.ready,
            templates: templates,
            clearFailure: true,
          ),
        );
      case AppFailure<List<SizeGridTemplate>>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: SizeGridTemplateLoadStatus.failure,
            failure: failure,
          ),
        );
    }
  }

  void _onSearchChanged(
    SizeGridTemplateSearchChanged event,
    Emitter<SizeGridTemplateState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onCreateRequested(
    SizeGridTemplateCreateRequested event,
    Emitter<SizeGridTemplateState> emit,
  ) {
    emit(
      state.copyWith(
        saveStatus: SizeGridTemplateSaveStatus.editing,
        name: '',
        sizesInput: 'PP\nP\nM\nG\nGG\nXGG',
        clearEditingTemplate: true,
        clearFieldErrors: true,
        clearFailure: true,
        clearPendingAction: true,
      ),
    );
  }

  void _onEditRequested(
    SizeGridTemplateEditRequested event,
    Emitter<SizeGridTemplateState> emit,
  ) {
    emit(
      state.copyWith(
        saveStatus: SizeGridTemplateSaveStatus.editing,
        editingTemplate: event.template,
        name: event.template.name,
        sizesInput: event.template.orderedSizes
            .map((size) => size.label)
            .join('\n'),
        clearFieldErrors: true,
        clearFailure: true,
        clearPendingAction: true,
      ),
    );
  }

  void _onFormChanged(
    SizeGridTemplateFormChanged event,
    Emitter<SizeGridTemplateState> emit,
  ) {
    emit(
      state.copyWith(
        saveStatus: SizeGridTemplateSaveStatus.editing,
        name: event.name,
        sizesInput: event.sizesInput,
        clearFieldErrors: true,
        clearFailure: true,
        clearPendingAction: true,
      ),
    );
  }

  Future<void> _onSubmitted(
    SizeGridTemplateSubmitted event,
    Emitter<SizeGridTemplateState> emit,
  ) async {
    await _submit(
      emit,
      confirmPublishedProductImpact: event.confirmPublishedProductImpact,
      confirmVariantUsage: event.confirmVariantUsage,
    );
  }

  Future<void> _submit(
    Emitter<SizeGridTemplateState> emit, {
    required bool confirmPublishedProductImpact,
    required bool confirmVariantUsage,
  }) async {
    emit(
      state.copyWith(
        saveStatus: SizeGridTemplateSaveStatus.submitting,
        pendingAction: SizeGridTemplatePendingAction.submit,
        pendingPublishedProductImpactConfirmed: confirmPublishedProductImpact,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );
    final sizes = _sizesFromInput();
    final result = state.editingTemplate == null
        ? await createSizeGridTemplate(
            id: _uuid.v4(),
            organizationId: state.organizationId,
            name: state.name,
            sizes: sizes,
            createdBy: state.userId,
          )
        : await updateSizeGridTemplate(
            organizationId: state.organizationId,
            id: state.editingTemplate!.id,
            name: state.name,
            sizes: sizes,
            updatedBy: state.userId,
            confirmPublishedProductImpact: confirmPublishedProductImpact,
            confirmVariantUsage: confirmVariantUsage,
          );
    if (emit.isDone) return;
    await _handleMutationResult(result, emit);
  }

  Future<void> _onDuplicateRequested(
    SizeGridTemplateDuplicateRequested event,
    Emitter<SizeGridTemplateState> emit,
  ) async {
    emit(
      state.copyWith(
        saveStatus: SizeGridTemplateSaveStatus.submitting,
        clearFieldErrors: true,
        clearFailure: true,
        clearPendingAction: true,
      ),
    );
    final result = await duplicateSizeGridTemplate(
      sourceTemplateId: event.template.id,
      newTemplateId: _uuid.v4(),
      newSizeIds: List<String>.generate(
        event.template.sizes.length,
        (_) => _uuid.v4(),
      ),
      organizationId: state.organizationId,
      createdBy: state.userId,
      targetName: _duplicateNameFor(event.template.name),
    );
    if (emit.isDone) return;
    await _handleMutationResult(result, emit);
  }

  Future<void> _onReordered(
    SizeGridTemplateReordered event,
    Emitter<SizeGridTemplateState> emit,
  ) async {
    await _reorder(
      emit,
      templateId: event.templateId,
      orderedSizeIds: event.orderedSizeIds,
      confirmPublishedProductImpact: event.confirmPublishedProductImpact,
    );
  }

  Future<void> _reorder(
    Emitter<SizeGridTemplateState> emit, {
    required String templateId,
    required List<String> orderedSizeIds,
    required bool confirmPublishedProductImpact,
  }) async {
    emit(
      state.copyWith(
        saveStatus: SizeGridTemplateSaveStatus.submitting,
        pendingAction: SizeGridTemplatePendingAction.reorder,
        pendingReorderTemplateId: templateId,
        pendingReorderSizeIds: orderedSizeIds,
        pendingPublishedProductImpactConfirmed: confirmPublishedProductImpact,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );
    final result = await reorderSizeGridTemplateSizes(
      organizationId: state.organizationId,
      templateId: templateId,
      orderedSizeIds: orderedSizeIds,
      updatedBy: state.userId,
      confirmPublishedProductImpact: confirmPublishedProductImpact,
    );
    if (emit.isDone) return;
    await _handleMutationResult(result, emit);
  }

  Future<void> _onConfirmationAccepted(
    SizeGridTemplateConfirmationAccepted event,
    Emitter<SizeGridTemplateState> emit,
  ) async {
    switch (state.pendingAction) {
      case SizeGridTemplatePendingAction.submit:
        await _submit(
          emit,
          confirmPublishedProductImpact: true,
          confirmVariantUsage:
              state.saveStatus ==
              SizeGridTemplateSaveStatus.variantUsageWarning,
        );
      case SizeGridTemplatePendingAction.reorder:
        final templateId = state.pendingReorderTemplateId;
        if (templateId == null) return;
        await _reorder(
          emit,
          templateId: templateId,
          orderedSizeIds: state.pendingReorderSizeIds,
          confirmPublishedProductImpact: true,
        );
      case null:
        return;
    }
  }

  Future<void> _handleMutationResult(
    AppResult<SizeGridTemplate> result,
    Emitter<SizeGridTemplateState> emit,
  ) async {
    switch (result) {
      case AppSuccess<SizeGridTemplate>():
        emit(
          state.copyWith(
            saveStatus: SizeGridTemplateSaveStatus.success,
            clearEditingTemplate: true,
            clearFieldErrors: true,
            clearFailure: true,
            clearPendingAction: true,
            pendingPublishedProductImpactConfirmed: false,
          ),
        );
        await _load(emit);
      case AppFailure<SizeGridTemplate>(failure: final failure):
        if (failure is ConflictFailure &&
            failure.code ==
                'size_grid_template_product_impact_confirmation_required') {
          emit(
            state.copyWith(
              saveStatus: SizeGridTemplateSaveStatus.impactWarning,
              failure: failure,
            ),
          );
          return;
        }
        if (failure is ConflictFailure &&
            failure.code ==
                'size_grid_template_size_usage_confirmation_required') {
          emit(
            state.copyWith(
              saveStatus: SizeGridTemplateSaveStatus.variantUsageWarning,
              failure: failure,
            ),
          );
          return;
        }
        emit(
          state.copyWith(
            saveStatus: SizeGridTemplateSaveStatus.failure,
            failure: failure,
            fieldErrors: failure is ValidationFailure
                ? failure.fieldErrors
                : const <String, String>{},
            clearPendingAction: true,
          ),
        );
    }
  }

  List<SizeGridSize> _sizesFromInput() {
    final existingByLabel = <String, SizeGridSize>{
      for (final size in state.editingTemplate?.sizes ?? const <SizeGridSize>[])
        size.label.trim().toLowerCase(): size,
    };
    final labels = state.sizesInput
        .split(RegExp(r'[\n,/]+'))
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList(growable: false);
    return labels.indexed
        .map((entry) {
          final (index, label) = entry;
          final existing = existingByLabel[label.toLowerCase()];
          return SizeGridSize(
            id: existing?.id ?? _uuid.v4(),
            organizationId: state.organizationId,
            label: label,
            orderScore: index + 1,
          );
        })
        .toList(growable: false);
  }

  String _duplicateNameFor(String sourceName) {
    final base = '$sourceName cópia';
    final names = state.templates.map((template) => template.name).toSet();
    if (!names.contains(base)) return base;
    var suffix = 2;
    while (names.contains('$base $suffix')) {
      suffix++;
    }
    return '$base $suffix';
  }
}
