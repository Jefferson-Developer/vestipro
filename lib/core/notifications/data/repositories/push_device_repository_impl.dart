import 'package:injectable/injectable.dart';

import '../../../errors/errors.dart';
import '../../../utils/utils.dart';
import '../../domain/entities/push_device.dart';
import '../../domain/repositories/push_device_repository.dart';
import '../datasources/push_device_data_source.dart';
import '../mappers/push_device_mapper.dart';

@LazySingleton(as: PushDeviceRepository)
final class PushDeviceRepositoryImpl implements PushDeviceRepository {
  const PushDeviceRepositoryImpl({
    required this.dataSource,
    required this.mapper,
  });

  final PushDeviceDataSource dataSource;
  final PushDeviceMapper mapper;

  @override
  Future<AppResult<void>> upsert(PushDevice device) async {
    try {
      await dataSource.upsert(mapper.toDto(device));
      return const AppSuccess<void>(null);
    } on AppException catch (exception) {
      return AppFailure<void>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error registering push device.',
          code: 'push_device_upsert_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> deactivate({
    required String organizationId,
    required String deviceId,
  }) async {
    try {
      await dataSource.softDelete(
        organizationId: organizationId,
        id: deviceId,
        deletedAt: DateTime.now().toUtc(),
      );
      return const AppSuccess<void>(null);
    } on AppException catch (exception) {
      return AppFailure<void>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error deactivating push device.',
          code: 'push_device_deactivate_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
