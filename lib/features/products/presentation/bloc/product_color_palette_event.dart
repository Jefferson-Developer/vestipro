import '../../domain/entities/product_color.dart';

sealed class ProductColorPaletteEvent {
  const ProductColorPaletteEvent();
}

final class ProductColorPaletteStarted extends ProductColorPaletteEvent {
  const ProductColorPaletteStarted({
    required this.organizationId,
    required this.userId,
  });

  final String organizationId;
  final String userId;
}

final class ProductColorPaletteSearchChanged extends ProductColorPaletteEvent {
  const ProductColorPaletteSearchChanged(this.query);

  final String query;
}

final class ProductColorPaletteFormChanged extends ProductColorPaletteEvent {
  const ProductColorPaletteFormChanged({
    required this.code,
    required this.name,
    required this.hex,
    required this.mainImageUrl,
    required this.additionalImageUrls,
    required this.eans,
  });

  final String code;
  final String name;
  final String hex;
  final String mainImageUrl;
  final String additionalImageUrls;
  final String eans;
}

final class ProductColorPaletteEditRequested extends ProductColorPaletteEvent {
  const ProductColorPaletteEditRequested(this.color);

  final ProductColor color;
}

final class ProductColorPaletteCreateRequested
    extends ProductColorPaletteEvent {
  const ProductColorPaletteCreateRequested();
}

final class ProductColorPaletteSubmitted extends ProductColorPaletteEvent {
  const ProductColorPaletteSubmitted({this.confirmSimilarColor = false});

  final bool confirmSimilarColor;
}

final class ProductColorPaletteUnavailableRequested
    extends ProductColorPaletteEvent {
  const ProductColorPaletteUnavailableRequested(this.color);

  final ProductColor color;
}
