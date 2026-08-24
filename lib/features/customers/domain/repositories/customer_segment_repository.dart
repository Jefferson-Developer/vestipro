import '../../../../core/utils/utils.dart';
import '../entities/customer_segment.dart';

/// Domain contract for [CustomerSegment] persistence (TASK-053).
///
/// Implementations may use Firestore or a local store, but callers only see
/// tenant-scoped methods: every query is scoped by `organizationId`, never
/// reusable across organizations.
abstract interface class CustomerSegmentRepository {
  Future<AppResult<CustomerSegment>> create(CustomerSegment segment);

  Future<AppResult<void>> delete({
    required String organizationId,
    required String id,
  });

  Future<AppResult<List<CustomerSegment>>> listByOrganization(
    String organizationId,
  );
}
