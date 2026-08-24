import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/customer_segment.dart';
import '../../domain/entities/customer_segment_preview.dart';
import '../../domain/usecases/create_customer_segment_use_case.dart';
import '../../domain/usecases/delete_customer_segment_use_case.dart';
import '../../domain/usecases/list_customer_segments_use_case.dart';
import '../../domain/usecases/preview_customer_segment_count_use_case.dart';
import 'customer_segment_event.dart';
import 'customer_segment_state.dart';

@injectable
final class CustomerSegmentBloc
    extends Bloc<CustomerSegmentEvent, CustomerSegmentState> {
  CustomerSegmentBloc({
    required this.listCustomerSegments,
    required this.createCustomerSegment,
    required this.deleteCustomerSegment,
    required this.previewCustomerSegmentCount,
  }) : super(const CustomerSegmentState()) {
    on<CustomerSegmentsStarted>(_onStarted, transformer: restartable());
    on<CustomerSegmentPreviewRequested>(
      _onPreviewRequested,
      transformer: restartable(),
    );
    on<CustomerSegmentSaveRequested>(
      _onSaveRequested,
      transformer: sequential(),
    );
    on<CustomerSegmentDeleteRequested>(
      _onDeleteRequested,
      transformer: sequential(),
    );
  }

  final ListCustomerSegmentsUseCase listCustomerSegments;
  final CreateCustomerSegmentUseCase createCustomerSegment;
  final DeleteCustomerSegmentUseCase deleteCustomerSegment;
  final PreviewCustomerSegmentCountUseCase previewCustomerSegmentCount;
  final Uuid _uuid = const Uuid();

  Future<void> _onStarted(
    CustomerSegmentsStarted event,
    Emitter<CustomerSegmentState> emit,
  ) async {
    emit(
      state.copyWith(
        listStatus: CustomerSegmentListStatus.loading,
        organizationId: event.organizationId,
        companyId: event.companyId,
        userId: event.userId,
        clearListFailure: true,
      ),
    );
    final result = await listCustomerSegments(
      organizationId: event.organizationId,
      userId: event.userId,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<List<CustomerSegment>>(value: final segments):
        emit(
          state.copyWith(
            listStatus: CustomerSegmentListStatus.ready,
            segments: segments,
            clearListFailure: true,
          ),
        );
      case AppFailure<List<CustomerSegment>>(failure: final failure):
        emit(
          state.copyWith(
            listStatus: CustomerSegmentListStatus.failure,
            listFailure: failure,
          ),
        );
    }
  }

  Future<void> _onPreviewRequested(
    CustomerSegmentPreviewRequested event,
    Emitter<CustomerSegmentState> emit,
  ) async {
    emit(
      state.copyWith(
        previewStatus: CustomerSegmentPreviewStatus.loading,
        clearPreviewFailure: true,
      ),
    );
    final result = await previewCustomerSegmentCount(
      organizationId: state.organizationId,
      companyId: state.companyId,
      userId: state.userId,
      criteria: event.criteria,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<CustomerSegmentPreview>(value: final preview):
        emit(
          state.copyWith(
            previewStatus: CustomerSegmentPreviewStatus.ready,
            preview: preview,
            clearPreviewFailure: true,
          ),
        );
      case AppFailure<CustomerSegmentPreview>(failure: final failure):
        emit(
          state.copyWith(
            previewStatus: CustomerSegmentPreviewStatus.failure,
            previewFailure: failure,
          ),
        );
    }
  }

  Future<void> _onSaveRequested(
    CustomerSegmentSaveRequested event,
    Emitter<CustomerSegmentState> emit,
  ) async {
    emit(
      state.copyWith(
        saveStatus: CustomerSegmentSaveStatus.saving,
        clearFieldErrors: true,
        clearSaveFailure: true,
        clearSavedSegment: true,
      ),
    );
    final result = await createCustomerSegment(
      id: _uuid.v4(),
      organizationId: state.organizationId,
      name: event.name,
      criteria: event.criteria,
      visibility: event.visibility,
      createdBy: state.userId,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<CustomerSegment>(value: final segment):
        final refreshed = await listCustomerSegments(
          organizationId: state.organizationId,
          userId: state.userId,
        );
        if (emit.isDone) return;
        emit(
          state.copyWith(
            saveStatus: CustomerSegmentSaveStatus.success,
            savedSegment: segment,
            segments: refreshed.fold(
              onSuccess: (segments) => segments,
              onFailure: (_) => state.segments,
            ),
            clearSaveFailure: true,
          ),
        );
      case AppFailure<CustomerSegment>(failure: final failure):
        emit(
          state.copyWith(
            saveStatus: CustomerSegmentSaveStatus.failure,
            saveFailure: failure,
            fieldErrors: failure is ValidationFailure
                ? failure.fieldErrors
                : const <String, String>{},
          ),
        );
    }
  }

  Future<void> _onDeleteRequested(
    CustomerSegmentDeleteRequested event,
    Emitter<CustomerSegmentState> emit,
  ) async {
    final result = await deleteCustomerSegment(
      segment: event.segment,
      requestedBy: state.userId,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<void>():
        emit(
          state.copyWith(
            segments: state.segments
                .where((segment) => segment.id != event.segment.id)
                .toList(growable: false),
          ),
        );
      case AppFailure<void>(failure: final failure):
        emit(state.copyWith(listFailure: failure));
    }
  }
}
