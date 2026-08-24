import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/product_form_draft.dart';
import '../../domain/repositories/product_form_draft_repository.dart';
import '../datasources/product_form_draft_data_source.dart';
import '../mappers/product_form_draft_mapper.dart';

@LazySingleton(as: ProductFormDraftRepository)
final class ProductFormDraftRepositoryImpl
    implements ProductFormDraftRepository {
  const ProductFormDraftRepositoryImpl({
    required this.dataSource,
    required this.mapper,
  });

  final ProductFormDraftDataSource dataSource;
  final ProductFormDraftMapper mapper;

  @override
  Future<AppResult<ProductFormDraft?>> get({
    required String organizationId,
    required String userId,
  }) async {
    try {
      final dto = await dataSource.getDraft(
        organizationId: organizationId,
        userId: userId,
      );
      return AppSuccess<ProductFormDraft?>(
        dto == null ? null : mapper.toEntity(dto),
      );
    } catch (exception) {
      return AppFailure<ProductFormDraft?>(
        UnexpectedFailure(
          'Unexpected error loading product draft.',
          code: 'product_draft_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> save(ProductFormDraft draft) async {
    try {
      await dataSource.saveDraft(mapper.toDto(draft));
      return const AppSuccess<void>(null);
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error saving product draft.',
          code: 'product_draft_save_unexpected',
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
          'Unexpected error clearing product draft.',
          code: 'product_draft_clear_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
