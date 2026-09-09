import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../domain/entities/commission_entry.dart';
import '../../domain/usecases/watch_commission_entries_use_case.dart';
import 'commission_statement_state.dart';

@injectable
final class CommissionStatementCubit extends Cubit<CommissionStatementState> {
  CommissionStatementCubit(this._watchEntries)
    : super(const CommissionStatementState());

  final WatchCommissionEntriesUseCase _watchEntries;
  StreamSubscription<AppResult<List<CommissionEntry>>>? _subscription;

  Future<void> load({
    required String organizationId,
    required String companyId,
    required String userId,
    String? sellerId,
  }) {
    final now = DateTime.now();
    return filter(
      organizationId: organizationId,
      companyId: companyId,
      userId: userId,
      from: DateTime(now.year, now.month),
      to: DateTime(now.year, now.month + 1),
      sellerId: sellerId,
    );
  }

  Future<void> filter({
    required String organizationId,
    required String companyId,
    required String userId,
    required DateTime from,
    required DateTime to,
    String? sellerId,
    CommissionEntryStatus? status,
  }) async {
    await _subscription?.cancel();
    emit(
      state.copyWith(
        status: CommissionStatementStatus.loading,
        organizationId: organizationId,
        companyId: companyId,
        userId: userId,
        from: from,
        to: to,
        sellerId: sellerId,
        statusFilter: status,
        clearStatusFilter: status == null,
        entries: const <CommissionEntry>[],
        clearFailureMessage: true,
      ),
    );
    _subscription =
        _watchEntries(
          organizationId: organizationId,
          companyId: companyId,
          from: from,
          to: to,
          sellerId: sellerId,
          status: status,
        ).listen((result) {
          result.fold(
            onSuccess: (entries) => emit(
              state.copyWith(
                status: entries.isEmpty
                    ? CommissionStatementStatus.empty
                    : CommissionStatementStatus.ready,
                entries: entries,
              ),
            ),
            onFailure: (failure) => emit(
              state.copyWith(
                status: CommissionStatementStatus.error,
                failureMessage: failure.message,
              ),
            ),
          );
        });
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
