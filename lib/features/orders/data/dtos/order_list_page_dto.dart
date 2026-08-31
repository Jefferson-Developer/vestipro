import 'order_dto.dart';

final class OrderListPageDto {
  const OrderListPageDto({required this.items, required this.hasMore});

  final List<OrderDto> items;
  final bool hasMore;
}
