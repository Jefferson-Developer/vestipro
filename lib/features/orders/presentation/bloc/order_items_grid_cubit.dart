import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_color.dart';
import '../../../products/domain/entities/product_variant.dart';
import '../../../products/domain/entities/size_grid_template.dart';
import '../../../products/domain/entities/variant_availability.dart';
import '../../../products/domain/entities/variant_availability_snapshot.dart';
import '../../../products/domain/usecases/get_size_grid_template_by_id_use_case.dart';
import '../../../products/domain/usecases/get_variant_availability_use_case.dart';
import '../../../products/domain/usecases/list_product_colors_use_case.dart';
import '../../../products/domain/usecases/list_product_variants_by_product_use_case.dart';
import '../../../products/domain/value_objects/product_variant_status.dart';
import 'order_items_grid_state.dart';

/// Resolves the color/size "shape" of one product already on an order draft
/// so `OrderItemsGrid` (TASK-098) can render it as an `AppSizeGrid` — the
/// exact same Design System component (TASK-073/TASK-024) `CommercialSizeGrid`
/// and `ProductDetailPage` already reuse, never a grid reimplemented for
/// orders.
///
/// Deliberately its own cubit (not `OrderDraftBloc` itself): the size/color/
/// availability of a product is read-only catalog data, unrelated to the
/// order draft's own persistence — `OrderDraftBloc` stays the single source
/// of truth for the actually-typed `OrderItem` quantities, this cubit only
/// answers "which color/size combinations exist for this product and are
/// they available", one instance per product card shown on the draft
/// screen.
@injectable
final class OrderItemsGridCubit extends Cubit<OrderItemsGridState> {
  OrderItemsGridCubit({
    required this.listVariantsByProduct,
    required this.listProductColors,
    required this.getSizeGridTemplateById,
    required this.getVariantAvailability,
  }) : super(const OrderItemsGridState());

  final ListProductVariantsByProductUseCase listVariantsByProduct;
  final ListProductColorsUseCase listProductColors;
  final GetSizeGridTemplateByIdUseCase getSizeGridTemplateById;
  final GetVariantAvailabilityUseCase getVariantAvailability;

  Future<void> load({
    required String organizationId,
    required Product product,
  }) async {
    emit(
      state.copyWith(
        loadStatus: OrderItemsGridLoadStatus.loading,
        product: product,
        clearFailure: true,
      ),
    );

    final variantsResult = await listVariantsByProduct(
      organizationId: organizationId,
      productId: product.id,
    );
    if (variantsResult is AppFailure<List<ProductVariant>>) {
      emit(
        state.copyWith(
          loadStatus: OrderItemsGridLoadStatus.failure,
          failure: variantsResult.failure,
        ),
      );
      return;
    }
    final variants = (variantsResult as AppSuccess<List<ProductVariant>>).value
        .where((variant) => variant.status == ProductVariantStatus.active)
        .toList(growable: false);

    final colorsResult = await listProductColors(organizationId);
    final colors = colorsResult is AppSuccess<List<ProductColor>>
        ? colorsResult.value
        : const <ProductColor>[];

    final templateId = product.sizeGridTemplateId;
    SizeGridTemplate? template;
    if (templateId != null && templateId.trim().isNotEmpty) {
      final templateResult = await getSizeGridTemplateById(
        organizationId: organizationId,
        id: templateId,
      );
      if (templateResult is AppSuccess<SizeGridTemplate>) {
        template = templateResult.value;
      }
    }

    final availabilityResult = await getVariantAvailability(
      organizationId: organizationId,
      variantIds: variants.map((variant) => variant.id),
    );
    final availabilityByVariantId =
        availabilityResult is AppSuccess<VariantAvailabilitySnapshot>
        ? availabilityResult.value.byVariantId
        : const <String, VariantAvailability>{};

    emit(
      state.copyWith(
        loadStatus: OrderItemsGridLoadStatus.ready,
        colors: colors,
        sizeGridTemplate: template,
        variants: variants,
        availabilityByVariantId: availabilityByVariantId,
        clearFailure: true,
      ),
    );
  }
}
