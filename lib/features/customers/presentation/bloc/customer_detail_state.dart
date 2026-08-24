import '../../../../core/errors/errors.dart';
import '../../domain/entities/customer.dart';

enum CustomerDetailLoadStatus { initial, loading, ready, failure }

final class CustomerDetailState {
  const CustomerDetailState({
    this.status = CustomerDetailLoadStatus.initial,
    this.organizationId = '',
    this.customerId = '',
    this.customer,
    this.failure,
  });

  final CustomerDetailLoadStatus status;
  final String organizationId;
  final String customerId;
  final Customer? customer;
  final Failure? failure;

  bool get isLoading =>
      status == CustomerDetailLoadStatus.initial ||
      status == CustomerDetailLoadStatus.loading;

  CustomerDetailState copyWith({
    CustomerDetailLoadStatus? status,
    String? organizationId,
    String? customerId,
    Customer? customer,
    bool clearCustomer = false,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return CustomerDetailState(
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      customerId: customerId ?? this.customerId,
      customer: clearCustomer ? null : customer ?? this.customer,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}
