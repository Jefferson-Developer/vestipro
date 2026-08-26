import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/storage/storage.dart';
import 'package:vestipro/features/catalog/catalog.dart';

import '../../catalog_test_fakes.dart';

class _MockStorageDataSource extends Mock implements StorageDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  group('CampaignFormBloc', () {
    late _MockStorageDataSource storage;
    late InMemoryCatalogCampaignRepository campaignRepository;
    late InMemoryCatalogProductRepository productRepository;

    setUp(() {
      storage = _MockStorageDataSource();
      campaignRepository = InMemoryCatalogCampaignRepository();
      productRepository = InMemoryCatalogProductRepository();

      when(
        () => storage.uploadFile(
          path: any(named: 'path'),
          bytes: any(named: 'bytes'),
          contentType: any(named: 'contentType'),
          onProgress: any(named: 'onProgress'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((invocation) async {
        final path = invocation.namedArguments[#path] as String;
        return 'https://storage.test/$path';
      });
      when(
        () => storage.deleteFile(path: any(named: 'path')),
      ).thenAnswer((_) async {});
    });

    CampaignFormBloc buildBloc() {
      return CampaignFormBloc(
        storage: storage,
        createCampaign: CreateCampaignUseCase(campaignRepository),
        updateCampaign: UpdateCampaignUseCase(campaignRepository),
        listRelatedProducts: ListCampaignRelatedProductsUseCase(
          productRepository,
        ),
      );
    }

    test(
      'starting a new campaign defaults to active with a generated id',
      () async {
        final bloc = buildBloc()
          ..add(
            const CampaignFormStarted(
              organizationId: 'org-1',
              userId: 'user-1',
            ),
          );
        await _drainBloc();

        expect(bloc.state.loadStatus, CampaignFormLoadStatus.ready);
        expect(bloc.state.isEditing, isFalse);
        expect(bloc.state.active, isTrue);
        expect(bloc.state.campaignId, isNotEmpty);
        await bloc.close();
      },
    );

    test('starting to edit hydrates fields and related products', () async {
      productRepository.products.add(
        buildTestCatalogHomeProduct(id: 'product-1'),
      );
      final initial = buildTestCampaign(
        id: 'campaign-1',
      ).copyWith(relatedProductIds: <String>['product-1']);

      final bloc = buildBloc()
        ..add(
          CampaignFormStarted(
            organizationId: 'org-1',
            userId: 'user-1',
            initialCampaign: initial,
          ),
        );
      await _drainBloc();

      expect(bloc.state.loadStatus, CampaignFormLoadStatus.ready);
      expect(bloc.state.isEditing, isTrue);
      expect(bloc.state.campaignId, 'campaign-1');
      expect(bloc.state.relatedProducts.single.id, 'product-1');
      await bloc.close();
    });

    test(
      'picking a cover image uploads it and replaces the previous one',
      () async {
        final bloc = buildBloc()
          ..add(
            const CampaignFormStarted(
              organizationId: 'org-1',
              userId: 'user-1',
            ),
          );
        await _drainBloc();

        bloc.add(
          CampaignFormCoverImagePicked(Uint8List.fromList(<int>[1, 2, 3])),
        );
        await _drainBloc();
        final firstUrl = bloc.state.coverImageUrl;
        expect(firstUrl, isNotNull);
        expect(bloc.state.isUploadingCover, isFalse);

        bloc.add(
          CampaignFormCoverImagePicked(Uint8List.fromList(<int>[4, 5, 6])),
        );
        await _drainBloc();

        expect(bloc.state.coverImageUrl, isNot(firstUrl));
        verify(() => storage.deleteFile(path: firstUrl!)).called(1);
        await bloc.close();
      },
    );

    test('removing the cover image clears it and deletes the file', () async {
      final bloc = buildBloc()
        ..add(
          const CampaignFormStarted(organizationId: 'org-1', userId: 'user-1'),
        );
      await _drainBloc();
      bloc.add(
        CampaignFormCoverImagePicked(Uint8List.fromList(<int>[1, 2, 3])),
      );
      await _drainBloc();
      final url = bloc.state.coverImageUrl!;

      bloc.add(const CampaignFormCoverImageRemoved());
      await _drainBloc();

      expect(bloc.state.coverImageUrl, isNull);
      verify(() => storage.deleteFile(path: url)).called(1);
      await bloc.close();
    });

    test('adding editorial images appends them in order and reorder/remove '
        'work', () async {
      final bloc = buildBloc()
        ..add(
          const CampaignFormStarted(organizationId: 'org-1', userId: 'user-1'),
        );
      await _drainBloc();

      bloc.add(CampaignFormEditorialImagePicked(Uint8List.fromList(<int>[1])));
      await _drainBloc();
      bloc.add(CampaignFormEditorialImagePicked(Uint8List.fromList(<int>[2])));
      await _drainBloc();

      expect(bloc.state.editorialImageUrls, hasLength(2));

      final reversed = bloc.state.editorialImageUrls.reversed.toList();
      bloc.add(CampaignFormEditorialImagesReordered(reversed));
      await _drainBloc();
      expect(bloc.state.editorialImageUrls, reversed);

      final removedUrl = bloc.state.editorialImageUrls.first;
      bloc.add(CampaignFormEditorialImageRemoved(removedUrl));
      await _drainBloc();

      expect(bloc.state.editorialImageUrls, isNot(contains(removedUrl)));
      verify(() => storage.deleteFile(path: removedUrl)).called(1);
      await bloc.close();
    });

    test('adding and removing a related product', () async {
      final bloc = buildBloc()
        ..add(
          const CampaignFormStarted(organizationId: 'org-1', userId: 'user-1'),
        );
      await _drainBloc();

      final product = buildTestCatalogHomeProduct(id: 'product-1');
      bloc.add(CampaignFormRelatedProductAdded(product));
      await _drainBloc();
      expect(bloc.state.relatedProducts, hasLength(1));

      // Adding the same product twice never duplicates it.
      bloc.add(CampaignFormRelatedProductAdded(product));
      await _drainBloc();
      expect(bloc.state.relatedProducts, hasLength(1));

      bloc.add(const CampaignFormRelatedProductRemoved('product-1'));
      await _drainBloc();
      expect(bloc.state.relatedProducts, isEmpty);
      await bloc.close();
    });

    test('submitting a new campaign creates it and reports success', () async {
      final bloc = buildBloc()
        ..add(
          const CampaignFormStarted(organizationId: 'org-1', userId: 'user-1'),
        );
      await _drainBloc();

      bloc.add(const CampaignFormTitleChanged('Verão em Movimento'));
      await _drainBloc();
      bloc.add(const CampaignFormSubmitted());
      await _drainBloc();

      expect(bloc.state.submissionStatus, CampaignFormSubmissionStatus.success);
      expect(bloc.state.savedCampaign, isNotNull);
      expect(campaignRepository.campaigns[bloc.state.campaignId], isNotNull);
      await bloc.close();
    });

    test(
      'submitting with a blank title fails validation without saving',
      () async {
        final bloc = buildBloc()
          ..add(
            const CampaignFormStarted(
              organizationId: 'org-1',
              userId: 'user-1',
            ),
          );
        await _drainBloc();

        bloc.add(const CampaignFormSubmitted());
        await _drainBloc();

        expect(
          bloc.state.submissionStatus,
          CampaignFormSubmissionStatus.failure,
        );
        expect(bloc.state.fieldErrors, containsPair('title', isNotEmpty));
        expect(campaignRepository.campaigns, isEmpty);
        await bloc.close();
      },
    );

    test('submitting an edit updates the existing campaign', () async {
      final initial = buildTestCampaign(id: 'campaign-1');
      campaignRepository.seed(initial);

      final bloc = buildBloc()
        ..add(
          CampaignFormStarted(
            organizationId: 'org-1',
            userId: 'user-1',
            initialCampaign: initial,
          ),
        );
      await _drainBloc();

      bloc.add(const CampaignFormTitleChanged('Título atualizado'));
      await _drainBloc();
      bloc.add(const CampaignFormSubmitted());
      await _drainBloc();

      expect(bloc.state.submissionStatus, CampaignFormSubmissionStatus.success);
      expect(
        campaignRepository.campaigns['campaign-1']?.title,
        'Título atualizado',
      );
      await bloc.close();
    });
  });
}

Future<void> _drainBloc() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
