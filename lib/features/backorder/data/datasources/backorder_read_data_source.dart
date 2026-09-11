import '../dtos/backorder_request_dto.dart';

abstract interface class BackorderReadDataSource {
  Stream<List<BackorderRequestDto>> watchQueue({
    required String organizationId,
  });

  Stream<List<BackorderRequestDto>> watchAwaitingApproval({
    required String organizationId,
  });

  Stream<List<BackorderRequestDto>> watchForCustomer({
    required String organizationId,
    required String customerId,
  });
}
