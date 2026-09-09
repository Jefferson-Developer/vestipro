import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/order.dart';
import '../entities/order_item.dart';
import '../entities/recurring_order_plan.dart';
import '../value_objects/recurring_order_plan_status.dart';

abstract interface class RecurringOrderPlanRepository {
  Future<AppResult<RecurringOrderPlan>> createFromOrder({
    required Order sourceOrder,
    required RecurringOrderFrequency frequency,
    required DateTime nextExecutionAt,
    required String actorId,
  });

  Future<AppResult<RecurringOrderPlan>> updatePlan({
    required String organizationId,
    required String companyId,
    required String planId,
    required RecurringOrderFrequency frequency,
    required DateTime nextExecutionAt,
    required List<OrderItem> items,
    required String actorId,
  });

  Future<AppResult<RecurringOrderPlan>> updateStatus({
    required String organizationId,
    required String companyId,
    required String planId,
    required RecurringOrderPlanStatus status,
    required String actorId,
  });

  Future<AppResult<List<RecurringOrderPlan>>> listByCustomer({
    required String organizationId,
    required String companyId,
    required String customerId,
  });
}

ValidationFailure recurringPlanValidationFailure(Map<String, String> errors) {
  return ValidationFailure(
    'Invalid recurring order plan payload.',
    fieldErrors: errors,
    code: 'invalid_recurring_order_plan',
  );
}
