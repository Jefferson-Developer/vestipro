import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/customer_segment.dart';
import '../../domain/repositories/customer_segment_repository.dart';
import '../datasources/customer_segment_data_source.dart';
import '../mappers/customer_segment_mapper.dart';

@LazySingleton(as: CustomerSegmentRepository)
final class CustomerSegmentRepositoryImpl implements CustomerSegmentRepository {
  const CustomerSegmentRepositoryImpl({
    required this.dataSource,
    required this.mapper,
  });

  final CustomerSegmentDataSource dataSource;
  final CustomerSegmentMapper mapper;

  @override
  Future<AppResult<CustomerSegment>> create(CustomerSegment segment) async {
    try {
      await dataSource.upsert(mapper.toDto(segment));
      return AppSuccess<CustomerSegment>(segment);
    } catch (exception) {
      return AppFailure<CustomerSegment>(
        UnexpectedFailure(
          'Unexpected error saving customer segment locally.',
          code: 'customer_segment_local_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> delete({
    required String organizationId,
    required String id,
  }) async {
    try {
      await dataSource.delete(organizationId: organizationId, id: id);
      return const AppSuccess<void>(null);
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error deleting customer segment locally.',
          code: 'customer_segment_local_delete_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<CustomerSegment>>> listByOrganization(
    String organizationId,
  ) async {
    try {
      final dtos = await dataSource.listByOrganization(organizationId);
      return AppSuccess<List<CustomerSegment>>(
        dtos.map(mapper.toEntity).toList(growable: false),
      );
    } catch (exception) {
      return AppFailure<List<CustomerSegment>>(
        UnexpectedFailure(
          'Unexpected error listing customer segments locally.',
          code: 'customer_segment_local_list_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
