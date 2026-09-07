import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/customer_portal_models.dart';
import '../../domain/usecases/customer_portal_use_cases.dart';

enum CustomerPortalStatus { initial, loading, ready, failure }

final class CustomerPortalState {
  const CustomerPortalState({
    this.status = CustomerPortalStatus.initial,
    this.snapshot,
    this.failureMessage,
    this.repeatedItems = const [],
  });
  final CustomerPortalStatus status;
  final CustomerPortalSnapshot? snapshot;
  final String? failureMessage;
  final List<RevalidatedPortalItem> repeatedItems;
}

final class CustomerPortalCubit extends Cubit<CustomerPortalState> {
  CustomerPortalCubit(this._load, this._repeat)
    : super(const CustomerPortalState());
  final LoadCustomerPortalUseCase _load;
  final RepeatCustomerPortalOrderUseCase _repeat;
  Future<void> load(String organizationId) async {
    emit(const CustomerPortalState(status: CustomerPortalStatus.loading));
    try {
      emit(
        CustomerPortalState(
          status: CustomerPortalStatus.ready,
          snapshot: await _load(organizationId),
        ),
      );
    } catch (_) {
      emit(
        const CustomerPortalState(
          status: CustomerPortalStatus.failure,
          failureMessage: 'Não foi possível carregar o portal.',
        ),
      );
    }
  }

  Future<void> repeatOrder(String organizationId, String orderId) async {
    final snapshot = state.snapshot;
    if (snapshot == null) return;
    try {
      emit(
        CustomerPortalState(
          status: CustomerPortalStatus.ready,
          snapshot: snapshot,
          repeatedItems: await _repeat(
            organizationId: organizationId,
            orderId: orderId,
          ),
        ),
      );
    } catch (_) {
      emit(
        CustomerPortalState(
          status: CustomerPortalStatus.failure,
          snapshot: snapshot,
          failureMessage: 'Não foi possível revalidar este pedido.',
        ),
      );
    }
  }
}
