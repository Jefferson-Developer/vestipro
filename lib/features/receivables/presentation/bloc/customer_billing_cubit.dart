import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/utils.dart';
import '../../domain/entities/billing_status_check.dart';
import '../../domain/entities/receivable.dart';
import '../../domain/usecases/receivables_use_cases.dart';
import 'customer_billing_state.dart';

/// Owns the customer 360º/pedido billing section (TASK-213): a
/// financially-authorized caller (`finance.view`) gets [watchFullDetail]'s
/// live, raw `Receivable` list; everyone else gets [loadMaskedStatus]'s
/// one-shot, status-only check — mirrors `CustomerCreditCubit` (TASK-212)
/// exactly, including which endpoint the widget calls (never this Cubit)
/// deciding the RBAC boundary.
@injectable
final class CustomerBillingCubit extends Cubit<CustomerBillingState> {
  CustomerBillingCubit({
    required this.watchReceivablesUseCase,
    required this.checkBillingStatusUseCase,
    required this.registerPaymentAllocationUseCase,
  }) : _uuid = const Uuid(),
       super(const CustomerBillingState());

  final WatchReceivablesUseCase watchReceivablesUseCase;
  final CheckBillingStatusUseCase checkBillingStatusUseCase;
  final RegisterPaymentAllocationUseCase registerPaymentAllocationUseCase;
  final Uuid _uuid;

  StreamSubscription<AppResult<List<Receivable>>>? _receivablesSubscription;

  void watchFullDetail({
    required String organizationId,
    required String customerId,
    String? orderId,
  }) {
    emit(
      const CustomerBillingState(loadStatus: CustomerBillingLoadStatus.loading),
    );
    unawaited(_receivablesSubscription?.cancel());
    _receivablesSubscription =
        watchReceivablesUseCase(
          organizationId: organizationId,
          customerId: customerId,
          orderId: orderId,
        ).listen((result) {
          switch (result) {
            case AppSuccess<List<Receivable>>(value: final receivables):
              emit(
                CustomerBillingState(
                  loadStatus: CustomerBillingLoadStatus.ready,
                  receivables: receivables,
                ),
              );
            case AppFailure<List<Receivable>>(failure: final failure):
              emit(
                CustomerBillingState(
                  loadStatus: CustomerBillingLoadStatus.failure,
                  loadFailure: failure,
                ),
              );
          }
        });
  }

  Future<void> loadMaskedStatus({
    required String organizationId,
    required String customerId,
    String? orderId,
  }) async {
    emit(
      const CustomerBillingState(loadStatus: CustomerBillingLoadStatus.loading),
    );
    final result = await checkBillingStatusUseCase(
      organizationId: organizationId,
      customerId: customerId,
      orderId: orderId,
    );
    switch (result) {
      case AppSuccess<BillingStatusCheck>(value: final check):
        emit(
          CustomerBillingState(
            loadStatus: CustomerBillingLoadStatus.ready,
            maskedCheck: check,
          ),
        );
      case AppFailure<BillingStatusCheck>(failure: final failure):
        emit(
          CustomerBillingState(
            loadStatus: CustomerBillingLoadStatus.failure,
            loadFailure: failure,
          ),
        );
    }
  }

  /// Confirms a payment against [receivableId] — `finance.manage` only,
  /// server-validated (TASK-213: "a UI nunca marca fatura como paga sem
  /// confirmação... de usuário financeiro autorizado"). A fresh
  /// `manual:{uuid}` reference is generated per submission, so a retried tap
  /// (e.g. a flaky connection) never applies the same payment twice — the
  /// callable is idempotent by this exact reference.
  Future<void> registerPayment({
    required String organizationId,
    required String receivableId,
    required double amount,
    String? note,
  }) async {
    emit(
      CustomerBillingState(
        loadStatus: state.loadStatus,
        receivables: state.receivables,
        maskedCheck: state.maskedCheck,
        actionStatus: CustomerBillingActionStatus.submitting,
      ),
    );
    final result = await registerPaymentAllocationUseCase(
      organizationId: organizationId,
      receivableId: receivableId,
      amount: amount,
      externalReference: 'manual:${_uuid.v4()}',
      note: note,
    );
    switch (result) {
      case AppSuccess<void>():
        emit(
          CustomerBillingState(
            loadStatus: state.loadStatus,
            receivables: state.receivables,
            maskedCheck: state.maskedCheck,
            actionStatus: CustomerBillingActionStatus.success,
          ),
        );
      case AppFailure<void>(failure: final failure):
        emit(
          CustomerBillingState(
            loadStatus: state.loadStatus,
            receivables: state.receivables,
            maskedCheck: state.maskedCheck,
            actionStatus: CustomerBillingActionStatus.failure,
            actionFailure: failure,
          ),
        );
    }
  }

  @override
  Future<void> close() async {
    await _receivablesSubscription?.cancel();
    return super.close();
  }
}
