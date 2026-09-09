import 'package:injectable/injectable.dart' hide Order;

import '../../../../core/utils/utils.dart';
import '../entities/order.dart';
import '../entities/recurring_order_plan.dart';
import '../repositories/recurring_order_plan_repository.dart';

@injectable
class CreateRecurringOrderPlanUseCase {
  const CreateRecurringOrderPlanUseCase(this._repository);

  final RecurringOrderPlanRepository _repository;

  Future<AppResult<RecurringOrderPlan>> call({
    required Order sourceOrder,
    required RecurringOrderFrequency frequency,
    required DateTime nextExecutionAt,
    required String actorId,
  }) async {
    final errors = <String, String>{};
    if (sourceOrder.items.isEmpty) {
      errors['items'] = 'At least one item is required.';
    }
    if (frequency.interval <= 0) {
      errors['frequency'] = 'Frequency interval must be positive.';
    }
    if (nextExecutionAt.toUtc().isBefore(DateTime.now().toUtc())) {
      errors['nextExecutionAt'] = 'Next execution must be in the future.';
    }
    if (actorId.trim().isEmpty) {
      errors['actorId'] = 'ActorId is required.';
    }
    if (errors.isNotEmpty) {
      return AppFailure<RecurringOrderPlan>(
        recurringPlanValidationFailure(errors),
      );
    }
    return _repository.createFromOrder(
      sourceOrder: sourceOrder,
      frequency: frequency,
      nextExecutionAt: nextExecutionAt.toUtc(),
      actorId: actorId.trim(),
    );
  }
}
