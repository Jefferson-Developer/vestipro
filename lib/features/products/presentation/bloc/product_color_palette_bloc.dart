import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/product_color.dart';
import '../../domain/usecases/create_product_color_use_case.dart';
import '../../domain/usecases/list_product_colors_use_case.dart';
import '../../domain/usecases/mark_product_color_unavailable_use_case.dart';
import '../../domain/usecases/update_product_color_use_case.dart';
import 'product_color_palette_event.dart';
import 'product_color_palette_state.dart';

@injectable
final class ProductColorPaletteBloc
    extends Bloc<ProductColorPaletteEvent, ProductColorPaletteState> {
  ProductColorPaletteBloc({
    required this.listProductColors,
    required this.createProductColor,
    required this.updateProductColor,
    required this.markProductColorUnavailable,
  }) : super(const ProductColorPaletteState()) {
    on<ProductColorPaletteStarted>(_onStarted, transformer: restartable());
    on<ProductColorPaletteSearchChanged>(
      _onSearchChanged,
      transformer: sequential(),
    );
    on<ProductColorPaletteCreateRequested>(
      _onCreateRequested,
      transformer: sequential(),
    );
    on<ProductColorPaletteEditRequested>(
      _onEditRequested,
      transformer: sequential(),
    );
    on<ProductColorPaletteFormChanged>(
      _onFormChanged,
      transformer: sequential(),
    );
    on<ProductColorPaletteSubmitted>(_onSubmitted, transformer: droppable());
    on<ProductColorPaletteUnavailableRequested>(
      _onUnavailableRequested,
      transformer: sequential(),
    );
  }

  final ListProductColorsUseCase listProductColors;
  final CreateProductColorUseCase createProductColor;
  final UpdateProductColorUseCase updateProductColor;
  final MarkProductColorUnavailableUseCase markProductColorUnavailable;
  final Uuid _uuid = const Uuid();

  Future<void> _onStarted(
    ProductColorPaletteStarted event,
    Emitter<ProductColorPaletteState> emit,
  ) async {
    emit(
      state.copyWith(
        loadStatus: ProductColorPaletteLoadStatus.loading,
        organizationId: event.organizationId,
        userId: event.userId,
        clearFailure: true,
      ),
    );
    await _load(emit);
  }

  Future<void> _load(Emitter<ProductColorPaletteState> emit) async {
    final result = await listProductColors(state.organizationId);
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<List<ProductColor>>(value: final colors):
        emit(
          state.copyWith(
            loadStatus: ProductColorPaletteLoadStatus.ready,
            colors: colors,
            clearFailure: true,
          ),
        );
      case AppFailure<List<ProductColor>>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: ProductColorPaletteLoadStatus.failure,
            failure: failure,
          ),
        );
    }
  }

  void _onSearchChanged(
    ProductColorPaletteSearchChanged event,
    Emitter<ProductColorPaletteState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onCreateRequested(
    ProductColorPaletteCreateRequested event,
    Emitter<ProductColorPaletteState> emit,
  ) {
    emit(
      state.copyWith(
        saveStatus: ProductColorPaletteSaveStatus.editing,
        code: '',
        name: '',
        hex: '#000000',
        mainImageUrl: '',
        additionalImageUrls: '',
        eans: '',
        clearEditingColor: true,
        clearFieldErrors: true,
        clearSimilarColor: true,
        clearFailure: true,
      ),
    );
  }

  void _onEditRequested(
    ProductColorPaletteEditRequested event,
    Emitter<ProductColorPaletteState> emit,
  ) {
    final color = event.color;
    emit(
      state.copyWith(
        saveStatus: ProductColorPaletteSaveStatus.editing,
        editingColor: color,
        code: color.code,
        name: color.name,
        hex: color.hex.value,
        mainImageUrl: color.mainImageUrl ?? '',
        additionalImageUrls: color.additionalImageUrls.join('\n'),
        eans: color.eans.map((ean) => ean.digits).join(', '),
        clearFieldErrors: true,
        clearSimilarColor: true,
        clearFailure: true,
      ),
    );
  }

  void _onFormChanged(
    ProductColorPaletteFormChanged event,
    Emitter<ProductColorPaletteState> emit,
  ) {
    emit(
      state.copyWith(
        saveStatus: ProductColorPaletteSaveStatus.editing,
        code: event.code,
        name: event.name,
        hex: event.hex,
        mainImageUrl: event.mainImageUrl,
        additionalImageUrls: event.additionalImageUrls,
        eans: event.eans,
        clearFieldErrors: true,
        clearSimilarColor: true,
        clearFailure: true,
      ),
    );
  }

  Future<void> _onSubmitted(
    ProductColorPaletteSubmitted event,
    Emitter<ProductColorPaletteState> emit,
  ) async {
    emit(
      state.copyWith(
        saveStatus: ProductColorPaletteSaveStatus.submitting,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );

    final additionalUrls = state.additionalImageUrls
        .split(RegExp(r'[\n,]'))
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
    final eans = state.eans
        .split(RegExp(r'[\n,]'))
        .map((ean) => ean.trim())
        .where((ean) => ean.isNotEmpty)
        .toList(growable: false);

    final result = state.editingColor == null
        ? await createProductColor(
            id: _uuid.v4(),
            organizationId: state.organizationId,
            code: state.code,
            name: state.name,
            hex: state.hex,
            mainImageUrl: state.mainImageUrl,
            additionalImageUrls: additionalUrls,
            eans: eans,
            createdBy: state.userId,
            confirmedSimilarColor: event.confirmSimilarColor,
          )
        : await updateProductColor(
            organizationId: state.organizationId,
            id: state.editingColor!.id,
            code: state.code,
            name: state.name,
            hex: state.hex,
            mainImageUrl: state.mainImageUrl,
            additionalImageUrls: additionalUrls,
            eans: eans,
            status: state.editingColor!.status,
            updatedBy: state.userId,
            confirmedSimilarColor: event.confirmSimilarColor,
          );
    if (emit.isDone) return;
    await _handleMutationResult(result, emit);
  }

  Future<void> _onUnavailableRequested(
    ProductColorPaletteUnavailableRequested event,
    Emitter<ProductColorPaletteState> emit,
  ) async {
    final result = await markProductColorUnavailable(
      organizationId: state.organizationId,
      id: event.color.id,
      updatedBy: state.userId,
    );
    if (emit.isDone) return;
    await _handleMutationResult(result, emit);
  }

  Future<void> _handleMutationResult(
    AppResult<ProductColor> result,
    Emitter<ProductColorPaletteState> emit,
  ) async {
    switch (result) {
      case AppSuccess<ProductColor>():
        emit(
          state.copyWith(
            saveStatus: ProductColorPaletteSaveStatus.success,
            clearEditingColor: true,
            clearFieldErrors: true,
            clearSimilarColor: true,
            clearFailure: true,
          ),
        );
        await _load(emit);
      case AppFailure<ProductColor>(failure: final failure):
        if (failure is ConflictFailure &&
            failure.code == 'product_color_similarity_confirmation_required') {
          emit(
            state.copyWith(
              saveStatus: ProductColorPaletteSaveStatus.similarityWarning,
              similarColorId: failure.cause as String?,
              failure: failure,
            ),
          );
          return;
        }
        emit(
          state.copyWith(
            saveStatus: ProductColorPaletteSaveStatus.failure,
            failure: failure,
            fieldErrors: failure is ValidationFailure
                ? failure.fieldErrors
                : const <String, String>{},
          ),
        );
    }
  }
}
