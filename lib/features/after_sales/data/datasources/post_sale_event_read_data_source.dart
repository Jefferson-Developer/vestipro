import '../dtos/post_sale_event_dto.dart';

abstract interface class PostSaleEventReadDataSource {
  Stream<List<PostSaleEventDto>> watchByOrder({
    required String organizationId,
    required String orderId,
  });
}
