import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/order_signature.dart';
import '../../domain/repositories/order_signature_draft_repository.dart';
import '../mappers/order_signature_local_mapper.dart';

/// Drift-backed implementation of [OrderSignatureDraftRepository] (EPIC-13,
/// TASK-180) — mirrors `DriftOrderDraftRepository`'s own shape for `Order`
/// itself.
@LazySingleton(as: OrderSignatureDraftRepository)
final class DriftOrderSignatureDraftRepository
    implements OrderSignatureDraftRepository {
  const DriftOrderSignatureDraftRepository(this._database, this._mapper);

  final AppDatabase _database;
  final OrderSignatureLocalMapper _mapper;

  @override
  Future<AppResult<void>> saveLocal({required OrderSignature signature}) async {
    try {
      await _database.upsertOrderSignature(_mapper.toRow(signature));
      return const AppSuccess<void>(null);
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error saving local order signature.',
          code: 'order_signature_save_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<OrderSignature?>> getByOrderId({
    required String organizationId,
    required String companyId,
    required String orderId,
  }) async {
    try {
      final row = await _database.getOrderSignatureByOrderId(
        organizationId: organizationId,
        companyId: companyId,
        orderId: orderId,
      );
      if (row == null) return const AppSuccess<OrderSignature?>(null);
      return AppSuccess<OrderSignature?>(_mapper.fromRow(row));
    } catch (exception) {
      return AppFailure<OrderSignature?>(
        UnexpectedFailure(
          'Unexpected error loading local order signature.',
          code: 'order_signature_read_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<OrderSignature>>> getPendingSync({
    required String organizationId,
    required String companyId,
  }) async {
    try {
      final rows = await _database.getPendingSyncOrderSignatures(
        organizationId: organizationId,
        companyId: companyId,
      );
      return AppSuccess<List<OrderSignature>>(
        rows.map(_mapper.fromRow).toList(growable: false),
      );
    } catch (exception) {
      return AppFailure<List<OrderSignature>>(
        UnexpectedFailure(
          'Unexpected error loading pending local order signatures.',
          code: 'order_signature_pending_list_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
