import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../organizations/organizations.dart';
import '../../../users/users.dart';
import '../../domain/entities/customer.dart';
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
            primaryEmail: state.primaryEmail,
            primaryPhone: state.primaryPhone,
            status: state.initialCustomer!.status,
            classification: state.classification,
            potential: state.potential,
            segment: state.initialCustomer!.segment,
            originChannel: state.initialCustomer!.originChannel,
            responsibleSellerId: _responsibleSellerForSubmit(),
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
            primaryEmail: state.primaryEmail,
            primaryPhone: state.primaryPhone,
            status: CustomerStatus.prospect,
            classification: state.classification,
            potential: state.potential,
            responsibleSellerId: _responsibleSellerForSubmit(),
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

    final emailError = _emailError(form.primaryEmail, allowEmpty: true);
    if (emailError != null) errors['primaryEmail'] = emailError;

    if (form.isRequired(CustomerRequiredField.primaryEmail) &&
        form.primaryEmail.trim().isEmpty) {
      errors['primaryEmail'] = 'Informe o e-mail principal.';
    }
    if (form.isRequired(CustomerRequiredField.primaryPhone) &&
        form.primaryPhone.trim().isEmpty) {
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

  String? _responsibleSellerForSubmit() {
    if (state.canChooseResponsibleSeller) {
      return _blankToNull(state.responsibleSellerId);
    }
    return _blankToNull(state.initialCustomer?.responsibleSellerId) ??
        _blankToNull(state.userId);
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
