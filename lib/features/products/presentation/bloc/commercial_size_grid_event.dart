import '../../domain/entities/product.dart';
import '../../domain/entities/product_color.dart';
import '../../domain/entities/product_variant.dart';
import '../../domain/entities/size_grid_template.dart';

sealed class CommercialSizeGridEvent {
  const CommercialSizeGridEvent();
}

final class CommercialSizeGridStarted extends CommercialSizeGridEvent {
  const CommercialSizeGridStarted({
    required this.product,
    required this.colors,
    required this.sizeGridTemplate,
    required this.variants,
  });

  final Product product;
  final List<ProductColor> colors;
  final SizeGridTemplate sizeGridTemplate;
  final List<ProductVariant> variants;
}

final class CommercialSizeGridQuantityChanged extends CommercialSizeGridEvent {
  const CommercialSizeGridQuantityChanged({
    required this.colorId,
    required this.sizeId,
    required this.quantity,
  });

  final String colorId;
  final String sizeId;
  final int quantity;
}

final class CommercialSizeGridConnectivityChanged
    extends CommercialSizeGridEvent {
  const CommercialSizeGridConnectivityChanged(this.isOnline);

  final bool isOnline;
}
