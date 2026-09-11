import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../domain/entities/credit_check_result.dart';
import '../../domain/entities/customer_credit_profile.dart';
import '../../domain/usecases/credit_use_cases.dart';
import '../../domain/value_objects/credit_block_policy.dart';
import 'customer_credit_state.dart';

/// Owns the customer 360º screen's credit section (TASK-212): a
/// financially-authorized caller (`finance.view`) gets [watchFullProfile]'s
/// live, raw `CustomerCreditProfile`; everyone else who can still see the
/// "Indicadores comerciais sensíveis" section (`report.viewSensitive`, e.g.
/// `SALES_MANAGER`) gets [loadMaskedStatus]'s one-shot, status-only check —
/// which endpoint the widget calls decides the RBAC boundary, never this
/// Cubit re-deciding a role itself.
@injectable
final class CustomerCreditCubit extends Cubit<CustomerCreditState> {
  CustomerCreditCubit({
    required this.watchProfileUseCase,
    required this.validateOrderCreditUseCase,
    required this.updateProfileUseCase,
    required this.grantOverrideUseCase,
    required this.revokeOverrideUseCase,
  }) : super(const CustomerCreditState());

  final WatchCustomerCreditProfileUseCase watchProfileUseCase;
  final ValidateOrderCreditUseCase validateOrderCreditUseCase;
  final UpdateCreditProfileUseCase updateProfileUseCase;
  final GrantCreditOverrideUseCase grantOverrideUseCase;
  final RevokeCreditOverrideUseCase revokeOverrideUseCase;

  StreamSubscription<AppResult<CustomerCreditProfile?>>? _profileSubscription;

  void watchFullProfile({
    required String organizationId,
    required String customerId,
  }) {
    emit(
      const CustomerCreditState(loadStatus: CustomerCreditLoadStatus.loading),
    );
    unawaited(_profileSubscription?.cancel());
    _profileSubscription =
        watchProfileUseCase(
          organizationId: organizationId,
          customerId: customerId,
        ).listen((result) {
          switch (result) {
            case AppSuccess<CustomerCreditProfile?>(value: final profile):
              emit(
                CustomerCreditState(
                  loadStatus: CustomerCreditLoadStatus.ready,
                  profile: profile,
                ),
              );
            case AppFailure<CustomerCreditProfile?>(failure: final failure):
              emit(
                CustomerCreditState(
                  loadStatus: CustomerCreditLoadStatus.failure,
                  loadFailure: failure,
                ),
              );
          }
        });
  }

  Future<void> loadMaskedStatus({
    required String organizationId,
    required String companyId,
    required String customerId,
  }) async {
    emit(
      const CustomerCreditState(loadStatus: CustomerCreditLoadStatus.loading),
    );
    final result = await validateOrderCreditUseCase(
      organizationId: organizationId,
      companyId: companyId,
      customerId: customerId,
      // Sem pedido em andamento aqui — reflete só a situação atual do
      // cliente (saldo/vencido/bloqueio), não um total específico.
      orderTotal: 0,
    );
    switch (result) {
      case AppSuccess<CreditCheckResult>(value: final check):
        emit(
          CustomerCreditState(
            loadStatus: CustomerCreditLoadStatus.ready,
            maskedCheck: check,
          ),
        );
      case AppFailure<CreditCheckResult>(failure: final failure):
        emit(
          CustomerCreditState(
            loadStatus: CustomerCreditLoadStatus.failure,
            loadFailure: failure,
          ),
        );
    }
  }

  Future<void> updateProfile({
    required String organizationId,
    required String companyId,
    required String customerId,
    required double creditLimit,
    required double openBalance,
    required double overdueBalance,
    required CreditBlockPolicy blockPolicy,
    double? financialScore,
    bool manualBlockActive = false,
    String? manualBlockReason,
  }) => _runAction(
    () => updateProfileUseCase(
      organizationId: organizationId,
      companyId: companyId,
      customerId: customerId,
      creditLimit: creditLimit,
      openBalance: openBalance,
      overdueBalance: overdueBalance,
      blockPolicy: blockPolicy,
      financialScore: financialScore,
      manualBlockActive: manualBlockActive,
      manualBlockReason: manualBlockReason,
    ),
  );

  Future<void> grantOverride({
    required String organizationId,
    required String companyId,
    required String customerId,
    required String reason,
    required DateTime expiresAt,
  }) => _runAction(
    () => grantOverrideUseCase(
      organizationId: organizationId,
      companyId: companyId,
      customerId: customerId,
      reason: reason,
      expiresAt: expiresAt,
    ),
  );

  Future<void> revokeOverride({
    required String organizationId,
    required String companyId,
    required String customerId,
  }) => _runAction(
    () => revokeOverrideUseCase(
      organizationId: organizationId,
      companyId: companyId,
      customerId: customerId,
    ),
  );

  /// Every mutation is followed by [_profileSubscription]'s own live update
  /// (the write goes through a Cloud Function, but the read stays a
  /// Firestore listener) — never a manual refetch, so a concurrent
  /// edit from another finance user is reflected the same way.
  Future<void> _runAction(Future<AppResult<void>> Function() action) async {
    emit(
      CustomerCreditState(
        loadStatus: state.loadStatus,
        profile: state.profile,
        maskedCheck: state.maskedCheck,
        actionStatus: CustomerCreditActionStatus.submitting,
      ),
    );
    final result = await action();
    switch (result) {
      case AppSuccess<void>():
        emit(
          CustomerCreditState(
            loadStatus: state.loadStatus,
            profile: state.profile,
            maskedCheck: state.maskedCheck,
            actionStatus: CustomerCreditActionStatus.success,
          ),
        );
      case AppFailure<void>(failure: final failure):
        emit(
          CustomerCreditState(
            loadStatus: state.loadStatus,
            profile: state.profile,
            maskedCheck: state.maskedCheck,
            actionStatus: CustomerCreditActionStatus.failure,
            actionFailure: failure,
          ),
        );
    }
  }

  @override
  Future<void> close() async {
    await _profileSubscription?.cancel();
    return super.close();
  }
}
