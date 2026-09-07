import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/functions/functions.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/replenishment_decision_result.dart';
import '../../domain/entities/replenishment_suggestion_page.dart';
import '../../domain/repositories/replenishment_repository.dart';
import '../../domain/value_objects/replenishment_decision_action.dart';
import '../../domain/value_objects/replenishment_suggestion_status.dart';
import '../datasources/replenishment_suggestion_data_source.dart';
import '../mappers/replenishment_suggestion_mapper.dart';

/// Combines a read-only Firestore datasource ([listPageByOrganization],
/// already scoped/RBAC'd by `firestore.rules`) with the
/// `decideReplenishmentSuggestion` callable ([decide]) — the same "one
/// repository, two different transports" shape already used by
/// `StockAlertRepositoryImpl` (Firestore-only) plus
/// `CloudFunctionsCartShareRepository` (callable-only) combined, since this
/// feature genuinely needs both: reading suggestions is a plain scoped
/// query, but deciding one is a server-side authorized mutation that must
/// never be a direct Firestore write from the client
/// (`firestore.rules`: `replenishmentSuggestions` denies client `create`/
/// `update`/`delete` unconditionally).
@LazySingleton(as: ReplenishmentRepository)
final class ReplenishmentRepositoryImpl implements ReplenishmentRepository {
  const ReplenishmentRepositoryImpl({
    required this.dataSource,
    required this.mapper,
    required this.functions,
  });

  final ReplenishmentSuggestionDataSource dataSource;
  final ReplenishmentSuggestionMapper mapper;
  final CloudFunctionsService functions;

  @override
  Future<AppResult<ReplenishmentSuggestionPage>> listPageByOrganization({
    required String organizationId,
    int limit = 25,
    DateTime? before,
    ReplenishmentSuggestionStatus? status,
    String? warehouseId,
  }) async {
    try {
      final items = await dataSource.listPageByOrganization(
        organizationId: organizationId,
        limit: limit,
        before: before,
        status: status?.code,
        warehouseId: warehouseId,
      );
      final suggestions = items.map(mapper.toEntity).toList(growable: false);
      return AppSuccess<ReplenishmentSuggestionPage>(
        ReplenishmentSuggestionPage(
          suggestions: suggestions,
          hasMore: suggestions.length == limit,
          nextCursor: suggestions.length == limit && suggestions.isNotEmpty
              ? suggestions.last.generatedAt
              : null,
        ),
      );
    } on AppException catch (exception) {
      return AppFailure<ReplenishmentSuggestionPage>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<ReplenishmentSuggestionPage>(
        UnexpectedFailure(
          'Unexpected error listing replenishment suggestions.',
          code: 'replenishment_suggestion_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<ReplenishmentDecisionResult>> decide({
    required String organizationId,
    required String suggestionId,
    required ReplenishmentDecisionAction action,
    int? adjustedQuantity,
    String? note,
  }) async {
    try {
      final json = await functions.call<Map<String, dynamic>>(
        'decideReplenishmentSuggestion',
        requireAuth: true,
        data: <String, dynamic>{
          'organizationId': organizationId,
          'suggestionId': suggestionId,
          'action': action.code,
          if (adjustedQuantity != null) 'adjustedQuantity': adjustedQuantity,
          if (note != null) 'note': note,
        },
      );
      return AppSuccess<ReplenishmentDecisionResult>(
        ReplenishmentDecisionResult(
          suggestionId: json['suggestionId'] as String,
          status: parseReplenishmentSuggestionStatus(json['status'] as String),
          finalQuantity: json['finalQuantity'] as int?,
          draftOrderId: json['draftOrderId'] as String?,
        ),
      );
    } on AppException catch (exception) {
      return AppFailure<ReplenishmentDecisionResult>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<ReplenishmentDecisionResult>(
        UnexpectedFailure(
          'Unexpected error deciding the replenishment suggestion.',
          code: 'replenishment_suggestion_decision_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
