import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../domain/entities/assortment_rule.dart';
import '../../domain/entities/commercial_pack.dart';
import '../../domain/entities/pack_component.dart';
import '../dtos/assortment_rule_dto.dart';
import '../dtos/pack_component_dto.dart';
import 'commercial_pack_mapper.dart';

/// Maps [CommercialPack] to/from the Drift rows backing its offline cache
/// (`CommercialPacksTable`, TASK-207). Enum<->string conversions delegate to
/// [CommercialPackMapper] so this local store does not reimplement the same
/// codes already used for the remote-facing DTO — same precedent
/// `PriceListLocalMapper` already follows. [components]/[assortmentRules]
/// round-trip through plain JSON text (`componentsJson`/
/// `assortmentRulesJson`), reusing the same `PackComponentDto`/
/// `AssortmentRuleDto.toJson`/`fromJson` shape the remote DTO uses.
@lazySingleton
final class CommercialPackLocalMapper {
  const CommercialPackLocalMapper(this._mapper);

  final CommercialPackMapper _mapper;

  CommercialPacksTableCompanion toRow(CommercialPack pack) {
    return CommercialPacksTableCompanion.insert(
      id: pack.id,
      organizationId: pack.organizationId,
      companyId: Value(pack.companyId),
      packCode: pack.packCode,
      version: pack.version,
      name: pack.name,
      description: Value(pack.description),
      packType: _mapper.packTypeToDto(pack.packType),
      status: _mapper.statusToDto(pack.status),
      pricingPolicyType: _mapper.pricingPolicyTypeToDto(pack.pricingPolicyType),
      fixedPrice: Value(pack.fixedPrice),
      discountPercentage: Value(pack.discountPercentage),
      bonusComponentId: Value(pack.bonusComponentId),
      stockPolicyType: _mapper.stockPolicyTypeToDto(pack.stockPolicyType),
      dedicatedWarehouseId: Value(pack.dedicatedWarehouseId),
      collectionId: Value(pack.collectionId),
      campaignId: Value(pack.campaignId),
      customerSegment: Value(pack.customerSegment),
      channel: Value(pack.channel),
      validFrom: pack.validFrom.toUtc(),
      validTo: Value(pack.validTo?.toUtc()),
      componentsJson: Value(
        jsonEncode(
          pack.components
              .map((component) => _mapper.componentToDto(component).toJson())
              .toList(growable: false),
        ),
      ),
      assortmentRulesJson: Value(
        jsonEncode(
          pack.assortmentRules
              .map((rule) => _mapper.assortmentRuleToDto(rule).toJson())
              .toList(growable: false),
        ),
      ),
      createdAt: pack.createdAt.toUtc(),
      createdBy: pack.createdBy,
      updatedAt: pack.updatedAt.toUtc(),
      updatedBy: pack.updatedBy,
      deletedAt: Value(pack.deletedAt?.toUtc()),
      supersededByPackId: Value(pack.supersededByPackId),
      syncStatus: _mapper.syncStatusToDto(pack.syncStatus),
    );
  }

  CommercialPack fromRow(CommercialPacksTableData row) {
    return CommercialPack(
      id: row.id,
      organizationId: row.organizationId,
      companyId: row.companyId,
      packCode: row.packCode,
      version: row.version,
      name: row.name,
      description: row.description,
      packType: _mapper.packTypeToEntity(row.packType),
      status: _mapper.statusToEntity(row.status),
      pricingPolicyType: _mapper.pricingPolicyTypeToEntity(
        row.pricingPolicyType,
      ),
      fixedPrice: row.fixedPrice,
      discountPercentage: row.discountPercentage,
      bonusComponentId: row.bonusComponentId,
      stockPolicyType: _mapper.stockPolicyTypeToEntity(row.stockPolicyType),
      dedicatedWarehouseId: row.dedicatedWarehouseId,
      collectionId: row.collectionId,
      campaignId: row.campaignId,
      customerSegment: row.customerSegment,
      channel: row.channel,
      validFrom: row.validFrom.toUtc(),
      validTo: row.validTo?.toUtc(),
      components: _decodeComponents(row.componentsJson),
      assortmentRules: _decodeAssortmentRules(row.assortmentRulesJson),
      createdAt: row.createdAt.toUtc(),
      createdBy: row.createdBy,
      updatedAt: row.updatedAt.toUtc(),
      updatedBy: row.updatedBy,
      deletedAt: row.deletedAt?.toUtc(),
      supersededByPackId: row.supersededByPackId,
      syncStatus: _mapper.syncStatusToEntity(row.syncStatus),
    );
  }

  List<PackComponent> _decodeComponents(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! List<dynamic>) return const <PackComponent>[];
    return decoded
        .map(
          (item) => _mapper.componentToEntity(
            PackComponentDto.fromJson(item as Map<String, dynamic>),
          ),
        )
        .toList(growable: false);
  }

  List<AssortmentRule> _decodeAssortmentRules(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! List<dynamic>) return const <AssortmentRule>[];
    return decoded
        .map(
          (item) => _mapper.assortmentRuleToEntity(
            AssortmentRuleDto.fromJson(item as Map<String, dynamic>),
          ),
        )
        .toList(growable: false);
  }
}
