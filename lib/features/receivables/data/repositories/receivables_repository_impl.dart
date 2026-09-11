import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/billing_status_check.dart';
import '../../domain/entities/receivable.dart';
import '../../domain/repositories/receivables_repository.dart';
import '../datasources/receivables_read_data_source.dart';
import '../datasources/receivables_write_data_source.dart';
import '../mappers/receivables_mapper.dart';

@LazySingleton(as: ReceivablesRepository)
final class ReceivablesRepositoryImpl implements ReceivablesRepository {
  const ReceivablesRepositoryImpl(this._readDataSource, this._writeDataSource);

  final ReceivablesReadDataSource _readDataSource;
  final ReceivablesWriteDataSource _writeDataSource;

  @override
  Future<AppResult<BillingStatusCheck>> checkBillingStatus({
    required String organizationId,
    required String customerId,
    String? orderId,
  }) => _guard(() async {
    final dto = await _writeDataSource.checkBillingStatus(
      organizationId: organizationId,
      customerId: customerId,
      orderId: orderId,
    );
    return dto.toDomain();
  });

  @override
  Stream<AppResult<List<Receivable>>> watchReceivables({
    required String organizationId,
    required String customerId,
    String? orderId,
  }) async* {
    try {
      await for (final dtos in _readDataSource.watchReceivables(
        organizationId: organizationId,
        customerId: customerId,
        orderId: orderId,
      )) {
        yield AppSuccess<List<Receivable>>(
          dtos.map((dto) => dto.toDomain()).toList(growable: false),
        );
      }
    } catch (error) {
      yield AppFailure<List<Receivable>>(
        UnexpectedFailure(
          'Unexpected error loading receivables.',
          code: 'receivables_watch_unexpected',
          cause: error,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> registerPaymentAllocation({
    required String organizationId,
    required String receivableId,
    required double amount,
    required String externalReference,
    String source = 'manual',
    String? note,
  }) => _guard(() {
    return _writeDataSource.registerPaymentAllocation(
      organizationId: organizationId,
      receivableId: receivableId,
      amount: amount,
      source: source,
      externalReference: externalReference,
      note: note,
    );
  });

  Future<AppResult<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return AppSuccess<T>(await action());
    } on AppException catch (error) {
      return AppFailure<T>(mapAppExceptionToFailure(error));
    } catch (error) {
      return AppFailure<T>(
        UnexpectedFailure(
          'Unexpected error managing receivables.',
          code: 'receivables_unexpected',
          cause: error,
        ),
      );
    }
  }
}
