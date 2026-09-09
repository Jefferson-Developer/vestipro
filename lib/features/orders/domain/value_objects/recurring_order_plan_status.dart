enum RecurringOrderPlanStatus {
  active,
  paused,
  canceled;

  String get label => switch (this) {
    RecurringOrderPlanStatus.active => 'Ativo',
    RecurringOrderPlanStatus.paused => 'Pausado',
    RecurringOrderPlanStatus.canceled => 'Cancelado',
  };
}
