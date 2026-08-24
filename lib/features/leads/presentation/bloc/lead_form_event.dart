import '../../domain/value_objects/lead_source.dart';

sealed class LeadFormEvent {
  const LeadFormEvent();
}

final class LeadFormStarted extends LeadFormEvent {
  const LeadFormStarted({
    required this.organizationId,
    this.companyId,
    required this.userId,
    required this.canChooseResponsible,
  });

  final String organizationId;
  final String? companyId;
  final String userId;
  final bool canChooseResponsible;
}

final class LeadFormNameChanged extends LeadFormEvent {
  const LeadFormNameChanged(this.name);

  final String name;
}

final class LeadFormDocumentChanged extends LeadFormEvent {
  const LeadFormDocumentChanged(this.document);

  final String document;
}

final class LeadFormSourceSelected extends LeadFormEvent {
  const LeadFormSourceSelected(this.source);

  final LeadSource source;
}

final class LeadFormCustomSourceLabelChanged extends LeadFormEvent {
  const LeadFormCustomSourceLabelChanged(this.customSourceLabel);

  final String customSourceLabel;
}

final class LeadFormResponsibleSelected extends LeadFormEvent {
  const LeadFormResponsibleSelected(this.responsibleUserId);

  final String? responsibleUserId;
}

final class LeadFormSubmitted extends LeadFormEvent {
  const LeadFormSubmitted();
}
