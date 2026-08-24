import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../domain/entities/customer.dart';
import '../../domain/usecases/get_customer_by_id_use_case.dart';
import 'customer_detail_event.dart';
import 'customer_detail_state.dart';

@injectable
final class CustomerDetailBloc
    extends Bloc<CustomerDetailEvent, CustomerDetailState> {
  CustomerDetailBloc({required this.getCustomerById})
    : super(const CustomerDetailState()) {
    on<CustomerDetailStarted>(_onStarted);
    on<CustomerDetailRetried>(_onRetried);
  }

  final GetCustomerByIdUseCase getCustomerById;

  Future<void> _onStarted(
    CustomerDetailStarted event,
    Emitter<CustomerDetailState> emit,
  ) async {
    emit(
      const CustomerDetailState().copyWith(
        status: CustomerDetailLoadStatus.loading,
        organizationId: event.organizationId,
        customerId: event.customerId,
        clearCustomer: true,
        clearFailure: true,
      ),
    );
    await _load(emit);
  }

  Future<void> _onRetried(
    CustomerDetailRetried event,
    Emitter<CustomerDetailState> emit,
  ) async {
    emit(
      state.copyWith(
        status: CustomerDetailLoadStatus.loading,
        clearCustomer: true,
        clearFailure: true,
      ),
    );
    await _load(emit);
  }

  Future<void> _load(Emitter<CustomerDetailState> emit) async {
    final result = await getCustomerById(
      organizationId: state.organizationId,
      id: state.customerId,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<Customer>(value: final customer):
        emit(
          state.copyWith(
            status: CustomerDetailLoadStatus.ready,
            customer: customer,
            clearFailure: true,
          ),
        );
      case AppFailure<Customer>(failure: final failure):
        emit(
          state.copyWith(
            status: CustomerDetailLoadStatus.failure,
            clearCustomer: true,
            failure: failure,
          ),
        );
    }
  }
}
