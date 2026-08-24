import '../../../../core/utils/utils.dart';
import '../entities/lead.dart';

/// Domain contract for Lead persistence, decoupled from Firestore/Drift.
///
/// TASK-055 only models the entity and the qualification/conversion use
/// cases; a concrete implementation (Firestore, outbox-backed, etc.) is left
/// for a future task, matching the precedent set by `CustomerRepository`
/// (TASK-048).
abstract interface class LeadRepository {
  Future<AppResult<Lead>> create({required Lead lead});

  Future<AppResult<Lead>> update({required Lead lead});

  Future<AppResult<Lead>> getById({
    required String organizationId,
    required String id,
  });
}
