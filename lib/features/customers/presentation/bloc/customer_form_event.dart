import '../../domain/entities/customer.dart';
import '../../domain/value_objects/customer_type.dart';

sealed class CustomerFormEvent {
  const CustomerFormEvent();
}

final class CustomerFormStarted extends CustomerFormEvent {
  const CustomerFormStarted({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.canChooseResponsibleSeller,
    this.initialCustomer,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final bool canChooseResponsibleSeller;
  final Customer? initialCustomer;
}

final class CustomerFormTypeChanged extends CustomerFormEvent {
  const CustomerFormTypeChanged(this.type);

  final CustomerType type;
}

final class CustomerFormDocumentChanged extends CustomerFormEvent {
  const CustomerFormDocumentChanged(this.document);

  final String document;
}

final class CustomerFormLegalNameChanged extends CustomerFormEvent {
  const CustomerFormLegalNameChanged(this.legalName);

  final String legalName;
}

final class CustomerFormTradeNameChanged extends CustomerFormEvent {
  const CustomerFormTradeNameChanged(this.tradeName);

  final String tradeName;
}

final class CustomerFormFullNameChanged extends CustomerFormEvent {
  const CustomerFormFullNameChanged(this.fullName);

  final String fullName;
}

final class CustomerFormStateRegistrationChanged extends CustomerFormEvent {
  const CustomerFormStateRegistrationChanged(this.stateRegistration);

  final String stateRegistration;
}

final class CustomerFormPrimaryEmailChanged extends CustomerFormEvent {
  const CustomerFormPrimaryEmailChanged(this.primaryEmail);

  final String primaryEmail;
}

final class CustomerFormPrimaryPhoneChanged extends CustomerFormEvent {
  const CustomerFormPrimaryPhoneChanged(this.primaryPhone);

  final String primaryPhone;
}

final class CustomerFormClassificationChanged extends CustomerFormEvent {
  const CustomerFormClassificationChanged(this.classification);

  final String classification;
}

final class CustomerFormPotentialChanged extends CustomerFormEvent {
  const CustomerFormPotentialChanged(this.potential);

  final String potential;
}

final class CustomerFormResponsibleSellerSelected extends CustomerFormEvent {
  const CustomerFormResponsibleSellerSelected(this.responsibleSellerId);

  final String? responsibleSellerId;
}

final class CustomerFormDraftSaved extends CustomerFormEvent {
  const CustomerFormDraftSaved();
}

final class CustomerFormSubmitted extends CustomerFormEvent {
  const CustomerFormSubmitted();
}
