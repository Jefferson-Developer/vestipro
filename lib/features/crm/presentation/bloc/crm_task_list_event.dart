sealed class CrmTaskListEvent {
  const CrmTaskListEvent();
}

final class CrmTaskListStarted extends CrmTaskListEvent {
  const CrmTaskListStarted({
    required this.organizationId,
    required this.userId,
    this.visibleResponsibleUserIds = const <String>{},
    this.canManageOthers = false,
  });

  final String organizationId;
  final String userId;
  final Set<String> visibleResponsibleUserIds;
  final bool canManageOthers;
}

final class CrmTaskListRetried extends CrmTaskListEvent {
  const CrmTaskListRetried();
}

final class CrmTaskListTaskCompleted extends CrmTaskListEvent {
  const CrmTaskListTaskCompleted(this.taskId);

  final String taskId;
}

final class CrmTaskListActionDismissed extends CrmTaskListEvent {
  const CrmTaskListActionDismissed();
}
