import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/commission_entry.dart';
import '../../domain/repositories/commission_repository.dart';
import '../datasources/commission_entry_data_source.dart';
import '../mappers/commission_entry_mapper.dart';

@LazySingleton(as: CommissionRepository)
final class CommissionRepositoryImpl implements CommissionRepository {
  const CommissionRepositoryImpl(this._dataSource);

  final CommissionEntryDataSource _dataSource;

  @override
  Stream<AppResult<List<CommissionEntry>>> watchEntries({
    required String organizationId,
    required String companyId,
    required DateTime from,
    required DateTime to,
    String? sellerId,
    CommissionEntryStatus? status,
  }) async* {
    try {
      await for (final items in _dataSource.watchEntries(
        organizationId: organizationId,
        companyId: companyId,
        from: from,
        to: to,
        sellerId: sellerId,
        status: status?.code,
      )) {
        yield AppSuccess<List<CommissionEntry>>(
          items.map((item) => item.toDomain()).toList(growable: false),
        );
      }
    } catch (error) {
      yield AppFailure<List<CommissionEntry>>(
        UnexpectedFailure(
          'Unexpected error loading commission entries.',
          code: 'commission_entries_watch_unexpected',
          cause: error,
        ),
      );
    }
  }
}
