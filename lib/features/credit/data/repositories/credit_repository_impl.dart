import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/credit_check_result.dart';
import '../../domain/entities/customer_credit_profile.dart';
import '../../domain/repositories/credit_repository.dart';
import '../../domain/value_objects/credit_block_policy.dart';
import '../datasources/credit_read_data_source.dart';
import '../datasources/credit_write_data_source.dart';
import '../mappers/credit_mapper.dart';

@LazySingleton(as: CreditRepository)
final class CreditRepositoryImpl implements CreditRepository {
  const CreditRepositoryImpl(this._readDataSource, this._writeDataSource);

  final CreditReadDataSource _readDataSource;
  final CreditWriteDataSource _writeDataSource;

  @override
  Future<AppResult<CreditCheckResult>> validateOrderCredit({
    required String organizationId,
    required String companyId,
    required String customerId,
    required double orderTotal,
  }) => _guard(() async {
    final dto = await _writeDataSource.validateOrderCredit(
      organizationId: organizationId,
      companyId: companyId,
      customerId: customerId,
      orderTotal: orderTotal,
    );
    return dto.toDomain();
  });

  @override
  Stream<AppResult<CustomerCreditProfile?>> watchProfile({
    required String organizationId,
    required String customerId,
  }) async* {
    try {
      await for (final dto in _readDataSource.watchProfile(
        organizationId: organizationId,
        customerId: customerId,
      )) {
        yield AppSuccess<CustomerCreditProfile?>(dto?.toDomain());
      }
    } catch (error) {
      yield AppFailure<CustomerCreditProfile?>(
        UnexpectedFailure(
          'Unexpected error loading the customer credit profile.',
          code: 'credit_profile_watch_unexpected',
          cause: error,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> updateProfile({
    required String organizationId,
    required String companyId,
    required String customerId,
    required double creditLimit,
    required double openBalance,
    required double overdueBalance,
    required CreditBlockPolicy blockPolicy,
    double? financialScore,
    String dataSource = 'manual',
    bool manualBlockActive = false,
    String? manualBlockReason,
  }) => _guard(() {
    return _writeDataSource.updateProfile(
      organizationId: organizationId,
      companyId: companyId,
      customerId: customerId,
      creditLimit: creditLimit,
      openBalance: openBalance,
      overdueBalance: overdueBalance,
      blockPolicy: blockPolicy.code,
      financialScore: financialScore,
      dataSource: dataSource,
      manualBlockActive: manualBlockActive,
      manualBlockReason: manualBlockReason,
    );
  });

  @override
  Future<AppResult<void>> grantOverride({
    required String organizationId,
    required String companyId,
    required String customerId,
    required String reason,
    required DateTime expiresAt,
  }) => _guard(() {
    return _writeDataSource.grantOverride(
      organizationId: organizationId,
      companyId: companyId,
      customerId: customerId,
      reason: reason,
      expiresAt: expiresAt.toUtc().toIso8601String(),
    );
  });

  @override
  Future<AppResult<void>> revokeOverride({
    required String organizationId,
    required String companyId,
    required String customerId,
  }) => _guard(() {
    return _writeDataSource.revokeOverride(
      organizationId: organizationId,
      companyId: companyId,
      customerId: customerId,
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
          'Unexpected error managing customer credit.',
          code: 'credit_unexpected',
          cause: error,
        ),
      );
    }
  }
}
