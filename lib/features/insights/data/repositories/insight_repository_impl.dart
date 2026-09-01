import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/insight.dart';
import '../../domain/entities/insight_page.dart';
import '../../domain/repositories/insight_repository.dart';
import '../../domain/services/insight_structural_validator.dart';
import '../../domain/value_objects/insight_status.dart';
import '../../domain/value_objects/insight_type.dart';
import '../datasources/insight_data_source.dart';
import '../mappers/insight_mapper.dart';

@LazySingleton(as: InsightRepository)
final class InsightRepositoryImpl implements InsightRepository {
  const InsightRepositoryImpl({
    required this.dataSource,
    required this.mapper,
    required this.validator,
  });

  final InsightDataSource dataSource;
  final InsightMapper mapper;
  final InsightStructuralValidator validator;

  @override
  Future<AppResult<void>> saveAll({
    required String organizationId,
    required List<Insight> insights,
  }) async {
    try {
      for (final insight in insights) {
        validator.validate(insight);
      }
      await dataSource.saveAll(
        organizationId: organizationId,
        insights: insights.map(mapper.toDto).toList(growable: false),
      );
      return const AppSuccess<void>(null);
    } on AppException catch (exception) {
      return AppFailure<void>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error persisting insights.',
          code: 'insight_save_all_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<InsightPage>> listPageByRecipient({
    required String organizationId,
    required String recipientUserId,
    int limit = 25,
    DateTime? before,
    InsightType? type,
    InsightStatus? status,
  }) async {
    try {
      final items = await dataSource.listPageByRecipient(
        organizationId: organizationId,
        recipientUserId: recipientUserId,
        limit: limit,
        before: before,
        type: type?.name,
        status: status?.name,
      );
      final insights = items.map(mapper.toEntity).toList(growable: false);
      return AppSuccess<InsightPage>(
        InsightPage(
          insights: insights,
          hasMore: insights.length == limit,
          nextCursor: insights.length == limit && insights.isNotEmpty
              ? insights.last.generatedAt
              : null,
        ),
      );
    } on AppException catch (exception) {
      return AppFailure<InsightPage>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<InsightPage>(
        UnexpectedFailure(
          'Unexpected error listing insights.',
          code: 'insight_list_page_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
