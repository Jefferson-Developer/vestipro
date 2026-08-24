import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../customers/customers.dart';
import '../entities/lead.dart';
import '../repositories/lead_repository.dart';
import '../value_objects/lead_status.dart';
import '../value_objects/lead_sync_status.dart';
import 'lead_use_case_helpers.dart';

/// Result of converting a qualified Lead into a Customer: both the updated
/// Lead (now `converted`, linked through [convertedCustomerId]) and the
/// Customer created from it (linked back through `Customer.sourceLeadId`).
typedef LeadToCustomerConversion = ({Lead lead, Customer customer});

/// Converts a qualified Lead into a Customer (TASK-048), preserving
/// traceability of the origin through `Customer.sourceLeadId`.
///
/// Reuses `CreateCustomerUseCase` instead of duplicating its validation
/// rules; this use case only adds the Lead-side qualification gate and the
/// resulting status transition.
final class ConvertLeadToCustomerUseCase {
  ConvertLeadToCustomerUseCase(this._leadRepository, this._createCustomer);

  final LeadRepository _leadRepository;
  final CreateCustomerUseCase _createCustomer;

  Future<AppResult<LeadToCustomerConversion>> call({
    required String organizationId,
    required String leadId,
    required String customerId,
    required String companyId,
    required CustomerType customerType,
    required String document,
    String? legalName,
    String? tradeName,
    String? fullName,
    String? stateRegistration,
    String? primaryEmail,
    String? primaryPhone,
    String? classification,
    String? potential,
    String? segment,
    String? originChannel,
    String? responsibleSellerId,
    List<String> tags = const <String>[],
    Map<String, Object?> customFields = const <String, Object?>{},
    required String convertedBy,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedLeadId = leadId.trim();
    final trimmedConvertedBy = convertedBy.trim();
    final fieldErrors = <String, String>{};

    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedLeadId.isEmpty) fieldErrors['leadId'] = 'LeadId is required.';
    if (trimmedConvertedBy.isEmpty) {
      fieldErrors['convertedBy'] = 'ConvertedBy is required.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<LeadToCustomerConversion>(
        ValidationFailure(
          'Invalid lead conversion payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_lead_convert_payload',
        ),
      );
    }

    final leadResult = await _leadRepository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedLeadId,
    );
    if (leadResult is AppFailure<Lead>) {
      return AppFailure<LeadToCustomerConversion>(leadResult.failure);
    }
    final lead = (leadResult as AppSuccess<Lead>).value;

    if (!lead.canTransitionTo(LeadStatus.converted)) {
      return AppFailure<LeadToCustomerConversion>(
        invalidLeadStatusTransitionFailure(
          from: lead.status,
          to: LeadStatus.converted,
        ),
      );
    }

    final customerResult = await _createCustomer.call(
      id: customerId,
      organizationId: trimmedOrganizationId,
      companyId: companyId,
      type: customerType,
      document: document,
      legalName: legalName,
      tradeName: tradeName,
      fullName: fullName,
      stateRegistration: stateRegistration,
      primaryEmail: primaryEmail,
      primaryPhone: primaryPhone,
      classification: classification,
      potential: potential,
      segment: segment,
      originChannel: originChannel,
      responsibleSellerId: responsibleSellerId,
      tags: tags,
      customFields: customFields,
      sourceLeadId: lead.id,
      createdBy: trimmedConvertedBy,
    );
    if (customerResult is AppFailure<Customer>) {
      return AppFailure<LeadToCustomerConversion>(customerResult.failure);
    }
    final customer = (customerResult as AppSuccess<Customer>).value;

    final now = DateTime.now().toUtc();
    final convertedLead = lead.copyWith(
      status: LeadStatus.converted,
      convertedAt: now,
      convertedCustomerId: customer.id,
      updatedAt: now,
      updatedBy: trimmedConvertedBy,
      version: lead.version + 1,
      syncStatus: LeadSyncStatus.pending,
    );

    final updateResult = await _leadRepository.update(lead: convertedLead);
    if (updateResult is AppFailure<Lead>) {
      return AppFailure<LeadToCustomerConversion>(updateResult.failure);
    }

    return AppSuccess<LeadToCustomerConversion>((
      lead: (updateResult as AppSuccess<Lead>).value,
      customer: customer,
    ));
  }
}
