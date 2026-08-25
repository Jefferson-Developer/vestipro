import '../../../../core/errors/errors.dart';
import '../../domain/entities/product_color.dart';

enum ProductColorPaletteLoadStatus { loading, ready, failure }

enum ProductColorPaletteSaveStatus {
  idle,
  editing,
  submitting,
  similarityWarning,
  success,
  failure,
}

final class ProductColorPaletteState {
  const ProductColorPaletteState({
    this.loadStatus = ProductColorPaletteLoadStatus.loading,
    this.saveStatus = ProductColorPaletteSaveStatus.idle,
    this.organizationId = '',
    this.userId = '',
    this.colors = const <ProductColor>[],
    this.searchQuery = '',
    this.editingColor,
    this.code = '',
    this.name = '',
    this.hex = '#000000',
    this.mainImageUrl = '',
    this.additionalImageUrls = '',
    this.eans = '',
    this.fieldErrors = const <String, String>{},
    this.similarColorId,
    this.failure,
  });

  final ProductColorPaletteLoadStatus loadStatus;
  final ProductColorPaletteSaveStatus saveStatus;
  final String organizationId;
  final String userId;
  final List<ProductColor> colors;
  final String searchQuery;
  final ProductColor? editingColor;
  final String code;
  final String name;
  final String hex;
  final String mainImageUrl;
  final String additionalImageUrls;
  final String eans;
  final Map<String, String> fieldErrors;
  final String? similarColorId;
  final Failure? failure;

  bool get isEditing => editingColor != null;
  bool get isBusy => saveStatus == ProductColorPaletteSaveStatus.submitting;

  ProductColor? get similarColor {
    final id = similarColorId;
    if (id == null) return null;
    for (final color in colors) {
      if (color.id == id) return color;
    }
    return null;
  }

  List<ProductColor> get filteredColors {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return colors;
    return colors
        .where(
          (color) =>
              color.name.toLowerCase().contains(query) ||
              color.code.toLowerCase().contains(query) ||
              color.hex.value.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  ProductColorPaletteState copyWith({
    ProductColorPaletteLoadStatus? loadStatus,
    ProductColorPaletteSaveStatus? saveStatus,
    String? organizationId,
    String? userId,
    List<ProductColor>? colors,
    String? searchQuery,
    ProductColor? editingColor,
    String? code,
    String? name,
    String? hex,
    String? mainImageUrl,
    String? additionalImageUrls,
    String? eans,
    Map<String, String>? fieldErrors,
    String? similarColorId,
    Failure? failure,
    bool clearEditingColor = false,
    bool clearSimilarColor = false,
    bool clearFieldErrors = false,
    bool clearFailure = false,
  }) {
    return ProductColorPaletteState(
      loadStatus: loadStatus ?? this.loadStatus,
      saveStatus: saveStatus ?? this.saveStatus,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      colors: colors ?? this.colors,
      searchQuery: searchQuery ?? this.searchQuery,
      editingColor: clearEditingColor
          ? null
          : editingColor ?? this.editingColor,
      code: code ?? this.code,
      name: name ?? this.name,
      hex: hex ?? this.hex,
      mainImageUrl: mainImageUrl ?? this.mainImageUrl,
      additionalImageUrls: additionalImageUrls ?? this.additionalImageUrls,
      eans: eans ?? this.eans,
      fieldErrors: clearFieldErrors
          ? const <String, String>{}
          : fieldErrors ?? this.fieldErrors,
      similarColorId: clearSimilarColor
          ? null
          : similarColorId ?? this.similarColorId,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}
