import '../dtos/exchange_request_dto.dart';

abstract interface class ExchangeRequestReadDataSource {
  Stream<List<ExchangeRequestDto>> watchByOrder({
    required String organizationId,
    required String orderId,
  });

  Stream<List<ExchangeRequestDto>> watchQueue({
    required String organizationId,
    required String companyId,
    required bool allCompany,
    required Set<String> sellerIds,
  });
}
