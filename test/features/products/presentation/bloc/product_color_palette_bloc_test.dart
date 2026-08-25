import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_product_color_repository.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('ProductColorPaletteBloc', () {
    late SharedPreferencesProductColorRepository repository;

    ProductColorPaletteBloc buildBloc() {
      return ProductColorPaletteBloc(
        listProductColors: ListProductColorsUseCase(repository),
        createProductColor: CreateProductColorUseCase(
          repository,
          const ProductColorSimilarityService(),
        ),
        updateProductColor: UpdateProductColorUseCase(
          repository,
          const ProductColorSimilarityService(),
        ),
        markProductColorUnavailable: MarkProductColorUnavailableUseCase(
          repository,
        ),
      );
    }

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = const SharedPreferencesProductColorRepository();
    });

    blocTest<ProductColorPaletteBloc, ProductColorPaletteState>(
      'creates a color',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(
          const ProductColorPaletteStarted(
            organizationId: 'org-1',
            userId: 'user-1',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc
          ..add(const ProductColorPaletteCreateRequested())
          ..add(
            const ProductColorPaletteFormChanged(
              code: 'AZM',
              name: 'Azul Marinho',
              hex: '#102A44',
              mainImageUrl: '',
              additionalImageUrls: '',
              eans: '4006381333931',
            ),
          )
          ..add(const ProductColorPaletteSubmitted());
      },
      wait: const Duration(milliseconds: 20),
      expect: () => contains(
        isA<ProductColorPaletteState>().having(
          (state) => state.saveStatus,
          'saveStatus',
          ProductColorPaletteSaveStatus.success,
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.colors.single.name, 'Azul Marinho');
        expect(bloc.state.colors.single.eans.single.digits, '4006381333931');
      },
    );

    blocTest<ProductColorPaletteBloc, ProductColorPaletteState>(
      'edits and marks a color unavailable',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(
          const ProductColorPaletteStarted(
            organizationId: 'org-1',
            userId: 'user-1',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc
          ..add(const ProductColorPaletteCreateRequested())
          ..add(
            const ProductColorPaletteFormChanged(
              code: 'PRE',
              name: 'Preto',
              hex: '#000000',
              mainImageUrl: '',
              additionalImageUrls: '',
              eans: '',
            ),
          )
          ..add(const ProductColorPaletteSubmitted());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        final color = bloc.state.colors.single;
        bloc
          ..add(ProductColorPaletteEditRequested(color))
          ..add(
            const ProductColorPaletteFormChanged(
              code: 'PTO',
              name: 'Preto Noite',
              hex: '#010101',
              mainImageUrl: '',
              additionalImageUrls: '',
              eans: '',
            ),
          )
          ..add(const ProductColorPaletteSubmitted(confirmSimilarColor: true));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(
          ProductColorPaletteUnavailableRequested(bloc.state.colors.single),
        );
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.colors.single.code, 'PTO');
        expect(bloc.state.colors.single.status, ProductColorStatus.unavailable);
      },
    );
  });
}
