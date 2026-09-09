import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/order_item.dart';
import '../entities/recurring_order_plan.dart';
import '../repositories/recurring_order_plan_repository.dart';
import '../value_objects/recurring_order_plan_status.dart';

@injectable
class UpdateRecurringOrderPlanUseCase {
  const UpdateRecurringOrderPlanUseCase(this._repository);

  final RecurringOrderPlanRepository _repository;

  Future<AppResult<RecurringOrderPlan>> updateScheduleAndItems({
    required String organizationId,
    required String companyId,
    required String planId,
    required RecurringOrderFrequency frequency,
    required DateTime nextExecutionAt,
    required List<OrderItem> items,
    required String actorId,
  }) async {
    final errors = <String, String>{};
    if (frequency.interval <= 0) {
      errors['frequency'] = 'Frequency interval must be positive.';
    }
    if (items.isEmpty) {
      errors['items'] = 'At least one item is required.';
    }
    if (errors.isNotEmpty) {
      return AppFailure<RecurringOrderPlan>(
        recurringPlanValidationFailure(errors),
      );
    }
    return _repository.updatePlan(
      organizationId: organizationId,
      companyId: companyId,
      planId: planId,
      frequency: frequency,
      nextExecutionAt: nextExecutionAt.toUtc(),
      items: items,
      actorId: actorId,
    );
  }

  Future<AppResult<RecurringOrderPlan>> pause({
    required String organizationId,
    required String companyId,
    required String planId,
    required String actorId,
  }) {
    return _repository.updateStatus(
      organizationId: organizationId,
      companyId: companyId,
      planId: planId,
      status: RecurringOrderPlanStatus.paused,
      actorId: actorId,
    );
  }

  Future<AppResult<RecurringOrderPlan>> cancel({
    required String organizationId,
    required String companyId,
    required String planId,
    required String actorId,
  }) {
    return _repository.updateStatus(
      organizationId: organizationId,
      companyId: companyId,
      planId: planId,
      status: RecurringOrderPlanStatus.canceled,
      actorId: actorId,
    );
  }
}
