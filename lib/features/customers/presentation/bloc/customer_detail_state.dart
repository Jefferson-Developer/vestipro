import '../../../../core/errors/errors.dart';
import '../../../crm/crm.dart';
import '../../domain/entities/customer.dart';

enum CustomerDetailLoadStatus { initial, loading, ready, failure }

enum CustomerDetailTimelineStatus {
  initial,
  loading,
  ready,
  loadingMore,
  failure,
}

enum CustomerDetailActivitySubmissionStatus {
  idle,
  submitting,
  success,
  failure,
}

final class CustomerDetailState {
  const CustomerDetailState({
    this.status = CustomerDetailLoadStatus.initial,
    this.timelineStatus = CustomerDetailTimelineStatus.initial,
    this.activitySubmissionStatus = CustomerDetailActivitySubmissionStatus.idle,
    this.organizationId = '',
    this.customerId = '',
    this.userId = '',
    this.customer,
    this.activities = const <CrmActivity>[],
    this.activitiesHasMore = false,
    this.activitiesNextCursor,
    this.failure,
    this.timelineFailure,
    this.activitySubmissionFailure,
  });

  final CustomerDetailLoadStatus status;
  final CustomerDetailTimelineStatus timelineStatus;
  final CustomerDetailActivitySubmissionStatus activitySubmissionStatus;
  final String organizationId;
  final String customerId;
  final String userId;
  final Customer? customer;
  final List<CrmActivity> activities;
  final bool activitiesHasMore;
  final String? activitiesNextCursor;
  final Failure? failure;
  final Failure? timelineFailure;
  final Failure? activitySubmissionFailure;

  bool get isLoading =>
      status == CustomerDetailLoadStatus.initial ||
      status == CustomerDetailLoadStatus.loading;

  bool get isTimelineLoading =>
      timelineStatus == CustomerDetailTimelineStatus.initial ||
      timelineStatus == CustomerDetailTimelineStatus.loading;

  bool get isLoadingMoreActivities =>
      timelineStatus == CustomerDetailTimelineStatus.loadingMore;

  bool get isSubmittingActivity =>
      activitySubmissionStatus ==
      CustomerDetailActivitySubmissionStatus.submitting;

  CustomerDetailState copyWith({
    CustomerDetailLoadStatus? status,
    CustomerDetailTimelineStatus? timelineStatus,
    CustomerDetailActivitySubmissionStatus? activitySubmissionStatus,
    String? organizationId,
    String? customerId,
    String? userId,
    Customer? customer,
    bool clearCustomer = false,
    List<CrmActivity>? activities,
    bool? activitiesHasMore,
    String? activitiesNextCursor,
    bool clearActivitiesNextCursor = false,
    Failure? failure,
    bool clearFailure = false,
    Failure? timelineFailure,
    bool clearTimelineFailure = false,
    Failure? activitySubmissionFailure,
    bool clearActivitySubmissionFailure = false,
  }) {
    return CustomerDetailState(
      status: status ?? this.status,
      timelineStatus: timelineStatus ?? this.timelineStatus,
      activitySubmissionStatus:
          activitySubmissionStatus ?? this.activitySubmissionStatus,
      organizationId: organizationId ?? this.organizationId,
      customerId: customerId ?? this.customerId,
      userId: userId ?? this.userId,
      customer: clearCustomer ? null : customer ?? this.customer,
      activities: activities ?? this.activities,
      activitiesHasMore: activitiesHasMore ?? this.activitiesHasMore,
      activitiesNextCursor: clearActivitiesNextCursor
          ? null
          : activitiesNextCursor ?? this.activitiesNextCursor,
      failure: clearFailure ? null : failure ?? this.failure,
      timelineFailure: clearTimelineFailure
          ? null
          : timelineFailure ?? this.timelineFailure,
      activitySubmissionFailure: clearActivitySubmissionFailure
          ? null
          : activitySubmissionFailure ?? this.activitySubmissionFailure,
    );
  }
}
