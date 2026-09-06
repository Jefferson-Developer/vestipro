import 'dart:typed_data';

import '../../../../core/utils/utils.dart';
import '../entities/customer_import_job.dart';
import '../entities/customer_import_mapping.dart';
import '../entities/customer_import_report.dart';
import '../value_objects/customer_import_duplicate_resolution.dart';

/// Domain contract for starting/tracking a `CustomerImportJob` (TASK-167).
///
/// Every mutating method here is backed by a Cloud Function using the Admin
/// SDK, never a direct Firestore write from the client (Firestore Security
/// Rules deny client `create`/`update`/`delete` on `customerImportJobs`
/// unconditionally) — the client only ever *reads* a job
/// ([watchJob]/[listByOrganization]) or *requests* one of the actions below.
abstract interface class CustomerImportJobRepository {
  /// Uploads [fileBytes] to Storage and calls `startCustomerImportJob`,
  /// which creates the Firestore job document (status `queued`) and returns
  /// its id. Processing itself happens later, asynchronously, in
  /// `processCustomerImportJob` (Firestore trigger) — this call never blocks
  /// on the whole file being parsed.
  Future<AppResult<CustomerImportJob>> startJob({
    required String organizationId,
    required String companyId,
    required String fileName,
    required bool isXlsx,
    required Uint8List fileBytes,
    required CustomerImportMapping mapping,
    String? templateId,
    required String createdBy,
  });

  /// Real-time updates for one job — the progress/report step listens to
  /// this instead of polling.
  Stream<AppResult<CustomerImportJob>> watchJob({
    required String organizationId,
    required String jobId,
  });

  Future<AppResult<List<CustomerImportJob>>> listByOrganization({
    required String organizationId,
    int limit = 20,
  });

  /// Downloads and parses the full per-row report of a completed job
  /// (`CustomerImportJob.reportStoragePath`) — only ever called once the job
  /// is `completed`/`failed`, never while still `processing`.
  Future<AppResult<CustomerImportReport>> getReport({
    required String organizationId,
    required String jobId,
    required String reportStoragePath,
  });

  /// Applies the gestor's decision for one `duplicateExisting` row via the
  /// `resolveCustomerImportDuplicateRow` Cloud Function — never resolved
  /// client-side, since [CustomerImportDuplicateResolution.merge] mutates
  /// the existing `Customer` and [CustomerImportDuplicateResolution
  /// .createAnyway] must be re-validated against the "e-mail-only match"
  /// rule server-side regardless of what the client believes.
  Future<AppResult<void>> resolveDuplicateRow({
    required String organizationId,
    required String jobId,
    required int rowNumber,
    required CustomerImportDuplicateResolution resolution,
  });
}
