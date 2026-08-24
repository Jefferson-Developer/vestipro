import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/customer_form_draft.dart';
import '../../domain/repositories/customer_form_draft_repository.dart';
import '../datasources/customer_form_draft_data_source.dart';
import '../mappers/customer_form_draft_mapper.dart';

@LazySingleton(as: CustomerFormDraftRepository)
final class CustomerFormDraftRepositoryImpl
    implements CustomerFormDraftRepository {
  const CustomerFormDraftRepositoryImpl({
    required this.dataSource,
    required this.mapper,
  });

  final CustomerFormDraftDataSource dataSource;
  final CustomerFormDraftMapper mapper;

  @override
  Future<AppResult<CustomerFormDraft?>> get({
    required String organizationId,
    required String userId,
  }) async {
    try {
      final dto = await dataSource.getDraft(
        organizationId: organizationId,
        userId: userId,
      );
      return AppSuccess<CustomerFormDraft?>(
        dto == null ? null : mapper.toEntity(dto),
      );
    } catch (exception) {
      return AppFailure<CustomerFormDraft?>(
        UnexpectedFailure(
          'Unexpected error loading customer draft.',
          code: 'customer_draft_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> save(CustomerFormDraft draft) async {
    try {
      await dataSource.saveDraft(mapper.toDto(draft));
      return const AppSuccess<void>(null);
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error saving customer draft.',
          code: 'customer_draft_save_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> clear({
    required String organizationId,
    required String userId,
  }) async {
    try {
      await dataSource.clearDraft(
        organizationId: organizationId,
        userId: userId,
      );
      return const AppSuccess<void>(null);
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error clearing customer draft.',
          code: 'customer_draft_clear_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
