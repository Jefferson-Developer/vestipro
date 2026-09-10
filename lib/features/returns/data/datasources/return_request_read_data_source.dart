import '../dtos/return_request_dto.dart';

abstract interface class ReturnRequestReadDataSource {
  Stream<List<ReturnRequestDto>> watchByOrder({
    required String organizationId,
    required String orderId,
  });

  Stream<List<ReturnRequestDto>> watchQueue({
    required String organizationId,
    required String companyId,
    required bool allCompany,
    required Set<String> sellerIds,
  });
}
