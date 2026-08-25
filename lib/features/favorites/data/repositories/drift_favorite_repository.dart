import 'dart:async' show unawaited;

import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/favorite_product.dart';
import '../../domain/entities/favorite_product_page.dart';
import '../../domain/repositories/favorite_repository.dart';
import '../../domain/value_objects/favorite_sync_status.dart';
import '../datasources/favorite_remote_data_source.dart';
import '../mappers/favorite_local_mapper.dart';

/// Local-first [FavoriteRepository] (TASK-079): every method reads/writes
/// [AppDatabase]'s [FavoritesTable] first and returns without waiting on
/// Firestore, then kicks off a best-effort background push via
/// [FavoriteRemoteDataSource] — a failed/slow/offline remote call never
/// fails the favorite/unfavorite action itself, it only leaves the row
/// `syncStatus: pending` for [_drainPendingSync] to retry next time this
/// repository is used, which is this feature's stand-in for the generic
/// Outbox engine that does not exist yet (EPIC-14).
@LazySingleton(as: FavoriteRepository)
final class DriftFavoriteRepository implements FavoriteRepository {
  DriftFavoriteRepository(this._database, this._mapper, this._remote);

  final AppDatabase _database;
  final FavoriteLocalMapper _mapper;
  final FavoriteRemoteDataSource _remote;

  @override
  Stream<Set<String>> watchFavoriteProductIds({
    required String organizationId,
    required String userId,
  }) {
    unawaited(
      _drainPendingSync(organizationId: organizationId, userId: userId),
    );
    return _database.watchFavoriteProductIds(
      organizationId: organizationId,
      userId: userId,
    );
  }

  @override
  Future<AppResult<FavoriteProduct>> addFavorite({
    required String organizationId,
    required String userId,
    required String productId,
    String? companyId,
  }) async {
    try {
      final favorite = FavoriteProduct(
        productId: productId,
        userId: userId,
        organizationId: organizationId,
        companyId: companyId,
        createdAt: DateTime.now().toUtc(),
        syncStatus: FavoriteSyncStatus.pending,
      );
      // `insertOnConflictUpdate` on the primary key
      // (organizationId, userId, productId) is what makes repeated taps
      // idempotent: a product already favorited is simply written again
      // (clearing any pending-deletion tombstone), never duplicated.
      await _database.upsertFavorite(_mapper.toRow(favorite));
      unawaited(_syncUpsert(favorite));
      return AppSuccess<FavoriteProduct>(favorite);
    } catch (exception) {
      return AppFailure<FavoriteProduct>(
        UnexpectedFailure(
          'Unexpected error favoriting product.',
          code: 'favorite_add_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> removeFavorite({
    required String organizationId,
    required String userId,
    required String productId,
  }) async {
    try {
      final deletedAt = DateTime.now().toUtc();
      await _database.softDeleteFavorite(
        organizationId: organizationId,
        userId: userId,
        productId: productId,
        deletedAt: deletedAt,
      );
      unawaited(
        _syncDelete(
          organizationId: organizationId,
          userId: userId,
          productId: productId,
        ),
      );
      return const AppSuccess<void>(null);
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error unfavoriting product.',
          code: 'favorite_remove_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<FavoriteProductPage>> listFavorites({
    required String organizationId,
    required String userId,
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final rows = await _database.listFavorites(
        organizationId: organizationId,
        userId: userId,
        offset: offset,
        limit: limit,
      );
      final hasMore = rows.length > limit;
      final page = hasMore ? rows.take(limit).toList(growable: false) : rows;
      return AppSuccess<FavoriteProductPage>(
        FavoriteProductPage(
          items: page.map(_mapper.fromRow).toList(growable: false),
          hasMore: hasMore,
        ),
      );
    } catch (exception) {
      return AppFailure<FavoriteProductPage>(
        UnexpectedFailure(
          'Unexpected error listing favorite products.',
          code: 'favorite_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  /// Pushes every locally pending favorite mutation (add or tombstoned
  /// remove) to Firestore — called opportunistically whenever this
  /// repository is first watched in a given scope, so a device that
  /// favorited/unfavorited products while offline quietly catches up the
  /// next time the app is used, without a dedicated connectivity listener.
  Future<void> _drainPendingSync({
    required String organizationId,
    required String userId,
  }) async {
    final List<FavoritesTableData> pending;
    try {
      pending = await _database.listPendingFavoriteSync(
        organizationId: organizationId,
        userId: userId,
      );
    } catch (_) {
      return;
    }

    for (final row in pending) {
      if (row.deletedAt != null) {
        await _syncDelete(
          organizationId: row.organizationId,
          userId: row.userId,
          productId: row.productId,
        );
      } else {
        await _syncUpsert(_mapper.fromRow(row));
      }
    }
  }

  Future<void> _syncUpsert(FavoriteProduct favorite) async {
    try {
      await _remote.upsert(favorite);
      await _database.updateFavoriteSyncStatus(
        organizationId: favorite.organizationId,
        userId: favorite.userId,
        productId: favorite.productId,
        syncStatus: FavoriteSyncStatus.synced.name,
      );
    } catch (_) {
      // Offline/remote failure: the local row stays exactly as it is
      // (`pending`), never lost — the next `_drainPendingSync` call retries
      // it. No Crashlytics/error surface here on purpose, the same way
      // every other local-store-until-outbox-exists repository in this
      // codebase treats a background sync failure as expected, not
      // exceptional.
      await _markFailedIfStillPending(favorite);
    }
  }

  Future<void> _syncDelete({
    required String organizationId,
    required String userId,
    required String productId,
  }) async {
    try {
      await _remote.delete(
        organizationId: organizationId,
        userId: userId,
        productId: productId,
      );
      // The remote deletion is confirmed — the local tombstone has served
      // its purpose and can be removed for good.
      await _database.deleteFavoriteRow(
        organizationId: organizationId,
        userId: userId,
        productId: productId,
      );
    } catch (_) {
      await _database.updateFavoriteSyncStatus(
        organizationId: organizationId,
        userId: userId,
        productId: productId,
        syncStatus: FavoriteSyncStatus.failed.name,
      );
    }
  }

  Future<void> _markFailedIfStillPending(FavoriteProduct favorite) {
    return _database.updateFavoriteSyncStatus(
      organizationId: favorite.organizationId,
      userId: favorite.userId,
      productId: favorite.productId,
      syncStatus: FavoriteSyncStatus.failed.name,
    );
  }
}
