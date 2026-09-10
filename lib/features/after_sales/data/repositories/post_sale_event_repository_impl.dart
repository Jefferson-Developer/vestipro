import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/post_sale_event.dart';
import '../../domain/entities/post_sale_event_submission_result.dart';
import '../../domain/repositories/post_sale_event_repository.dart';
import '../../domain/value_objects/post_sale_event_type.dart';
import '../datasources/post_sale_event_read_data_source.dart';
import '../datasources/post_sale_event_write_data_source.dart';
import '../mappers/post_sale_event_mapper.dart';

@LazySingleton(as: PostSaleEventRepository)
final class PostSaleEventRepositoryImpl implements PostSaleEventRepository {
  const PostSaleEventRepositoryImpl(
    this._readDataSource,
    this._writeDataSource,
  );

  final PostSaleEventReadDataSource _readDataSource;
  final PostSaleEventWriteDataSource _writeDataSource;

  @override
  Future<AppResult<PostSaleEventSubmissionResult>> registerPostSaleEvent({
    required String organizationId,
    required String companyId,
    required String orderId,
    required String eventId,
    required PostSaleEventType type,
    String? description,
  }) async {
    try {
      final result = await _writeDataSource.register(
        organizationId: organizationId,
        companyId: companyId,
        orderId: orderId,
        eventId: eventId,
        type: type,
        description: description,
      );
      return AppSuccess<PostSaleEventSubmissionResult>(
        PostSaleEventSubmissionResult(
          eventId: result.eventId,
          orderId: result.orderId,
          type: PostSaleEventType.fromCode(result.type),
          description: result.description,
          createdAt: result.createdAt,
        ),
      );
    } on AppException catch (exception) {
      return AppFailure<PostSaleEventSubmissionResult>(
        mapAppExceptionToFailure(exception),
      );
    } catch (error) {
      return AppFailure<PostSaleEventSubmissionResult>(
        UnexpectedFailure(
          'Unexpected error registering the post-sale event.',
          code: 'post_sale_event_register_unexpected',
          cause: error,
        ),
      );
    }
  }

  @override
  Stream<AppResult<List<PostSaleEvent>>> watchByOrder({
    required String organizationId,
    required String orderId,
  }) async* {
    try {
      await for (final items in _readDataSource.watchByOrder(
        organizationId: organizationId,
        orderId: orderId,
      )) {
        yield AppSuccess<List<PostSaleEvent>>(
          items.map((item) => item.toDomain()).toList(growable: false),
        );
      }
    } catch (error) {
      yield AppFailure<List<PostSaleEvent>>(
        UnexpectedFailure(
          'Unexpected error loading the post-sale timeline.',
          code: 'post_sale_timeline_watch_unexpected',
          cause: error,
        ),
      );
    }
  }
}
