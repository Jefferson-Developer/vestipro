import '../../../customers/domain/entities/customer.dart';
import 'crm_activity.dart';
import 'crm_task.dart';

final class NextBestActionContext {
  const NextBestActionContext({
    required this.customer,
    required this.actorUserId,
    required this.actorCanManageOthers,
    required this.customerInPortfolio,
    required this.now,
    this.activities = const <CrmActivity>[],
    this.pendingTasks = const <CrmTask>[],
    this.noContactThresholdDays = 30,
  });

  final Customer customer;
  final String actorUserId;
  final bool actorCanManageOthers;
  final bool customerInPortfolio;
  final DateTime now;
  final List<CrmActivity> activities;
  final List<CrmTask> pendingTasks;
  final int noContactThresholdDays;
}
