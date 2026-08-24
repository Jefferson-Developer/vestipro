import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../organizations/organizations.dart';
import '../../../users/users.dart';
import '../../domain/customer_address_contact_rules.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_address.dart';
import '../../domain/entities/customer_contact.dart';
import '../../domain/entities/customer_form_config.dart';
import '../../domain/entities/customer_form_draft.dart';
import '../../domain/usecases/clear_customer_form_draft_use_case.dart';
import '../../domain/usecases/create_customer_use_case.dart';
import '../../domain/usecases/get_customer_form_config_use_case.dart';
import '../../domain/usecases/get_customer_form_draft_use_case.dart';
import '../../domain/usecases/save_customer_form_draft_use_case.dart';
import '../../domain/usecases/update_customer_use_case.dart';
import '../../domain/value_objects/cnpj_cpf.dart';
import '../../domain/value_objects/customer_required_field.dart';
import '../../domain/value_objects/customer_status.dart';
import '../../domain/value_objects/customer_type.dart';
import 'customer_form_event.dart';
import 'customer_form_state.dart';

@injectable
final class CustomerFormBloc
    extends Bloc<CustomerFormEvent, CustomerFormState> {
  CustomerFormBloc({
    required this.getConfig,
    required this.getDraft,
    required this.saveDraft,
    required this.clearDraft,
    required this.createCustomer,
    required this.updateCustomer,
    required this.listOrganizationUsers,
    required this.analyticsService,
  }) : super(const CustomerFormState()) {
    on<CustomerFormStarted>(_onStarted, transformer: restartable());
    on<CustomerFormTypeChanged>(_onTypeChanged, transformer: sequential());
    on<CustomerFormDocumentChanged>(
      _onDocumentChanged,
      transformer: sequential(),
    );
    on<CustomerFormLegalNameChanged>(
      (event, emit) => _changeText(
        emit,
        errorField: 'legalName',
        legalName: event.legalName,
      ),
      transformer: sequential(),
    );
    on<CustomerFormTradeNameChanged>(
      (event, emit) => _changeText(
        emit,
        errorField: 'tradeName',
        tradeName: event.tradeName,
      ),
      transformer: sequential(),
    );
    on<CustomerFormFullNameChanged>(
      (event, emit) =>
          _changeText(emit, errorField: 'fullName', fullName: event.fullName),
      transformer: sequential(),
    );
    on<CustomerFormStateRegistrationChanged>(
      (event, emit) => _changeText(
        emit,
        errorField: 'stateRegistration',
        stateRegistration: event.stateRegistration,
      ),
      transformer: sequential(),
    );
    on<CustomerFormPrimaryEmailChanged>(
      _onPrimaryEmailChanged,
      transformer: sequential(),
    );
    on<CustomerFormPrimaryPhoneChanged>(
      (event, emit) => _changeText(
        emit,
        errorField: 'primaryPhone',
        primaryPhone: event.primaryPhone,
      ),
      transformer: sequential(),
    );
    on<CustomerFormClassificationChanged>(
      (event, emit) => _changeText(
        emit,
        errorField: 'classification',
        classification: event.classification,
      ),
      transformer: sequential(),
    );
    on<CustomerFormPotentialChanged>(
      (event, emit) => _changeText(
        emit,
        errorField: 'potential',
        potential: event.potential,
      ),
      transformer: sequential(),
    );
    on<CustomerFormResponsibleSellerSelected>(
      _onResponsibleSellerSelected,
      transformer: sequential(),
    );
    on<CustomerFormAddressAdded>(_onAddressAdded, transformer: sequential());
    on<CustomerFormAddressUpdated>(
      _onAddressUpdated,
      transformer: sequential(),
    );
    on<CustomerFormAddressRemoved>(
      _onAddressRemoved,
      transformer: sequential(),
    );
    on<CustomerFormPrimaryAddressSelected>(
      _onPrimaryAddressSelected,
      transformer: sequential(),
    );
    on<CustomerFormContactAdded>(_onContactAdded, transformer: sequential());
    on<CustomerFormContactUpdated>(
      _onContactUpdated,
      transformer: sequential(),
    );
    on<CustomerFormContactRemoved>(
      _onContactRemoved,
      transformer: sequential(),
    );
    on<CustomerFormPrimaryContactSelected>(
      _onPrimaryContactSelected,
      transformer: sequential(),
    );
    on<CustomerFormDraftSaved>(_onDraftSaved, transformer: droppable());
    on<CustomerFormSubmitted>(_onSubmitted, transformer: droppable());
  }

  final GetCustomerFormConfigUseCase getConfig;
  final GetCustomerFormDraftUseCase getDraft;
  final SaveCustomerFormDraftUseCase saveDraft;
  final ClearCustomerFormDraftUseCase clearDraft;
  final CreateCustomerUseCase createCustomer;
  final UpdateCustomerUseCase updateCustomer;
  final ListOrganizationUsersUseCase listOrganizationUsers;
  final AnalyticsService analyticsService;
  final Uuid _uuid = const Uuid();

  Future<void> _onStarted(
    CustomerFormStarted event,
    Emitter<CustomerFormState> emit,
  ) async {
    emit(
      const CustomerFormState().copyWith(
        loadStatus: CustomerFormLoadStatus.loading,
        organizationId: event.organizationId,
        companyId: event.companyId,
        userId: event.userId,
        initialCustomer: event.initialCustomer,
        canChooseResponsibleSeller: event.canChooseResponsibleSeller,
      ),
    );

    final configResult = await getConfig(event.organizationId);
    if (emit.isDone) return;
    final CustomerFormConfig config;
    switch (configResult) {
      case AppSuccess<CustomerFormConfig>(value: final loadedConfig):
        config = loadedConfig;
      case AppFailure<CustomerFormConfig>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: CustomerFormLoadStatus.failure,
            failure: failure,
          ),
        );
        return;
    }

    var responsibleSellers = const <OrganizationUser>[];
    if (event.canChooseResponsibleSeller) {
      final usersResult = await listOrganizationUsers(event.organizationId);
      if (emit.isDone) return;
      responsibleSellers = usersResult.fold(
        onSuccess: _filterResponsibleSellers,
        onFailure: (_) => const <OrganizationUser>[],
      );
    }

    final initial = event.initialCustomer;
    if (initial != null) {
      emit(
        state.copyWith(
          loadStatus: CustomerFormLoadStatus.ready,
          config: config,
          responsibleSellers: responsibleSellers,
          type: initial.type,
          document: initial.document.formatted,
          legalName: initial.legalName ?? '',
          tradeName: initial.tradeName ?? '',
          fullName: initial.fullName ?? '',
          stateRegistration: initial.stateRegistration ?? '',
          primaryEmail: initial.primaryEmail ?? '',
          primaryPhone: initial.primaryPhone ?? '',
          classification: initial.classification ?? '',
          potential: initial.potential ?? '',
          responsibleSellerId: initial.responsibleSellerId,
          addresses: normalizeCustomerAddresses(initial.addresses),
          contacts: normalizeCustomerContacts(initial.contacts),
          clearFieldErrors: true,
          clearFailure: true,
        ),
      );
      return;
    }

    final draftResult = await getDraft(
      organizationId: event.organizationId,
      userId: event.userId,
    );
    if (emit.isDone) return;
    final draft = draftResult.fold(
      onSuccess: (value) => value?.companyId == event.companyId ? value : null,
      onFailure: (_) => null,
    );

    emit(
      state.copyWith(
        loadStatus: CustomerFormLoadStatus.ready,
        config: config,
        responsibleSellers: responsibleSellers,
        type: draft?.type,
        document: draft?.document,
        legalName: draft?.legalName ?? '',
        tradeName: draft?.tradeName ?? '',
        fullName: draft?.fullName ?? '',
        stateRegistration: draft?.stateRegistration ?? '',
        primaryEmail: draft?.primaryEmail ?? '',
        primaryPhone: draft?.primaryPhone ?? '',
        classification: draft?.classification ?? '',
        potential: draft?.potential ?? '',
        responsibleSellerId: draft?.responsibleSellerId,
        addresses: normalizeCustomerAddresses(
          draft?.addresses ?? const <CustomerAddress>[],
        ),
        contacts: normalizeCustomerContacts(
          draft?.contacts ?? const <CustomerContact>[],
        ),
        hasRestoredDraft: draft != null,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );
  }

  void _onTypeChanged(
    CustomerFormTypeChanged event,
    Emitter<CustomerFormState> emit,
  ) {
    final fieldErrors = Map<String, String>.of(state.fieldErrors);
    _setOrRemove(
      fieldErrors,
      'document',
      _documentError(state.document, event.type, allowEmpty: true),
    );
    fieldErrors
      ..remove('legalName')
      ..remove('fullName');
    emit(
      state.copyWith(
        type: event.type,
        submissionStatus: CustomerFormSubmissionStatus.idle,
        draftStatus: CustomerFormDraftStatus.idle,
        fieldErrors: fieldErrors,
        clearFailure: true,
        clearSavedCustomer: true,
      ),
    );
  }

  void _onDocumentChanged(
    CustomerFormDocumentChanged event,
    Emitter<CustomerFormState> emit,
  ) {
    final fieldErrors = Map<String, String>.of(state.fieldErrors);
    _setOrRemove(
      fieldErrors,
      'document',
      _documentError(event.document, state.type, allowEmpty: true),
    );
    emit(
      state.copyWith(
        document: event.document,
        submissionStatus: CustomerFormSubmissionStatus.idle,
        draftStatus: CustomerFormDraftStatus.idle,
        fieldErrors: fieldErrors,
        clearFailure: true,
        clearSavedCustomer: true,
      ),
    );
  }

  void _onPrimaryEmailChanged(
    CustomerFormPrimaryEmailChanged event,
    Emitter<CustomerFormState> emit,
  ) {
    final fieldErrors = Map<String, String>.of(state.fieldErrors);
    _setOrRemove(
      fieldErrors,
      'primaryEmail',
      _emailError(event.primaryEmail, allowEmpty: true),
    );
    emit(
      state.copyWith(
        primaryEmail: event.primaryEmail,
        submissionStatus: CustomerFormSubmissionStatus.idle,
        draftStatus: CustomerFormDraftStatus.idle,
        fieldErrors: fieldErrors,
        clearFailure: true,
        clearSavedCustomer: true,
      ),
    );
  }

  void _onResponsibleSellerSelected(
    CustomerFormResponsibleSellerSelected event,
    Emitter<CustomerFormState> emit,
  ) {
    final fieldErrors = Map<String, String>.of(state.fieldErrors)
      ..remove('responsibleSellerId');
    emit(
      state.copyWith(
        responsibleSellerId: event.responsibleSellerId,
        clearResponsibleSellerId: event.responsibleSellerId == null,
        submissionStatus: CustomerFormSubmissionStatus.idle,
        draftStatus: CustomerFormDraftStatus.idle,
        fieldErrors: fieldErrors,
        clearFailure: true,
        clearSavedCustomer: true,
      ),
    );
  }

  void _onAddressAdded(
    CustomerFormAddressAdded event,
    Emitter<CustomerFormState> emit,
  ) {
    try {
      final address = buildCustomerAddress(
        id: _uuid.v4(),
        type: event.type,
        street: event.street,
        number: event.number,
        complement: event.complement,
        district: event.district,
        city: _cityFromLocalZip(event.zipCode, event.city),
        state: _stateFromLocalZip(event.zipCode, event.state),
        zipCode: event.zipCode,
        country: event.country,
        isPrimary: event.isPrimary || state.addresses.isEmpty,
      );
      final next = normalizeCustomerAddresses(<CustomerAddress>[
        if (address.isPrimary)
          for (final existing in state.addresses)
            existing.copyWith(isPrimary: false)
        else
          ...state.addresses,
        address,
      ]);
      emit(
        state.copyWith(
          addresses: next,
          submissionStatus: CustomerFormSubmissionStatus.idle,
          draftStatus: CustomerFormDraftStatus.idle,
          fieldErrors: _withoutPrefixedErrors('address.'),
          clearFailure: true,
          clearSavedCustomer: true,
        ),
      );
    } on ValidationException catch (exception) {
      emit(
        state.copyWith(
          submissionStatus: CustomerFormSubmissionStatus.failure,
          fieldErrors: _withAddressErrors(exception),
          clearFailure: true,
        ),
      );
    }
  }

  void _onAddressUpdated(
    CustomerFormAddressUpdated event,
    Emitter<CustomerFormState> emit,
  ) {
    try {
      final updated = buildCustomerAddress(
        id: event.addressId,
        type: event.type,
        street: event.street,
        number: event.number,
        complement: event.complement,
        district: event.district,
        city: _cityFromLocalZip(event.zipCode, event.city),
        state: _stateFromLocalZip(event.zipCode, event.state),
        zipCode: event.zipCode,
        country: event.country,
        isPrimary: event.isPrimary,
      );
      final index = state.addresses.indexWhere(
        (address) => address.id == event.addressId,
      );
      if (index == -1) {
        emit(
          state.copyWith(
            submissionStatus: CustomerFormSubmissionStatus.failure,
            fieldErrors: <String, String>{
              ..._withoutPrefixedErrors('address.'),
              'address.id': 'Endereço não encontrado.',
            },
            clearFailure: true,
          ),
        );
        return;
      }
      final next = <CustomerAddress>[
        for (
          var itemIndex = 0;
          itemIndex < state.addresses.length;
          itemIndex += 1
        )
          itemIndex == index ? updated : state.addresses[itemIndex],
      ];
      emit(
        state.copyWith(
          addresses: normalizeCustomerAddresses(next),
          submissionStatus: CustomerFormSubmissionStatus.idle,
          draftStatus: CustomerFormDraftStatus.idle,
          fieldErrors: _withoutPrefixedErrors('address.'),
          clearFailure: true,
          clearSavedCustomer: true,
        ),
      );
    } on ValidationException catch (exception) {
      emit(
        state.copyWith(
          submissionStatus: CustomerFormSubmissionStatus.failure,
          fieldErrors: _withAddressErrors(exception),
          clearFailure: true,
        ),
      );
    }
  }

  void _onAddressRemoved(
    CustomerFormAddressRemoved event,
    Emitter<CustomerFormState> emit,
  ) {
    final next = state.addresses
        .where((address) => address.id != event.addressId)
        .toList(growable: false);
    if (next.length == state.addresses.length) return;
    emit(
      state.copyWith(
        addresses: normalizeCustomerAddresses(next),
        submissionStatus: CustomerFormSubmissionStatus.idle,
        draftStatus: CustomerFormDraftStatus.idle,
        fieldErrors: _withoutPrefixedErrors('address.'),
        clearFailure: true,
        clearSavedCustomer: true,
      ),
    );
  }

  void _onPrimaryAddressSelected(
    CustomerFormPrimaryAddressSelected event,
    Emitter<CustomerFormState> emit,
  ) {
    if (!state.addresses.any((address) => address.id == event.addressId)) {
      return;
    }
    emit(
      state.copyWith(
        addresses: <CustomerAddress>[
          for (final address in state.addresses)
            address.copyWith(isPrimary: address.id == event.addressId),
        ],
        submissionStatus: CustomerFormSubmissionStatus.idle,
        draftStatus: CustomerFormDraftStatus.idle,
        fieldErrors: _withoutPrefixedErrors('address.'),
        clearFailure: true,
        clearSavedCustomer: true,
      ),
    );
  }

  void _onContactAdded(
    CustomerFormContactAdded event,
    Emitter<CustomerFormState> emit,
  ) {
    try {
      final contact = buildCustomerContact(
        id: _uuid.v4(),
        type: event.type,
        name: event.name,
        role: event.role,
        phone: event.phone,
        email: event.email,
        isPrimary: event.isPrimary || state.contacts.isEmpty,
      );
      final next = normalizeCustomerContacts(<CustomerContact>[
        if (contact.isPrimary)
          for (final existing in state.contacts)
            existing.copyWith(isPrimary: false)
        else
          ...state.contacts,
        contact,
      ]);
      _emitContacts(
        emit,
        next,
        fieldErrors: _withoutPrefixedErrors('contact.'),
      );
    } on ValidationException catch (exception) {
      emit(
        state.copyWith(
          submissionStatus: CustomerFormSubmissionStatus.failure,
          fieldErrors: _withContactErrors(exception),
          clearFailure: true,
        ),
      );
    }
  }

  void _onContactUpdated(
    CustomerFormContactUpdated event,
    Emitter<CustomerFormState> emit,
  ) {
    try {
      final updated = buildCustomerContact(
        id: event.contactId,
        type: event.type,
        name: event.name,
        role: event.role,
        phone: event.phone,
        email: event.email,
        isPrimary: event.isPrimary,
      );
      final index = state.contacts.indexWhere(
        (contact) => contact.id == event.contactId,
      );
      if (index == -1) {
        emit(
          state.copyWith(
            submissionStatus: CustomerFormSubmissionStatus.failure,
            fieldErrors: <String, String>{
              ..._withoutPrefixedErrors('contact.'),
              'contact.id': 'Contato não encontrado.',
            },
            clearFailure: true,
          ),
        );
        return;
      }
      final next = <CustomerContact>[
        for (
          var itemIndex = 0;
          itemIndex < state.contacts.length;
          itemIndex += 1
        )
          itemIndex == index ? updated : state.contacts[itemIndex],
      ];
      _emitContacts(
        emit,
        normalizeCustomerContacts(next),
        fieldErrors: _withoutPrefixedErrors('contact.'),
      );
    } on ValidationException catch (exception) {
      emit(
        state.copyWith(
          submissionStatus: CustomerFormSubmissionStatus.failure,
          fieldErrors: _withContactErrors(exception),
          clearFailure: true,
        ),
      );
    }
  }

  void _onContactRemoved(
    CustomerFormContactRemoved event,
    Emitter<CustomerFormState> emit,
  ) {
    final next = state.contacts
        .where((contact) => contact.id != event.contactId)
        .toList(growable: false);
    if (next.length == state.contacts.length) return;
    _emitContacts(
      emit,
      normalizeCustomerContacts(next),
      fieldErrors: _withoutPrefixedErrors('contact.'),
    );
  }

  void _onPrimaryContactSelected(
    CustomerFormPrimaryContactSelected event,
    Emitter<CustomerFormState> emit,
  ) {
    if (!state.contacts.any((contact) => contact.id == event.contactId)) {
      return;
    }
    _emitContacts(emit, <CustomerContact>[
      for (final contact in state.contacts)
        contact.copyWith(isPrimary: contact.id == event.contactId),
    ], fieldErrors: _withoutPrefixedErrors('contact.'));
  }

  void _changeText(
    Emitter<CustomerFormState> emit, {
    required String errorField,
    String? legalName,
    String? tradeName,
    String? fullName,
    String? stateRegistration,
    String? primaryPhone,
    String? classification,
    String? potential,
  }) {
    final fieldErrors = Map<String, String>.of(state.fieldErrors)
      ..remove(errorField);
    emit(
      state.copyWith(
        legalName: legalName,
        tradeName: tradeName,
        fullName: fullName,
        stateRegistration: stateRegistration,
        primaryPhone: primaryPhone,
        classification: classification,
        potential: potential,
        submissionStatus: CustomerFormSubmissionStatus.idle,
        draftStatus: CustomerFormDraftStatus.idle,
        fieldErrors: fieldErrors,
        clearFailure: true,
        clearSavedCustomer: true,
      ),
    );
  }

  Future<void> _onDraftSaved(
    CustomerFormDraftSaved event,
    Emitter<CustomerFormState> emit,
  ) async {
    if (state.isSubmitting || state.isDraftSaving) return;
    emit(
      state.copyWith(
        draftStatus: CustomerFormDraftStatus.saving,
        clearFailure: true,
      ),
    );

    final result = await saveDraft(_draftFromState());
    if (emit.isDone) return;
    result.fold(
      onSuccess: (_) => emit(
        state.copyWith(
          draftStatus: CustomerFormDraftStatus.saved,
          clearFailure: true,
        ),
      ),
      onFailure: (failure) => emit(
        state.copyWith(
          draftStatus: CustomerFormDraftStatus.failure,
          failure: failure,
        ),
      ),
    );
  }

  Future<void> _onSubmitted(
    CustomerFormSubmitted event,
    Emitter<CustomerFormState> emit,
  ) async {
    if (state.isSubmitting) return;

    final fieldErrors = _validate(state);
    if (fieldErrors.isNotEmpty) {
      emit(
        state.copyWith(
          submissionStatus: CustomerFormSubmissionStatus.failure,
          fieldErrors: fieldErrors,
          clearFailure: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        submissionStatus: CustomerFormSubmissionStatus.submitting,
        clearFieldErrors: true,
        clearFailure: true,
        clearSavedCustomer: true,
      ),
    );

    final result = state.isEditing
        ? await updateCustomer(
            organizationId: state.organizationId,
            id: state.initialCustomer!.id,
            type: state.type,
            document: state.document,
            legalName: state.legalName,
            tradeName: state.tradeName,
            fullName: state.fullName,
            stateRegistration: state.stateRegistration,
            primaryEmail: _primaryEmailForSubmit(),
            primaryPhone: _primaryPhoneForSubmit(),
            status: state.initialCustomer!.status,
            classification: state.classification,
            potential: state.potential,
            segment: state.initialCustomer!.segment,
            originChannel: state.initialCustomer!.originChannel,
            responsibleSellerId: _responsibleSellerForSubmit(),
            addresses: state.addresses,
            contacts: state.contacts,
            tags: state.initialCustomer!.tags,
            customFields: state.initialCustomer!.customFields,
            updatedBy: state.userId,
          )
        : await createCustomer(
            id: _uuid.v4(),
            organizationId: state.organizationId,
            companyId: state.companyId,
            type: state.type,
            document: state.document,
            legalName: state.legalName,
            tradeName: state.tradeName,
            fullName: state.fullName,
            stateRegistration: state.stateRegistration,
            primaryEmail: _primaryEmailForSubmit(),
            primaryPhone: _primaryPhoneForSubmit(),
            status: CustomerStatus.prospect,
            classification: state.classification,
            potential: state.potential,
            responsibleSellerId: _responsibleSellerForSubmit(),
            addresses: state.addresses,
            contacts: state.contacts,
            createdBy: state.userId,
          );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<Customer>(value: final customer):
        await clearDraft(
          organizationId: state.organizationId,
          userId: state.userId,
        );
        await analyticsService.logEvent(
          AnalyticsEvents.customerCreated,
          parameters: <String, Object?>{
            'organization_id': state.organizationId,
            'customer_id': customer.id,
            'customer_type': customer.type.name,
            'sync_status': customer.syncStatus.name,
          },
        );
        if (emit.isDone) return;
        emit(
          state.copyWith(
            submissionStatus: CustomerFormSubmissionStatus.success,
            draftStatus: CustomerFormDraftStatus.idle,
            savedCustomer: customer,
            hasRestoredDraft: false,
            clearFailure: true,
          ),
        );
      case AppFailure<Customer>(failure: final failure):
        emit(
          state.copyWith(
            submissionStatus: CustomerFormSubmissionStatus.failure,
            failure: failure,
            fieldErrors: _fieldErrorsFromFailure(failure),
          ),
        );
    }
  }

  CustomerFormDraft _draftFromState() {
    return CustomerFormDraft(
      organizationId: state.organizationId,
      companyId: state.companyId,
      userId: state.userId,
      type: state.type,
      document: state.document,
      legalName: _blankToNull(state.legalName),
      tradeName: _blankToNull(state.tradeName),
      fullName: _blankToNull(state.fullName),
      stateRegistration: _blankToNull(state.stateRegistration),
      primaryEmail: _blankToNull(state.primaryEmail),
      primaryPhone: _blankToNull(state.primaryPhone),
      classification: _blankToNull(state.classification),
      potential: _blankToNull(state.potential),
      responsibleSellerId: _blankToNull(state.responsibleSellerId),
      addresses: state.addresses,
      contacts: state.contacts,
      savedAt: DateTime.now().toUtc(),
    );
  }

  Map<String, String> _validate(CustomerFormState form) {
    final errors = <String, String>{};
    final documentError = _documentError(
      form.document,
      form.type,
      allowEmpty: false,
    );
    if (documentError != null) errors['document'] = documentError;

    if (form.type == CustomerType.legalEntity &&
        form.legalName.trim().isEmpty) {
      errors['legalName'] = 'Informe a razão social.';
    }
    if (form.type == CustomerType.individual && form.fullName.trim().isEmpty) {
      errors['fullName'] = 'Informe o nome completo.';
    }

    final primaryContact = primaryCustomerContact(form.contacts);
    final resolvedPrimaryEmail = primaryContact?.email ?? form.primaryEmail;
    final resolvedPrimaryPhone = primaryContact?.phone ?? form.primaryPhone;
    final emailError = _emailError(resolvedPrimaryEmail, allowEmpty: true);
    if (emailError != null) errors['primaryEmail'] = emailError;

    if (form.isRequired(CustomerRequiredField.primaryEmail) &&
        resolvedPrimaryEmail.trim().isEmpty) {
      errors['primaryEmail'] = 'Informe o e-mail principal.';
    }
    if (form.isRequired(CustomerRequiredField.primaryPhone) &&
        resolvedPrimaryPhone.trim().isEmpty) {
      errors['primaryPhone'] = 'Informe o telefone principal.';
    }
    if (form.isRequired(CustomerRequiredField.classification) &&
        form.classification.trim().isEmpty) {
      errors['classification'] = 'Informe a classificação.';
    }
    if (form.isRequired(CustomerRequiredField.potential) &&
        form.potential.trim().isEmpty) {
      errors['potential'] = 'Informe o potencial.';
    }
    if (form.canChooseResponsibleSeller &&
        form.isRequired(CustomerRequiredField.responsibleSellerId) &&
        (form.responsibleSellerId == null ||
            form.responsibleSellerId!.trim().isEmpty)) {
      errors['responsibleSellerId'] = 'Selecione o vendedor responsável.';
    }

    return errors;
  }

  String? _documentError(
    String document,
    CustomerType type, {
    required bool allowEmpty,
  }) {
    final trimmed = document.trim();
    if (trimmed.isEmpty) {
      return allowEmpty
          ? null
          : switch (type) {
              CustomerType.legalEntity => 'Informe o CNPJ.',
              CustomerType.individual => 'Informe o CPF.',
            };
    }

    try {
      final parsed = CnpjCpf.parse(trimmed);
      return switch (type) {
        CustomerType.legalEntity when !parsed.isCnpj =>
          'Informe um CNPJ válido.',
        CustomerType.individual when !parsed.isCpf => 'Informe um CPF válido.',
        _ => null,
      };
    } on ValidationException {
      return switch (type) {
        CustomerType.legalEntity => 'Informe um CNPJ válido.',
        CustomerType.individual => 'Informe um CPF válido.',
      };
    }
  }

  String? _emailError(String email, {required bool allowEmpty}) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return allowEmpty ? null : 'Informe o e-mail.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)) {
      return 'Informe um e-mail válido.';
    }
    return null;
  }

  Map<String, String> _fieldErrorsFromFailure(Failure failure) {
    if (failure is ConflictFailure &&
        failure.code == 'customer_document_already_exists') {
      return const <String, String>{
        'document': 'Já existe um cliente com este documento.',
      };
    }
    if (failure is ValidationFailure) {
      return failure.fieldErrors.map(
        (field, _) => MapEntry(field, _fallbackFieldMessage(field)),
      );
    }
    return const <String, String>{};
  }

  String _fallbackFieldMessage(String field) {
    return switch (field) {
      'document' => 'Informe um documento válido.',
      'legalName' => 'Informe a razão social.',
      'fullName' => 'Informe o nome completo.',
      'stateRegistration' => 'Informe uma inscrição estadual válida.',
      _ => 'Revise este campo.',
    };
  }

  List<OrganizationUser> _filterResponsibleSellers(
    List<OrganizationUser> users,
  ) {
    final sellerRoles = <String>{
      SystemRoleName.salesManager.code,
      SystemRoleName.salesRep.code,
      SystemRoleName.salesAssistant.code,
    };
    return users
        .where(
          (user) =>
              user.status == MembershipStatus.active &&
              sellerRoles.contains(user.roleName),
        )
        .toList(growable: false);
  }

  void _emitContacts(
    Emitter<CustomerFormState> emit,
    List<CustomerContact> contacts, {
    required Map<String, String> fieldErrors,
  }) {
    final normalized = normalizeCustomerContacts(contacts);
    final primary = primaryCustomerContact(normalized);
    emit(
      state.copyWith(
        contacts: normalized,
        primaryEmail: primary?.email ?? '',
        primaryPhone: primary?.phone ?? '',
        submissionStatus: CustomerFormSubmissionStatus.idle,
        draftStatus: CustomerFormDraftStatus.idle,
        fieldErrors: fieldErrors,
        clearFailure: true,
        clearSavedCustomer: true,
      ),
    );
  }

  Map<String, String> _withoutPrefixedErrors(String prefix) {
    return Map<String, String>.fromEntries(
      state.fieldErrors.entries.where((entry) => !entry.key.startsWith(prefix)),
    );
  }

  Map<String, String> _withAddressErrors(ValidationException exception) {
    return <String, String>{
      ..._withoutPrefixedErrors('address.'),
      for (final field in exception.fieldErrors.keys)
        'address.$field': _addressFieldMessage(field),
    };
  }

  Map<String, String> _withContactErrors(ValidationException exception) {
    return <String, String>{
      ..._withoutPrefixedErrors('contact.'),
      for (final field in exception.fieldErrors.keys)
        'contact.$field': _contactFieldMessage(field),
    };
  }

  String _cityFromLocalZip(String zipCode, String city) {
    final trimmedCity = city.trim();
    if (trimmedCity.isNotEmpty) return city;
    final digits = zipCode.replaceAll(RegExp(r'\D'), '');
    for (final address in state.addresses) {
      if (address.zipCode.digits == digits) return address.city;
    }
    return city;
  }

  String _stateFromLocalZip(String zipCode, String stateCode) {
    final trimmedState = stateCode.trim();
    if (trimmedState.isNotEmpty) return stateCode;
    final digits = zipCode.replaceAll(RegExp(r'\D'), '');
    for (final address in state.addresses) {
      if (address.zipCode.digits == digits) return address.state;
    }
    return stateCode;
  }

  String _addressFieldMessage(String field) {
    return switch (field) {
      'street' => 'Informe o logradouro.',
      'city' => 'Informe a cidade.',
      'state' => 'Informe a UF.',
      'zipCode' => 'Informe um CEP válido.',
      'country' => 'Informe o país.',
      _ => 'Revise este campo.',
    };
  }

  String _contactFieldMessage(String field) {
    return switch (field) {
      'name' => 'Informe o nome do contato.',
      'phone' => 'Informe telefone ou e-mail.',
      'email' => 'Informe um e-mail válido ou telefone.',
      _ => 'Revise este campo.',
    };
  }

  String? _responsibleSellerForSubmit() {
    if (state.canChooseResponsibleSeller) {
      return _blankToNull(state.responsibleSellerId);
    }
    return _blankToNull(state.initialCustomer?.responsibleSellerId) ??
        _blankToNull(state.userId);
  }

  String? _primaryEmailForSubmit() {
    return _blankToNull(primaryCustomerContact(state.contacts)?.email) ??
        _blankToNull(state.primaryEmail);
  }

  String? _primaryPhoneForSubmit() {
    return _blankToNull(primaryCustomerContact(state.contacts)?.phone) ??
        _blankToNull(state.primaryPhone);
  }

  void _setOrRemove(Map<String, String> errors, String field, String? message) {
    if (message == null) {
      errors.remove(field);
    } else {
      errors[field] = message;
    }
  }

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
