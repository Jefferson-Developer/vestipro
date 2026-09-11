import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/commercial_packs/commercial_packs.dart';

/// Shared in-memory fake for `CommercialPackRepository` — avoids redefining
/// the same repository fake in every use case test file that needs a real
/// `CreateCommercialPackUseCase`/`UpdateCommercialPackUseCase`/
/// `ReviseCommercialPackUseCase` (TASK-207), same precedent
/// `test/features/catalog/catalog_test_fakes.dart` already sets.
///
/// Mirrors [SharedPreferencesCommercialPackRepository]'s own semantics
/// closely enough for these use cases' tests: `create` rejects a duplicate
/// id, `update` rejects a `packCode` change and a missing id, and
/// `listByOrganization`'s optional `companyId` narrowing includes
/// organization-wide packs (`companyId == null`).
class FakeCommercialPackRepository implements CommercialPackRepository {
  final Map<String, CommercialPack> _packsById = <String, CommercialPack>{};

  @override
  Future<AppResult<CommercialPack>> create({
    required CommercialPack pack,
  }) async {
    if (_packsById.containsKey(pack.id)) {
      return const AppFailure<CommercialPack>(
        ConflictFailure(
          'Commercial pack already exists.',
          code: 'commercial_pack_already_exists',
        ),
      );
    }
    _packsById[pack.id] = pack;
    return AppSuccess<CommercialPack>(pack);
  }

  @override
  Future<AppResult<CommercialPack>> update({
    required CommercialPack pack,
  }) async {
    final current = _packsById[pack.id];
    if (current == null) {
      return const AppFailure<CommercialPack>(
        NotFoundFailure(
          'Commercial pack not found.',
          code: 'commercial_pack_not_found',
        ),
      );
    }
    if (current.packCode != pack.packCode) {
      return const AppFailure<CommercialPack>(
        ValidationFailure(
          'Commercial pack packCode is immutable once created.',
          code: 'commercial_pack_pack_code_immutable',
        ),
      );
    }
    _packsById[pack.id] = pack;
    return AppSuccess<CommercialPack>(pack);
  }

  @override
  Future<AppResult<CommercialPack?>> getById({
    required String organizationId,
    required String id,
  }) async {
    final pack = _packsById[id];
    if (pack == null ||
        pack.organizationId != organizationId ||
        pack.deletedAt != null) {
      return const AppSuccess<CommercialPack?>(null);
    }
    return AppSuccess<CommercialPack?>(pack);
  }

  @override
  Future<AppResult<List<CommercialPack>>> listByOrganization({
    required String organizationId,
    String? companyId,
  }) async {
    return AppSuccess<List<CommercialPack>>(
      _packsById.values
          .where(
            (pack) =>
                pack.organizationId == organizationId &&
                pack.deletedAt == null &&
                (companyId == null ||
                    pack.companyId == null ||
                    pack.companyId == companyId),
          )
          .toList(growable: false),
    );
  }

  /// Test-only helper to seed a pack directly, bypassing [create]'s
  /// duplicate-id guard — used to arrange the "current version already
  /// exists" precondition several tests need.
  void seed(CommercialPack pack) {
    _packsById[pack.id] = pack;
  }
}
