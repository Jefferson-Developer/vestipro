import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../../crm/crm.dart';
import '../../domain/entities/customer.dart';
import '../../domain/usecases/get_customer_by_id_use_case.dart';
import 'customer_detail_event.dart';
import 'customer_detail_state.dart';

@injectable
final class CustomerDetailBloc
    extends Bloc<CustomerDetailEvent, CustomerDetailState> {
  CustomerDetailBloc({
    required this.getCustomerById,
    required this.listActivitiesForCustomer,
    required this.registerActivity,
    required this.analyticsService,
  }) : super(const CustomerDetailState()) {
    on<CustomerDetailStarted>(_onStarted);
    on<CustomerDetailRetried>(_onRetried);
    on<CustomerDetailTimelineRetried>(_onTimelineRetried);
    on<CustomerDetailTimelineLoadMoreRequested>(_onTimelineLoadMoreRequested);
    on<CustomerDetailActivitySubmitted>(_onActivitySubmitted);
    on<CustomerDetailActivitySubmissionAcknowledged>(
      _onActivitySubmissionAcknowledged,
    );
  }

  final GetCustomerByIdUseCase getCustomerById;
  final ListCrmActivitiesForCustomerUseCase listActivitiesForCustomer;
  final RegisterCrmActivityUseCase registerActivity;
  final AnalyticsService analyticsService;
  final Uuid _uuid = const Uuid();

  Future<void> _onStarted(
    CustomerDetailStarted event,
    Emitter<CustomerDetailState> emit,
  ) async {
    emit(
      const CustomerDetailState().copyWith(
        status: CustomerDetailLoadStatus.loading,
        timelineStatus: CustomerDetailTimelineStatus.loading,
        organizationId: event.organizationId,
        customerId: event.customerId,
        userId: event.userId,
        clearCustomer: true,
        activities: const <CrmActivity>[],
        activitiesHasMore: false,
        clearActivitiesNextCursor: true,
        clearFailure: true,
        clearTimelineFailure: true,
        clearActivitySubmissionFailure: true,
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
        timelineStatus: CustomerDetailTimelineStatus.loading,
        clearCustomer: true,
        activities: const <CrmActivity>[],
        activitiesHasMore: false,
        clearActivitiesNextCursor: true,
        clearFailure: true,
        clearTimelineFailure: true,
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
        await _loadActivities(emit);
      case AppFailure<Customer>(failure: final failure):
        emit(
          state.copyWith(
            status: CustomerDetailLoadStatus.failure,
            timelineStatus: CustomerDetailTimelineStatus.failure,
            clearCustomer: true,
            failure: failure,
          ),
        );
    }
  }

  Future<void> _onTimelineRetried(
    CustomerDetailTimelineRetried event,
    Emitter<CustomerDetailState> emit,
  ) async {
    emit(
      state.copyWith(
        timelineStatus: CustomerDetailTimelineStatus.loading,
        activities: const <CrmActivity>[],
        activitiesHasMore: false,
        clearActivitiesNextCursor: true,
        clearTimelineFailure: true,
      ),
    );
    await _loadActivities(emit);
  }

  Future<void> _onTimelineLoadMoreRequested(
    CustomerDetailTimelineLoadMoreRequested event,
    Emitter<CustomerDetailState> emit,
  ) async {
    if (!state.activitiesHasMore || state.isLoadingMoreActivities) return;
    emit(
      state.copyWith(
        timelineStatus: CustomerDetailTimelineStatus.loadingMore,
        clearTimelineFailure: true,
      ),
    );
    await _loadActivities(emit, append: true);
  }

  Future<void> _loadActivities(
    Emitter<CustomerDetailState> emit, {
    bool append = false,
  }) async {
    final result = await listActivitiesForCustomer(
      organizationId: state.organizationId,
      customerId: state.customerId,
      cursor: append ? state.activitiesNextCursor : null,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<CrmActivityPageResult>(value: final page):
        emit(
          state.copyWith(
            timelineStatus: CustomerDetailTimelineStatus.ready,
            activities: append
                ? <CrmActivity>[...state.activities, ...page.activities]
                : page.activities,
            activitiesHasMore: page.hasMore,
            activitiesNextCursor: page.nextCursor,
            clearActivitiesNextCursor: page.nextCursor == null,
            clearTimelineFailure: true,
          ),
        );
      case AppFailure<CrmActivityPageResult>(failure: final failure):
        emit(
          state.copyWith(
            timelineStatus: CustomerDetailTimelineStatus.failure,
            timelineFailure: failure,
          ),
        );
    }
  }

  Future<void> _onActivitySubmitted(
    CustomerDetailActivitySubmitted event,
    Emitter<CustomerDetailState> emit,
  ) async {
    if (state.isSubmittingActivity) return;
    emit(
      state.copyWith(
        activitySubmissionStatus:
            CustomerDetailActivitySubmissionStatus.submitting,
        clearActivitySubmissionFailure: true,
      ),
    );

    final result = await registerActivity(
      id: _uuid.v4(),
      organizationId: state.organizationId,
      customerId: state.customerId,
      userId: state.userId,
      type: event.type,
      description: event.description,
      durationMinutes: event.durationMinutes,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<CrmActivity>(value: final activity):
        await analyticsService.logEvent(
          AnalyticsEvents.crmActivityCreated,
          parameters: <String, Object?>{
            'organization_id': state.organizationId,
            'customer_id': state.customerId,
            'activity_id': activity.id,
            'activity_type': activity.type.analyticsCode,
            'sync_status': activity.syncStatus.name,
          },
        );
        if (emit.isDone) return;
        emit(
          state.copyWith(
            activitySubmissionStatus:
                CustomerDetailActivitySubmissionStatus.success,
            activities: <CrmActivity>[activity, ...state.activities],
            clearActivitySubmissionFailure: true,
            timelineStatus: CustomerDetailTimelineStatus.ready,
          ),
        );
      case AppFailure<CrmActivity>(failure: final failure):
        emit(
          state.copyWith(
            activitySubmissionStatus:
                CustomerDetailActivitySubmissionStatus.failure,
            activitySubmissionFailure: failure,
          ),
        );
    }
  }

  void _onActivitySubmissionAcknowledged(
    CustomerDetailActivitySubmissionAcknowledged event,
    Emitter<CustomerDetailState> emit,
  ) {
    emit(
      state.copyWith(
        activitySubmissionStatus: CustomerDetailActivitySubmissionStatus.idle,
        clearActivitySubmissionFailure: true,
      ),
    );
  }
}
