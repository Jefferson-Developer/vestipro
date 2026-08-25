import '../../domain/entities/size_grid_template.dart';

sealed class SizeGridTemplateEvent {
  const SizeGridTemplateEvent();
}

final class SizeGridTemplateStarted extends SizeGridTemplateEvent {
  const SizeGridTemplateStarted({
    required this.organizationId,
    required this.userId,
  });

  final String organizationId;
  final String userId;
}

final class SizeGridTemplateSearchChanged extends SizeGridTemplateEvent {
  const SizeGridTemplateSearchChanged(this.query);

  final String query;
}

final class SizeGridTemplateCreateRequested extends SizeGridTemplateEvent {
  const SizeGridTemplateCreateRequested();
}

final class SizeGridTemplateEditRequested extends SizeGridTemplateEvent {
  const SizeGridTemplateEditRequested(this.template);

  final SizeGridTemplate template;
}

final class SizeGridTemplateFormChanged extends SizeGridTemplateEvent {
  const SizeGridTemplateFormChanged({
    required this.name,
    required this.sizesInput,
  });

  final String name;
  final String sizesInput;
}

final class SizeGridTemplateSubmitted extends SizeGridTemplateEvent {
  const SizeGridTemplateSubmitted({
    this.confirmPublishedProductImpact = false,
    this.confirmVariantUsage = false,
  });

  final bool confirmPublishedProductImpact;
  final bool confirmVariantUsage;
}

final class SizeGridTemplateDuplicateRequested extends SizeGridTemplateEvent {
  const SizeGridTemplateDuplicateRequested(this.template);

  final SizeGridTemplate template;
}

final class SizeGridTemplateReordered extends SizeGridTemplateEvent {
  const SizeGridTemplateReordered({
    required this.templateId,
    required this.orderedSizeIds,
    this.confirmPublishedProductImpact = false,
  });

  final String templateId;
  final List<String> orderedSizeIds;
  final bool confirmPublishedProductImpact;
}

final class SizeGridTemplateConfirmationAccepted extends SizeGridTemplateEvent {
  const SizeGridTemplateConfirmationAccepted();
}
