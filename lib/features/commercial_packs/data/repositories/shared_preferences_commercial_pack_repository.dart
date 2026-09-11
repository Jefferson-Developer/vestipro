import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/assortment_rule.dart';
import '../../domain/entities/commercial_pack.dart';
import '../../domain/entities/pack_component.dart';
import '../../domain/repositories/commercial_pack_repository.dart';
import '../dtos/assortment_rule_dto.dart';
import '../dtos/commercial_pack_dto.dart';
import '../dtos/pack_component_dto.dart';
import '../mappers/commercial_pack_mapper.dart';

/// Durable local `CommercialPack` store used until the real remote/outbox
/// sync implementation exists (TASK-207, EPIC-32) — same precedent as
/// `SharedPreferencesPriceListRepository` (TASK-083): this feature does not
/// get a `FirestoreCommercialPackRepository` implementation either, for the
/// exact same reason documented there (Security Rules are validated
/// directly via JS/emulador, independent of any Dart repository
/// implementation).
///
/// Enum<->string codes are shared with the remote-facing
/// [CommercialPackMapper] so they stay identical once a Firestore-backed
/// implementation exists; dates are kept as plain ISO-8601 strings rather
/// than the Firestore `Timestamp` shape [CommercialPackDto] uses, since this
/// store has nothing to do with `cloud_firestore`.
@LazySingleton(as: CommercialPackRepository)
final class SharedPreferencesCommercialPackRepository
    implements CommercialPackRepository {
  const SharedPreferencesCommercialPackRepository(this._mapper);

  final CommercialPackMapper _mapper;

  String _keyFor(String organizationId) => 'commercial_packs_$organizationId';

  @override
  Future<AppResult<CommercialPack>> create({
    required CommercialPack pack,
  }) async {
    try {
      final existing = await _load(pack.organizationId);
      if (existing.any((item) => item.id == pack.id)) {
        return const AppFailure<CommercialPack>(
          ConflictFailure(
            'Commercial pack already exists.',
            code: 'commercial_pack_already_exists',
          ),
        );
      }
      final next = <CommercialPack>[...existing, pack];
      await _save(pack.organizationId, next);
      return AppSuccess<CommercialPack>(pack);
    } catch (exception) {
      return AppFailure<CommercialPack>(
        UnexpectedFailure(
          'Unexpected error creating commercial pack locally.',
          code: 'commercial_pack_local_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<CommercialPack>> update({
    required CommercialPack pack,
  }) async {
    try {
      final existing = await _load(pack.organizationId);
      final current = existing.where((item) => item.id == pack.id);
      if (current.isEmpty) {
        return const AppFailure<CommercialPack>(
          NotFoundFailure(
            'Commercial pack not found.',
            code: 'commercial_pack_not_found',
          ),
        );
      }
      if (current.first.packCode != pack.packCode) {
        return const AppFailure<CommercialPack>(
          ValidationFailure(
            'Commercial pack packCode is immutable once created.',
            code: 'commercial_pack_pack_code_immutable',
          ),
        );
      }
      final next = <CommercialPack>[
        ...existing.where((item) => item.id != pack.id),
        pack,
      ];
      await _save(pack.organizationId, next);
      return AppSuccess<CommercialPack>(pack);
    } catch (exception) {
      return AppFailure<CommercialPack>(
        UnexpectedFailure(
          'Unexpected error updating commercial pack locally.',
          code: 'commercial_pack_local_update_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<CommercialPack?>> getById({
    required String organizationId,
    required String id,
  }) async {
    try {
      final existing = await _load(organizationId);
      for (final pack in existing) {
        if (pack.id == id && pack.deletedAt == null) {
          return AppSuccess<CommercialPack?>(pack);
        }
      }
      return const AppSuccess<CommercialPack?>(null);
    } catch (exception) {
      return AppFailure<CommercialPack?>(
        UnexpectedFailure(
          'Unexpected error loading commercial pack locally.',
          code: 'commercial_pack_local_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<CommercialPack>>> listByOrganization({
    required String organizationId,
    String? companyId,
  }) async {
    try {
      final existing = await _load(organizationId);
      return AppSuccess<List<CommercialPack>>(
        existing
            .where(
              (pack) =>
                  pack.deletedAt == null &&
                  (companyId == null ||
                      pack.companyId == null ||
                      pack.companyId == companyId),
            )
            .toList(growable: false),
      );
    } catch (exception) {
      return AppFailure<List<CommercialPack>>(
        UnexpectedFailure(
          'Unexpected error listing commercial packs locally.',
          code: 'commercial_pack_local_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  Future<List<CommercialPack>> _load(String organizationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(organizationId));
    if (raw == null || raw.isEmpty) return const <CommercialPack>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) return const <CommercialPack>[];
    return decoded
        .map((item) => _fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> _save(String organizationId, List<CommercialPack> packs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(organizationId),
      jsonEncode(packs.map(_toJson).toList(growable: false)),
    );
  }

  /// Plain (non-Firestore) JSON encoding for local persistence — unlike
  /// [CommercialPackDto] (which shapes dates as `cloud_firestore` `Timestamp`
  /// for the eventual remote store), dates here are ISO-8601 strings, same
  /// precedent `SharedPreferencesPriceListRepository._toJson`/`_fromJson`
  /// already follows. Nested `components`/`assortmentRules` reuse
  /// [CommercialPackMapper]'s own `componentToDto`/`assortmentRuleToDto`
  /// (and their DTOs' `toJson`) since those two shapes have nothing
  /// Firestore-specific about them.
  Map<String, dynamic> _toJson(CommercialPack pack) {
    return <String, dynamic>{
      'id': pack.id,
      'organizationId': pack.organizationId,
      'companyId': pack.companyId,
      'packCode': pack.packCode,
      'version': pack.version,
      'name': pack.name,
      'description': pack.description,
      'packType': _mapper.packTypeToDto(pack.packType),
      'status': _mapper.statusToDto(pack.status),
      'pricingPolicyType': _mapper.pricingPolicyTypeToDto(
        pack.pricingPolicyType,
      ),
      'fixedPrice': pack.fixedPrice,
      'discountPercentage': pack.discountPercentage,
      'bonusComponentId': pack.bonusComponentId,
      'stockPolicyType': _mapper.stockPolicyTypeToDto(pack.stockPolicyType),
      'dedicatedWarehouseId': pack.dedicatedWarehouseId,
      'collectionId': pack.collectionId,
      'campaignId': pack.campaignId,
      'customerSegment': pack.customerSegment,
      'channel': pack.channel,
      'validFrom': pack.validFrom.toIso8601String(),
      'validTo': pack.validTo?.toIso8601String(),
      'components': pack.components
          .map((component) => _mapper.componentToDto(component).toJson())
          .toList(growable: false),
      'assortmentRules': pack.assortmentRules
          .map((rule) => _mapper.assortmentRuleToDto(rule).toJson())
          .toList(growable: false),
      'createdAt': pack.createdAt.toIso8601String(),
      'createdBy': pack.createdBy,
      'updatedAt': pack.updatedAt.toIso8601String(),
      'updatedBy': pack.updatedBy,
      'deletedAt': pack.deletedAt?.toIso8601String(),
      'supersededByPackId': pack.supersededByPackId,
      'syncStatus': _mapper.syncStatusToDto(pack.syncStatus),
    };
  }

  CommercialPack _fromJson(Map<String, dynamic> json) {
    return CommercialPack(
      id: json['id'] as String,
      organizationId: json['organizationId'] as String,
      companyId: json['companyId'] as String?,
      packCode: json['packCode'] as String,
      version: json['version'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      packType: _mapper.packTypeToEntity(json['packType'] as String),
      status: _mapper.statusToEntity(json['status'] as String),
      pricingPolicyType: _mapper.pricingPolicyTypeToEntity(
        json['pricingPolicyType'] as String,
      ),
      fixedPrice: (json['fixedPrice'] as num?)?.toDouble(),
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble(),
      bonusComponentId: json['bonusComponentId'] as String?,
      stockPolicyType: _mapper.stockPolicyTypeToEntity(
        json['stockPolicyType'] as String,
      ),
      dedicatedWarehouseId: json['dedicatedWarehouseId'] as String?,
      collectionId: json['collectionId'] as String?,
      campaignId: json['campaignId'] as String?,
      customerSegment: json['customerSegment'] as String?,
      channel: json['channel'] as String?,
      validFrom: DateTime.parse(json['validFrom'] as String),
      validTo: (json['validTo'] as String?) == null
          ? null
          : DateTime.parse(json['validTo'] as String),
      components: _decodeComponents(json['components']),
      assortmentRules: _decodeAssortmentRules(json['assortmentRules']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      updatedBy: json['updatedBy'] as String,
      deletedAt: (json['deletedAt'] as String?) == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      supersededByPackId: json['supersededByPackId'] as String?,
      syncStatus: _mapper.syncStatusToEntity(json['syncStatus'] as String),
    );
  }

  List<PackComponent> _decodeComponents(Object? value) {
    if (value is! List<dynamic>) return const <PackComponent>[];
    return value
        .map(
          (item) => _mapper.componentToEntity(
            PackComponentDto.fromJson(item as Map<String, dynamic>),
          ),
        )
        .toList(growable: false);
  }

  List<AssortmentRule> _decodeAssortmentRules(Object? value) {
    if (value is! List<dynamic>) return const <AssortmentRule>[];
    return value
        .map(
          (item) => _mapper.assortmentRuleToEntity(
            AssortmentRuleDto.fromJson(item as Map<String, dynamic>),
          ),
        )
        .toList(growable: false);
  }
}
