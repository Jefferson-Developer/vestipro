import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../organizations/organizations.dart';
import '../../../users/users.dart';
import '../../domain/entities/lead.dart';
import '../../domain/usecases/create_lead_use_case.dart';
import '../../domain/value_objects/lead_source.dart';
import 'lead_form_event.dart';
import 'lead_form_state.dart';

/// Drives `LeadFormPage` (TASK-056): the cadastro form on top of the Lead
/// entity/`CreateLeadUseCase` modeled by TASK-055.
///
/// Mirrors `CustomerFormBloc`'s responsible-seller pattern: only a caller
/// granted [Capability.teamManage] gets to reassign the lead to a different
/// rep; everyone else always creates the lead assigned to themselves
/// (`state.userId`), matching the "reatribuir o responsavel" RBAC rule in
/// TASK-056.
@injectable
final class LeadFormBloc extends Bloc<LeadFormEvent, LeadFormState> {
  LeadFormBloc({
    required this.createLead,
    required this.listOrganizationUsers,
    required this.analyticsService,
  }) : super(const LeadFormState()) {
    on<LeadFormStarted>(_onStarted, transformer: restartable());
    on<LeadFormNameChanged>(_onNameChanged, transformer: sequential());
    on<LeadFormDocumentChanged>(_onDocumentChanged, transformer: sequential());
    on<LeadFormSourceSelected>(_onSourceSelected, transformer: sequential());
    on<LeadFormCustomSourceLabelChanged>(
      _onCustomSourceLabelChanged,
      transformer: sequential(),
    );
    on<LeadFormResponsibleSelected>(
      _onResponsibleSelected,
      transformer: sequential(),
    );
    on<LeadFormSubmitted>(_onSubmitted, transformer: droppable());
  }

  final CreateLeadUseCase createLead;
  final ListOrganizationUsersUseCase listOrganizationUsers;
  final AnalyticsService analyticsService;
  final Uuid _uuid = const Uuid();

  Future<void> _onStarted(
    LeadFormStarted event,
    Emitter<LeadFormState> emit,
  ) async {
    emit(
      const LeadFormState().copyWith(
        loadStatus: LeadFormLoadStatus.loading,
        organizationId: event.organizationId,
        companyId: event.companyId,
        userId: event.userId,
        canChooseResponsible: event.canChooseResponsible,
      ),
    );

    var responsibleUsers = const <OrganizationUser>[];
    if (event.canChooseResponsible) {
      final usersResult = await listOrganizationUsers(event.organizationId);
      if (emit.isDone) return;
      responsibleUsers = usersResult.fold(
        onSuccess: _filterResponsibleUsers,
        onFailure: (_) => const <OrganizationUser>[],
      );
    }

    emit(
      state.copyWith(
        loadStatus: LeadFormLoadStatus.ready,
        responsibleUsers: responsibleUsers,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );
  }

  void _onNameChanged(LeadFormNameChanged event, Emitter<LeadFormState> emit) {
    final fieldErrors = Map<String, String>.of(state.fieldErrors)
      ..remove('name');
    emit(
      state.copyWith(
        name: event.name,
        submissionStatus: LeadFormSubmissionStatus.idle,
        fieldErrors: fieldErrors,
        clearFailure: true,
        clearSavedLead: true,
      ),
    );
  }

  void _onDocumentChanged(
    LeadFormDocumentChanged event,
    Emitter<LeadFormState> emit,
  ) {
    emit(
      state.copyWith(
        document: event.document,
        submissionStatus: LeadFormSubmissionStatus.idle,
        clearFailure: true,
        clearSavedLead: true,
      ),
    );
  }

  void _onSourceSelected(
    LeadFormSourceSelected event,
    Emitter<LeadFormState> emit,
  ) {
    final fieldErrors = Map<String, String>.of(state.fieldErrors)
      ..remove('source');
    emit(
      state.copyWith(
        source: event.source,
        customSourceLabel: event.source == LeadSource.other
            ? state.customSourceLabel
            : '',
        submissionStatus: LeadFormSubmissionStatus.idle,
        fieldErrors: fieldErrors,
        clearFailure: true,
        clearSavedLead: true,
      ),
    );
  }

  void _onCustomSourceLabelChanged(
    LeadFormCustomSourceLabelChanged event,
    Emitter<LeadFormState> emit,
  ) {
    final fieldErrors = Map<String, String>.of(state.fieldErrors)
      ..remove('customSourceLabel');
    emit(
      state.copyWith(
        customSourceLabel: event.customSourceLabel,
        submissionStatus: LeadFormSubmissionStatus.idle,
        fieldErrors: fieldErrors,
        clearFailure: true,
        clearSavedLead: true,
      ),
    );
  }

  void _onResponsibleSelected(
    LeadFormResponsibleSelected event,
    Emitter<LeadFormState> emit,
  ) {
    final fieldErrors = Map<String, String>.of(state.fieldErrors)
      ..remove('responsibleUserId');
    emit(
      state.copyWith(
        responsibleUserId: event.responsibleUserId,
        clearResponsibleUserId: event.responsibleUserId == null,
        submissionStatus: LeadFormSubmissionStatus.idle,
        fieldErrors: fieldErrors,
        clearFailure: true,
        clearSavedLead: true,
      ),
    );
  }

  Future<void> _onSubmitted(
    LeadFormSubmitted event,
    Emitter<LeadFormState> emit,
  ) async {
    if (state.isSubmitting) return;

    final fieldErrors = _validate(state);
    if (fieldErrors.isNotEmpty) {
      emit(
        state.copyWith(
          submissionStatus: LeadFormSubmissionStatus.failure,
          fieldErrors: fieldErrors,
          clearFailure: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        submissionStatus: LeadFormSubmissionStatus.submitting,
        clearFieldErrors: true,
        clearFailure: true,
        clearSavedLead: true,
      ),
    );

    final result = await createLead(
      id: _uuid.v4(),
      organizationId: state.organizationId,
      companyId: state.companyId,
      name: state.name,
      document: state.document,
      source: _sourceForSubmit(),
      responsibleUserId: _responsibleUserIdForSubmit(),
      createdBy: state.userId,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<Lead>(value: final lead):
        await analyticsService.logEvent(
          AnalyticsEvents.leadCreated,
          parameters: <String, Object?>{
            'organization_id': state.organizationId,
            'lead_id': lead.id,
            'lead_source': lead.source.code,
            'sync_status': lead.syncStatus.name,
          },
        );
        if (emit.isDone) return;
        emit(
          state.copyWith(
            submissionStatus: LeadFormSubmissionStatus.success,
            savedLead: lead,
            clearFailure: true,
          ),
        );
      case AppFailure<Lead>(failure: final failure):
        emit(
          state.copyWith(
            submissionStatus: LeadFormSubmissionStatus.failure,
            failure: failure,
            fieldErrors: _fieldErrorsFromFailure(failure),
          ),
        );
    }
  }

  Map<String, String> _validate(LeadFormState form) {
    final errors = <String, String>{};
    if (form.name.trim().isEmpty) {
      errors['name'] = 'Informe o nome ou empresa do lead.';
    }
    // A blank custom source label when `source == LeadSource.other` is not
    // an error: it simply keeps the standard "Outro" source (see
    // `_sourceForSubmit`), so no field error is raised for it here.
    if (form.canChooseResponsible &&
        (form.responsibleUserId == null ||
            form.responsibleUserId!.trim().isEmpty)) {
      errors['responsibleUserId'] = 'Selecione o responsavel pelo lead.';
    }
    return errors;
  }

  LeadSource _sourceForSubmit() {
    final customLabel = state.customSourceLabel.trim();
    if (state.source == LeadSource.other && customLabel.isNotEmpty) {
      return LeadSource.custom(customLabel, label: customLabel);
    }
    return state.source;
  }

  String _responsibleUserIdForSubmit() {
    if (state.canChooseResponsible) {
      final selected = state.responsibleUserId?.trim();
      return (selected == null || selected.isEmpty) ? state.userId : selected;
    }
    return state.userId;
  }

  Map<String, String> _fieldErrorsFromFailure(Failure failure) {
    if (failure is ValidationFailure) {
      return failure.fieldErrors.map(
        (field, _) => MapEntry(field, _fallbackFieldMessage(field)),
      );
    }
    return const <String, String>{};
  }

  String _fallbackFieldMessage(String field) {
    return switch (field) {
      'name' => 'Informe o nome ou empresa do lead.',
      'responsibleUserId' => 'Selecione o responsavel pelo lead.',
      _ => 'Revise este campo.',
    };
  }

  List<OrganizationUser> _filterResponsibleUsers(List<OrganizationUser> users) {
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
}
