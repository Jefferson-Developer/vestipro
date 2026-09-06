import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/favorites/favorites.dart';

class _InMemoryFavoriteRepository implements FavoriteRepository {
  // Closed by the test's tearDown, not by this class — the analyzer cannot
  // see across that boundary.
  // ignore: close_sinks
  final _controller = StreamController<Set<String>>.broadcast();
  String? lastOrganizationId;
  String? lastUserId;

  @override
  Stream<Set<String>> watchFavoriteProductIds({
    required String organizationId,
    required String userId,
  }) {
    lastOrganizationId = organizationId;
    lastUserId = userId;
    return _controller.stream;
  }

  @override
  Future<AppResult<FavoriteProduct>> addFavorite({
    required String organizationId,
    required String userId,
    required String productId,
    String? companyId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<void>> removeFavorite({
    required String organizationId,
    required String userId,
    required String productId,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<FavoriteProductPage>> listFavorites({
    required String organizationId,
    required String userId,
    int offset = 0,
    int limit = 20,
  }) => throw UnimplementedError();
}

void main() {
  group('WatchFavoriteProductIdsUseCase', () {
    late _InMemoryFavoriteRepository repository;
    late WatchFavoriteProductIdsUseCase useCase;

    setUp(() {
      repository = _InMemoryFavoriteRepository();
      useCase = WatchFavoriteProductIdsUseCase(repository);
    });

    tearDown(() async {
      await repository._controller.close();
    });

    test('forwards organizationId/userId to the repository', () {
      useCase.call(organizationId: 'org-1', userId: 'user-1');

      expect(repository.lastOrganizationId, 'org-1');
      expect(repository.lastUserId, 'user-1');
    });

    test('re-emits every set the repository stream produces', () async {
      final stream = useCase.call(organizationId: 'org-1', userId: 'user-1');
      final emissions = <Set<String>>[];
      final subscription = stream.listen(emissions.add);

      repository._controller.add(<String>{'product-1'});
      repository._controller.add(<String>{'product-1', 'product-2'});
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(emissions, <Set<String>>[
        {'product-1'},
        {'product-1', 'product-2'},
      ]);
    });
  });
}
