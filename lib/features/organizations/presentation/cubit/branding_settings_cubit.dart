import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/organization.dart';
import '../../domain/usecases/get_organization_use_case.dart';
import '../../domain/usecases/update_organization_settings_use_case.dart';
import 'branding_settings_state.dart';

/// Drives the catalog branding admin screen (TASK-179, EPIC-25). Reuses
/// `GetOrganizationUseCase`/`UpdateOrganizationSettingsUseCase` (no new
/// Organization write path, same precedent as `PositivacaoSettingsCubit`,
/// TASK-117): [submit] resends every existing `OrganizationSettings` field
/// alongside the edited branding ones, since
/// `FirestoreOrganizationDataSource.updateSettings` replaces the whole
/// `settings` map — never only the branding slice, or every other setting an
/// OWNER/ADMIN configured before would be silently reset to its default.
@injectable
final class BrandingSettingsCubit extends Cubit<BrandingSettingsState> {
  BrandingSettingsCubit(
    this._getOrganizationUseCase,
    this._updateOrganizationSettingsUseCase,
    this._analyticsService,
  ) : super(const BrandingSettingsState());

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
        loadStatus: BrandingSettingsLoadStatus.loading,
        organizationId: organizationId,
        updatedBy: updatedBy,
      ),
    );

    final result = await _getOrganizationUseCase(organizationId);
    switch (result) {
      case AppSuccess<Organization>(value: final organization):
        _organization = organization;
        final settings = organization.settings;
        final logoUrlInput = settings.brandingLogoUrl ?? '';
        final primaryColorHexInput = settings.brandingPrimaryColorHex ?? '';
        emit(
          state.copyWith(
            loadStatus: BrandingSettingsLoadStatus.ready,
            logoUrlInput: logoUrlInput,
            primaryColorHexInput: primaryColorHexInput,
            usesContrastFallback: _needsContrastFallback(primaryColorHexInput),
          ),
        );
      case AppFailure<Organization>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: BrandingSettingsLoadStatus.failure,
            failureMessage: failure.message,
          ),
        );
    }
  }

  void updateDraft({String? logoUrlInput, String? primaryColorHexInput}) {
    final resolvedPrimaryColorHexInput =
        primaryColorHexInput ?? state.primaryColorHexInput;
    emit(
      state.copyWith(
        saveStatus: BrandingSettingsSaveStatus.idle,
        logoUrlInput: logoUrlInput ?? state.logoUrlInput,
        primaryColorHexInput: resolvedPrimaryColorHexInput,
        usesContrastFallback: _needsContrastFallback(
          resolvedPrimaryColorHexInput,
        ),
        fieldErrors: const <String, String>{},
      ),
    );
  }

  Future<void> submit() async {
    final organization = _organization;
    if (organization == null) return;

    emit(
      state.copyWith(
        saveStatus: BrandingSettingsSaveStatus.submitting,
        fieldErrors: const <String, String>{},
        clearFailureMessage: true,
      ),
    );

    final trimmedLogoUrl = state.logoUrlInput.trim();
    final trimmedPrimaryColorHex = state.primaryColorHexInput.trim();
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
      positivacaoPeriodGranularity: settings.positivacaoPeriodGranularity,
      positivacaoEligibleOrderStatuses:
          settings.positivacaoEligibleOrderStatuses,
      positivacaoMinOrderValue: settings.positivacaoMinOrderValue,
      rankingVisibilityMode: settings.rankingVisibilityMode,
      brandingLogoUrl: trimmedLogoUrl.isEmpty ? null : trimmedLogoUrl,
      brandingPrimaryColorHex: trimmedPrimaryColorHex.isEmpty
          ? null
          : trimmedPrimaryColorHex,
    );

    switch (result) {
      case AppSuccess<Organization>(value: final updated):
        _organization = updated;
        emit(state.copyWith(saveStatus: BrandingSettingsSaveStatus.success));
        await _analyticsService.logEvent(
          AnalyticsEvents.catalogBrandingUpdated,
          parameters: <String, Object?>{'organization_id': updated.id},
        );
      case AppFailure<Organization>(failure: final failure):
        emit(
          state.copyWith(
            saveStatus: BrandingSettingsSaveStatus.failure,
            failureMessage: failure.message,
            fieldErrors: failure is ValidationFailure
                ? failure.fieldErrors
                : const <String, String>{},
          ),
        );
    }
  }

  /// Whether [primaryColorHexInput], trimmed, would need [AppBrandTheme]'s
  /// automatic contrast fallback. Checked against [AppColors.light] — the
  /// same base every customer-facing catalog surface this branding targets
  /// (`CatalogSharePublicPage`, TASK-081) renders with today — so the
  /// warning always matches what the live preview actually shows, instead
  /// of flagging a color that reads perfectly fine in the theme that
  /// matters simply because it would also need an adjustment in the other
  /// brightness.
  bool _needsContrastFallback(String primaryColorHexInput) {
    final trimmed = primaryColorHexInput.trim();
    if (trimmed.isEmpty) return false;
    return AppBrandTheme.needsContrastFallback(
      base: AppColors.light,
      primaryColorHex: trimmed,
    );
  }
}
