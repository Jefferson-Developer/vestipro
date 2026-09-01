import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../organizations/organizations.dart';
import 'positivacao_settings_state.dart';

/// Drives the positivação settings admin screen (TASK-117, EPIC-15/
/// VESTI-087). Reuses `GetOrganizationUseCase`/`UpdateOrganizationSettingsUseCase`
/// (no new Organization write path): [submit] resends every existing
/// `OrganizationSettings` field alongside the edited positivação ones,
/// since `FirestoreOrganizationDataSource.updateSettings` replaces the whole
/// `settings` map (see that DTO's own docs) — never only the positivação
/// slice, or every other setting an OWNER/ADMIN configured before would be
/// silently reset to its default.
@injectable
final class PositivacaoSettingsCubit extends Cubit<PositivacaoSettingsState> {
  PositivacaoSettingsCubit(
    this._getOrganizationUseCase,
    this._updateOrganizationSettingsUseCase,
    this._analyticsService,
  ) : super(const PositivacaoSettingsState());

  final GetOrganizationUseCase _getOrganizationUseCase;
  final UpdateOrganizationSettingsUseCase _updateOrganizationSettingsUseCase;
  final AnalyticsService _analyticsService;

  Organization? _organization;

  Future<void> load({
    required String organizationId,
    required String updatedBy,
  }) async {
    emit(
      state.copyWith(
        loadStatus: PositivacaoSettingsLoadStatus.loading,
        organizationId: organizationId,
        updatedBy: updatedBy,
      ),
    );

    final result = await _getOrganizationUseCase(organizationId);
    switch (result) {
      case AppSuccess<Organization>(value: final organization):
        _organization = organization;
        final settings = organization.settings;
        emit(
          state.copyWith(
            loadStatus: PositivacaoSettingsLoadStatus.ready,
            periodGranularity: settings.positivacaoPeriodGranularity,
            eligibleOrderStatuses: settings.positivacaoEligibleOrderStatuses
                .toSet(),
            minOrderValueInput:
                settings.positivacaoMinOrderValue?.toString() ?? '',
          ),
        );
      case AppFailure<Organization>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: PositivacaoSettingsLoadStatus.failure,
            failureMessage: failure.message,
          ),
        );
    }
  }

  void updateDraft({
    String? periodGranularity,
    Set<String>? eligibleOrderStatuses,
    String? minOrderValueInput,
  }) {
    emit(
      state.copyWith(
        saveStatus: PositivacaoSettingsSaveStatus.idle,
        periodGranularity: periodGranularity ?? state.periodGranularity,
        eligibleOrderStatuses:
            eligibleOrderStatuses ?? state.eligibleOrderStatuses,
        minOrderValueInput: minOrderValueInput ?? state.minOrderValueInput,
      ),
    );
  }

  Future<void> submit() async {
    final organization = _organization;
    if (organization == null) return;

    final trimmedMinOrderValueInput = state.minOrderValueInput.trim();
    double? minOrderValue;
    if (trimmedMinOrderValueInput.isNotEmpty) {
      minOrderValue = double.tryParse(
        trimmedMinOrderValueInput.replaceAll(',', '.'),
      );
      if (minOrderValue == null) {
        emit(
          state.copyWith(
            saveStatus: PositivacaoSettingsSaveStatus.failure,
            fieldErrors: const <String, String>{
              'minOrderValue': 'Valor mínimo inválido.',
            },
          ),
        );
        return;
      }
    }

    emit(
      state.copyWith(
        saveStatus: PositivacaoSettingsSaveStatus.submitting,
        fieldErrors: const <String, String>{},
        clearFailureMessage: true,
      ),
    );

    final settings = organization.settings;
    final result = await _updateOrganizationSettingsUseCase(
      id: organization.id,
      currency: settings.currency,
      country: settings.country,
      defaultLanguage: settings.defaultLanguage,
      updatedBy: state.updatedBy,
      requiredCustomerFields: settings.requiredCustomerFields,
      customerAddressTypes: settings.customerAddressTypes,
      customerContactTypes: settings.customerContactTypes,
      allowMultipleCollectionsPerProduct:
          settings.allowMultipleCollectionsPerProduct,
      stockReservationExpiresInMinutes:
          settings.stockReservationExpiresInMinutes,
      positivacaoPeriodGranularity: state.periodGranularity,
      positivacaoEligibleOrderStatuses: state.eligibleOrderStatuses.toList(),
      positivacaoMinOrderValue: minOrderValue,
    );

    switch (result) {
      case AppSuccess<Organization>(value: final updated):
        _organization = updated;
        emit(state.copyWith(saveStatus: PositivacaoSettingsSaveStatus.success));
        await _analyticsService.logEvent(
          AnalyticsEvents.positivacaoSettingsUpdated,
          parameters: <String, Object?>{'organization_id': updated.id},
        );
      case AppFailure<Organization>(failure: final failure):
        emit(
          state.copyWith(
            saveStatus: PositivacaoSettingsSaveStatus.failure,
            failureMessage: failure.message,
            fieldErrors: failure is ValidationFailure
                ? failure.fieldErrors
                : const <String, String>{},
          ),
        );
    }
  }
}
