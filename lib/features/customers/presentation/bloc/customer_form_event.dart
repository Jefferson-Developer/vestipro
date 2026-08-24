import '../../domain/entities/customer.dart';
import '../../domain/value_objects/customer_address_type.dart';
import '../../domain/value_objects/customer_contact_type.dart';
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

final class CustomerFormAddressAdded extends CustomerFormEvent {
  const CustomerFormAddressAdded({
    required this.type,
    required this.street,
    this.number,
    this.complement,
    this.district,
    required this.city,
    required this.state,
    required this.zipCode,
    this.country = 'BR',
    this.isPrimary = false,
  });

  final CustomerAddressType type;
  final String street;
  final String? number;
  final String? complement;
  final String? district;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final bool isPrimary;
}

final class CustomerFormAddressUpdated extends CustomerFormEvent {
  const CustomerFormAddressUpdated({
    required this.addressId,
    required this.type,
    required this.street,
    this.number,
    this.complement,
    this.district,
    required this.city,
    required this.state,
    required this.zipCode,
    this.country = 'BR',
    this.isPrimary = false,
  });

  final String addressId;
  final CustomerAddressType type;
  final String street;
  final String? number;
  final String? complement;
  final String? district;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final bool isPrimary;
}

final class CustomerFormAddressRemoved extends CustomerFormEvent {
  const CustomerFormAddressRemoved(this.addressId);

  final String addressId;
}

final class CustomerFormPrimaryAddressSelected extends CustomerFormEvent {
  const CustomerFormPrimaryAddressSelected(this.addressId);

  final String addressId;
}

final class CustomerFormContactAdded extends CustomerFormEvent {
  const CustomerFormContactAdded({
    required this.type,
    required this.name,
    this.role,
    this.phone,
    this.email,
    this.isPrimary = false,
  });

  final CustomerContactType type;
  final String name;
  final String? role;
  final String? phone;
  final String? email;
  final bool isPrimary;
}

final class CustomerFormContactUpdated extends CustomerFormEvent {
  const CustomerFormContactUpdated({
    required this.contactId,
    required this.type,
    required this.name,
    this.role,
    this.phone,
    this.email,
    this.isPrimary = false,
  });

  final String contactId;
  final CustomerContactType type;
  final String name;
  final String? role;
  final String? phone;
  final String? email;
  final bool isPrimary;
}

final class CustomerFormContactRemoved extends CustomerFormEvent {
  const CustomerFormContactRemoved(this.contactId);

  final String contactId;
}

final class CustomerFormPrimaryContactSelected extends CustomerFormEvent {
  const CustomerFormPrimaryContactSelected(this.contactId);

  final String contactId;
}

final class CustomerFormDraftSaved extends CustomerFormEvent {
  const CustomerFormDraftSaved();
}

final class CustomerFormSubmitted extends CustomerFormEvent {
  const CustomerFormSubmitted();
}
