import '../../../../core/errors/errors.dart';
import '../../domain/entities/customer_segment.dart';
import '../../domain/entities/customer_segment_preview.dart';

enum CustomerSegmentListStatus { loading, ready, failure }

enum CustomerSegmentPreviewStatus { idle, loading, ready, failure }

enum CustomerSegmentSaveStatus { idle, saving, success, failure }

final class CustomerSegmentState {
  const CustomerSegmentState({
    this.listStatus = CustomerSegmentListStatus.loading,
    this.organizationId = '',
    this.companyId = '',
    this.userId = '',
    this.segments = const <CustomerSegment>[],
    this.listFailure,
    this.previewStatus = CustomerSegmentPreviewStatus.idle,
    this.preview,
    this.previewFailure,
    this.saveStatus = CustomerSegmentSaveStatus.idle,
    this.saveFailure,
    this.fieldErrors = const <String, String>{},
    this.savedSegment,
  });

  final CustomerSegmentListStatus listStatus;
  final String organizationId;
  final String companyId;
  final String userId;
  final List<CustomerSegment> segments;
  final Failure? listFailure;
  final CustomerSegmentPreviewStatus previewStatus;
  final CustomerSegmentPreview? preview;
  final Failure? previewFailure;
  final CustomerSegmentSaveStatus saveStatus;
  final Failure? saveFailure;
  final Map<String, String> fieldErrors;
  final CustomerSegment? savedSegment;

  CustomerSegmentState copyWith({
    CustomerSegmentListStatus? listStatus,
    String? organizationId,
    String? companyId,
    String? userId,
    List<CustomerSegment>? segments,
    Failure? listFailure,
    bool clearListFailure = false,
    CustomerSegmentPreviewStatus? previewStatus,
    CustomerSegmentPreview? preview,
    bool clearPreview = false,
    Failure? previewFailure,
    bool clearPreviewFailure = false,
    CustomerSegmentSaveStatus? saveStatus,
    Failure? saveFailure,
    bool clearSaveFailure = false,
    Map<String, String>? fieldErrors,
    bool clearFieldErrors = false,
    CustomerSegment? savedSegment,
    bool clearSavedSegment = false,
  }) {
    return CustomerSegmentState(
      listStatus: listStatus ?? this.listStatus,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      segments: segments ?? this.segments,
      listFailure: clearListFailure ? null : listFailure ?? this.listFailure,
      previewStatus: previewStatus ?? this.previewStatus,
      preview: clearPreview ? null : preview ?? this.preview,
      previewFailure: clearPreviewFailure
          ? null
          : previewFailure ?? this.previewFailure,
      saveStatus: saveStatus ?? this.saveStatus,
      saveFailure: clearSaveFailure ? null : saveFailure ?? this.saveFailure,
      fieldErrors: clearFieldErrors
          ? const <String, String>{}
          : fieldErrors ?? this.fieldErrors,
      savedSegment: clearSavedSegment
          ? null
          : savedSegment ?? this.savedSegment,
    );
  }
}
