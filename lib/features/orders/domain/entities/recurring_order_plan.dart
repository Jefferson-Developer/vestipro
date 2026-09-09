import '../value_objects/recurring_order_plan_status.dart';
import 'order_item.dart';

enum RecurringOrderFrequencyUnit {
  days,
  weeks;

  String get label => switch (this) {
    RecurringOrderFrequencyUnit.days => 'dias',
    RecurringOrderFrequencyUnit.weeks => 'semanas',
  };
}

final class RecurringOrderFrequency {
  const RecurringOrderFrequency({required this.interval, required this.unit});

  final int interval;
  final RecurringOrderFrequencyUnit unit;

  RecurringOrderFrequency copyWith({
    int? interval,
    RecurringOrderFrequencyUnit? unit,
  }) {
    return RecurringOrderFrequency(
      interval: interval ?? this.interval,
      unit: unit ?? this.unit,
    );
  }
}

final class RecurringOrderExecution {
  const RecurringOrderExecution({
    required this.id,
    required this.scheduledFor,
    required this.processedAt,
    required this.status,
    this.orderId,
    this.orderNumber,
    this.message,
  });

  final String id;
  final DateTime scheduledFor;
  final DateTime processedAt;
  final String status;
  final String? orderId;
  final String? orderNumber;
  final String? message;
}

final class RecurringOrderPlan {
  const RecurringOrderPlan({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.customerId,
    required this.sellerId,
    required this.sourceOrderId,
    required this.frequency,
    required this.nextExecutionAt,
    required this.status,
    required this.items,
    required this.executions,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    required this.version,
  });

  final String id;
  final String organizationId;
  final String companyId;
  final String customerId;
  final String sellerId;
  final String sourceOrderId;
  final RecurringOrderFrequency frequency;
  final DateTime nextExecutionAt;
  final RecurringOrderPlanStatus status;
  final List<OrderItem> items;
  final List<RecurringOrderExecution> executions;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final int version;

  bool get canRun => status == RecurringOrderPlanStatus.active;

  RecurringOrderPlan copyWith({
    RecurringOrderFrequency? frequency,
    DateTime? nextExecutionAt,
    RecurringOrderPlanStatus? status,
    List<OrderItem>? items,
    List<RecurringOrderExecution>? executions,
    DateTime? updatedAt,
    String? updatedBy,
    int? version,
  }) {
    return RecurringOrderPlan(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      customerId: customerId,
      sellerId: sellerId,
      sourceOrderId: sourceOrderId,
      frequency: frequency ?? this.frequency,
      nextExecutionAt: nextExecutionAt ?? this.nextExecutionAt,
      status: status ?? this.status,
      items: items ?? this.items,
      executions: executions ?? this.executions,
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      version: version ?? this.version,
    );
  }
}
