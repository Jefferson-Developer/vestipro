import '../../domain/entities/customer_segment.dart';
import '../../domain/entities/customer_segment_criteria.dart';
import '../../domain/value_objects/customer_segment_visibility.dart';

sealed class CustomerSegmentEvent {
  const CustomerSegmentEvent();
}

final class CustomerSegmentsStarted extends CustomerSegmentEvent {
  const CustomerSegmentsStarted({
    required this.organizationId,
    required this.companyId,
    required this.userId,
  });

  final String organizationId;
  final String companyId;
  final String userId;
}

final class CustomerSegmentPreviewRequested extends CustomerSegmentEvent {
  const CustomerSegmentPreviewRequested(this.criteria);

  final CustomerSegmentCriteria criteria;
}

final class CustomerSegmentSaveRequested extends CustomerSegmentEvent {
  const CustomerSegmentSaveRequested({
    required this.name,
    required this.visibility,
    required this.criteria,
  });

  final String name;
  final CustomerSegmentVisibility visibility;
  final CustomerSegmentCriteria criteria;
}

final class CustomerSegmentDeleteRequested extends CustomerSegmentEvent {
  const CustomerSegmentDeleteRequested(this.segment);

  final CustomerSegment segment;
}
