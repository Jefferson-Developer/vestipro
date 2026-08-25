import '../../../../core/errors/errors.dart';
import '../../domain/entities/size_grid_template.dart';

enum SizeGridTemplateLoadStatus { loading, ready, failure }

enum SizeGridTemplateSaveStatus {
  idle,
  editing,
  submitting,
  impactWarning,
  variantUsageWarning,
  success,
  failure,
}

enum SizeGridTemplatePendingAction { submit, reorder }

final class SizeGridTemplateState {
  const SizeGridTemplateState({
    this.loadStatus = SizeGridTemplateLoadStatus.loading,
    this.saveStatus = SizeGridTemplateSaveStatus.idle,
    this.organizationId = '',
    this.userId = '',
    this.templates = const <SizeGridTemplate>[],
    this.searchQuery = '',
    this.editingTemplate,
    this.name = '',
    this.sizesInput = '',
    this.fieldErrors = const <String, String>{},
    this.failure,
    this.pendingAction,
    this.pendingReorderTemplateId,
    this.pendingReorderSizeIds = const <String>[],
    this.pendingPublishedProductImpactConfirmed = false,
  });

  final SizeGridTemplateLoadStatus loadStatus;
  final SizeGridTemplateSaveStatus saveStatus;
  final String organizationId;
  final String userId;
  final List<SizeGridTemplate> templates;
  final String searchQuery;
  final SizeGridTemplate? editingTemplate;
  final String name;
  final String sizesInput;
  final Map<String, String> fieldErrors;
  final Failure? failure;
  final SizeGridTemplatePendingAction? pendingAction;
  final String? pendingReorderTemplateId;
  final List<String> pendingReorderSizeIds;
  final bool pendingPublishedProductImpactConfirmed;

  bool get isEditing => editingTemplate != null;
  bool get isBusy => saveStatus == SizeGridTemplateSaveStatus.submitting;

  List<SizeGridTemplate> get filteredTemplates {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return templates;
    return templates
        .where(
          (template) =>
              template.name.toLowerCase().contains(query) ||
              template.sizes.any(
                (size) => size.label.toLowerCase().contains(query),
              ),
        )
        .toList(growable: false);
  }

  SizeGridTemplateState copyWith({
    SizeGridTemplateLoadStatus? loadStatus,
    SizeGridTemplateSaveStatus? saveStatus,
    String? organizationId,
    String? userId,
    List<SizeGridTemplate>? templates,
    String? searchQuery,
    SizeGridTemplate? editingTemplate,
    String? name,
    String? sizesInput,
    Map<String, String>? fieldErrors,
    Failure? failure,
    SizeGridTemplatePendingAction? pendingAction,
    String? pendingReorderTemplateId,
    List<String>? pendingReorderSizeIds,
    bool? pendingPublishedProductImpactConfirmed,
    bool clearEditingTemplate = false,
    bool clearFieldErrors = false,
    bool clearFailure = false,
    bool clearPendingAction = false,
  }) {
    return SizeGridTemplateState(
      loadStatus: loadStatus ?? this.loadStatus,
      saveStatus: saveStatus ?? this.saveStatus,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      templates: templates ?? this.templates,
      searchQuery: searchQuery ?? this.searchQuery,
      editingTemplate: clearEditingTemplate
          ? null
          : editingTemplate ?? this.editingTemplate,
      name: name ?? this.name,
      sizesInput: sizesInput ?? this.sizesInput,
      fieldErrors: clearFieldErrors
          ? const <String, String>{}
          : fieldErrors ?? this.fieldErrors,
      failure: clearFailure ? null : failure ?? this.failure,
      pendingAction: clearPendingAction
          ? null
          : pendingAction ?? this.pendingAction,
      pendingReorderTemplateId: clearPendingAction
          ? null
          : pendingReorderTemplateId ?? this.pendingReorderTemplateId,
      pendingReorderSizeIds: clearPendingAction
          ? const <String>[]
          : pendingReorderSizeIds ?? this.pendingReorderSizeIds,
      pendingPublishedProductImpactConfirmed:
          pendingPublishedProductImpactConfirmed ??
          this.pendingPublishedProductImpactConfirmed,
    );
  }
}
