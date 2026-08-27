import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/payment_term.dart';
import '../../domain/repositories/payment_term_local_store_repository.dart';
import '../mappers/payment_term_local_mapper.dart';

@LazySingleton(as: PaymentTermLocalStoreRepository)
final class DriftPaymentTermLocalStoreRepository
    implements PaymentTermLocalStoreRepository {
  const DriftPaymentTermLocalStoreRepository(this._database, this._mapper);

  final AppDatabase _database;
  final PaymentTermLocalMapper _mapper;

  @override
  Future<AppResult<int>> count({
    required String organizationId,
    required String companyId,
  }) async {
    try {
      final total = await _database.countPaymentTermsForCompany(
        organizationId: organizationId,
        companyId: companyId,
      );
      return AppSuccess<int>(total);
    } catch (exception) {
      return AppFailure<int>(
        UnexpectedFailure(
          'Unexpected error counting local payment term cache.',
          code: 'payment_term_offline_count_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<PaymentTerm>>> getAll({
    required String organizationId,
    required String companyId,
  }) async {
    try {
      final rows = await _database.getPaymentTermsForCompany(
        organizationId: organizationId,
        companyId: companyId,
      );
      return AppSuccess<List<PaymentTerm>>(
        rows.map(_mapper.fromRow).toList(growable: false),
      );
    } catch (exception) {
      return AppFailure<List<PaymentTerm>>(
        UnexpectedFailure(
          'Unexpected error loading local payment term cache.',
          code: 'payment_term_offline_read_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> replaceInitialLoad({
    required String organizationId,
    required String companyId,
    required List<PaymentTerm> paymentTerms,
  }) async {
    try {
      await _database.replacePaymentTerms(
        organizationId: organizationId,
        companyId: companyId,
        paymentTermRows: paymentTerms
            .map(_mapper.toRow)
            .toList(growable: false),
      );
      return const AppSuccess<void>(null);
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error replacing local payment term cache.',
          code: 'payment_term_offline_replace_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> upsert({required PaymentTerm paymentTerm}) async {
    try {
      await _database.upsertPaymentTerm(_mapper.toRow(paymentTerm));
      return const AppSuccess<void>(null);
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error upserting local payment term.',
          code: 'payment_term_offline_upsert_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
