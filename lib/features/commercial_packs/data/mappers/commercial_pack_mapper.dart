import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/entities/assortment_rule.dart';
import '../../domain/entities/commercial_pack.dart';
import '../../domain/entities/pack_component.dart';
import '../../domain/value_objects/assortment_rule_type.dart';
import '../../domain/value_objects/commercial_pack_pricing_policy_type.dart';
import '../../domain/value_objects/commercial_pack_status.dart';
import '../../domain/value_objects/commercial_pack_stock_policy_type.dart';
import '../../domain/value_objects/commercial_pack_sync_status.dart';
import '../../domain/value_objects/commercial_pack_type.dart';
import '../../domain/value_objects/pack_component_composition_type.dart';
import '../../domain/value_objects/pack_component_scope_type.dart';
import '../dtos/assortment_rule_dto.dart';
import '../dtos/commercial_pack_dto.dart';
import '../dtos/pack_component_dto.dart';

/// Maps [CommercialPack] to/from [CommercialPackDto] (TASK-207, EPIC-32),
/// the only place enum<->string codes for every enum field of
/// `CommercialPack`/`PackComponent`/`AssortmentRule` are decided, so no
/// other layer reimplements them — same precedent [PriceListMapper]/
/// [OrderMapper] already follow (the latter also handling its own nested
/// item mapper methods on the same class, rather than a separate mapper
/// type per nested value).
@lazySingleton
final class CommercialPackMapper {
  const CommercialPackMapper();

  CommercialPackDto toDto(CommercialPack pack) {
    return CommercialPackDto(
      id: pack.id,
      organizationId: pack.organizationId,
      companyId: pack.companyId,
      packCode: pack.packCode,
      version: pack.version,
      name: pack.name,
      description: pack.description,
      packType: packTypeToDto(pack.packType),
      status: statusToDto(pack.status),
      pricingPolicyType: pricingPolicyTypeToDto(pack.pricingPolicyType),
      fixedPrice: pack.fixedPrice,
      discountPercentage: pack.discountPercentage,
      bonusComponentId: pack.bonusComponentId,
      stockPolicyType: stockPolicyTypeToDto(pack.stockPolicyType),
      dedicatedWarehouseId: pack.dedicatedWarehouseId,
      collectionId: pack.collectionId,
      campaignId: pack.campaignId,
      customerSegment: pack.customerSegment,
      channel: pack.channel,
      validFrom: pack.validFrom,
      validTo: pack.validTo,
      components: pack.components.map(componentToDto).toList(growable: false),
      assortmentRules: pack.assortmentRules
          .map(assortmentRuleToDto)
          .toList(growable: false),
      createdAt: pack.createdAt,
      createdBy: pack.createdBy,
      updatedAt: pack.updatedAt,
      updatedBy: pack.updatedBy,
      deletedAt: pack.deletedAt,
      supersededByPackId: pack.supersededByPackId,
      syncStatus: syncStatusToDto(pack.syncStatus),
    );
  }

  CommercialPack toEntity(CommercialPackDto dto) {
    return CommercialPack(
      id: dto.id,
      organizationId: dto.organizationId,
      companyId: dto.companyId,
      packCode: dto.packCode,
      version: dto.version,
      name: dto.name,
      description: dto.description,
      packType: packTypeToEntity(dto.packType),
      status: statusToEntity(dto.status),
      pricingPolicyType: pricingPolicyTypeToEntity(dto.pricingPolicyType),
      fixedPrice: dto.fixedPrice,
      discountPercentage: dto.discountPercentage,
      bonusComponentId: dto.bonusComponentId,
      stockPolicyType: stockPolicyTypeToEntity(dto.stockPolicyType),
      dedicatedWarehouseId: dto.dedicatedWarehouseId,
      collectionId: dto.collectionId,
      campaignId: dto.campaignId,
      customerSegment: dto.customerSegment,
      channel: dto.channel,
      validFrom: dto.validFrom,
      validTo: dto.validTo,
      components: dto.components.map(componentToEntity).toList(growable: false),
      assortmentRules: dto.assortmentRules
          .map(assortmentRuleToEntity)
          .toList(growable: false),
      createdAt: dto.createdAt,
      createdBy: dto.createdBy,
      updatedAt: dto.updatedAt,
      updatedBy: dto.updatedBy,
      deletedAt: dto.deletedAt,
      supersededByPackId: dto.supersededByPackId,
      syncStatus: syncStatusToEntity(dto.syncStatus),
    );
  }

  PackComponentDto componentToDto(PackComponent component) {
    return PackComponentDto(
      id: component.id,
      scopeType: scopeTypeToDto(component.scopeType),
      scopeReferenceId: component.scopeReferenceId,
      compositionType: compositionTypeToDto(component.compositionType),
      quantity: component.quantity,
      minQuantity: component.minQuantity,
      maxQuantity: component.maxQuantity,
      proportion: component.proportion,
      isBonusItem: component.isBonusItem,
    );
  }

  PackComponent componentToEntity(PackComponentDto dto) {
    return PackComponent(
      id: dto.id,
      scopeType: scopeTypeToEntity(dto.scopeType),
      scopeReferenceId: dto.scopeReferenceId,
      compositionType: compositionTypeToEntity(dto.compositionType),
      quantity: dto.quantity,
      minQuantity: dto.minQuantity,
      maxQuantity: dto.maxQuantity,
      proportion: dto.proportion,
      isBonusItem: dto.isBonusItem,
    );
  }

  AssortmentRuleDto assortmentRuleToDto(AssortmentRule rule) {
    return AssortmentRuleDto(
      id: rule.id,
      type: assortmentRuleTypeToDto(rule.type),
      colorId: rule.colorId,
      sizeId: rule.sizeId,
      minPercentage: rule.minPercentage,
      minQuantity: rule.minQuantity,
    );
  }

  AssortmentRule assortmentRuleToEntity(AssortmentRuleDto dto) {
    return AssortmentRule(
      id: dto.id,
      type: assortmentRuleTypeToEntity(dto.type),
      colorId: dto.colorId,
      sizeId: dto.sizeId,
      minPercentage: dto.minPercentage,
      minQuantity: dto.minQuantity,
    );
  }

  String packTypeToDto(CommercialPackType type) {
    return switch (type) {
      CommercialPackType.kit => 'kit',
      CommercialPackType.pack => 'pack',
      CommercialPackType.assortment => 'assortment',
    };
  }

  CommercialPackType packTypeToEntity(String raw) {
    return switch (raw) {
      'kit' => CommercialPackType.kit,
      'pack' => CommercialPackType.pack,
      'assortment' => CommercialPackType.assortment,
      _ => throw ValidationException(
        'Invalid commercial pack type "$raw".',
        code: 'invalid_commercial_pack_type',
      ),
    };
  }

  String statusToDto(CommercialPackStatus status) {
    return switch (status) {
      CommercialPackStatus.draft => 'draft',
      CommercialPackStatus.active => 'active',
      CommercialPackStatus.expired => 'expired',
      CommercialPackStatus.archived => 'archived',
      CommercialPackStatus.superseded => 'superseded',
    };
  }

  CommercialPackStatus statusToEntity(String raw) {
    return switch (raw) {
      'draft' => CommercialPackStatus.draft,
      'active' => CommercialPackStatus.active,
      'expired' => CommercialPackStatus.expired,
      'archived' => CommercialPackStatus.archived,
      'superseded' => CommercialPackStatus.superseded,
      _ => throw ValidationException(
        'Invalid commercial pack status "$raw".',
        code: 'invalid_commercial_pack_status',
      ),
    };
  }

  String pricingPolicyTypeToDto(CommercialPackPricingPolicyType type) {
    return switch (type) {
      CommercialPackPricingPolicyType.componentSum => 'componentSum',
      CommercialPackPricingPolicyType.fixedPrice => 'fixedPrice',
      CommercialPackPricingPolicyType.packDiscount => 'packDiscount',
      CommercialPackPricingPolicyType.bonusItem => 'bonusItem',
    };
  }

  CommercialPackPricingPolicyType pricingPolicyTypeToEntity(String raw) {
    return switch (raw) {
      'componentSum' => CommercialPackPricingPolicyType.componentSum,
      'fixedPrice' => CommercialPackPricingPolicyType.fixedPrice,
      'packDiscount' => CommercialPackPricingPolicyType.packDiscount,
      'bonusItem' => CommercialPackPricingPolicyType.bonusItem,
      _ => throw ValidationException(
        'Invalid commercial pack pricing policy type "$raw".',
        code: 'invalid_commercial_pack_pricing_policy_type',
      ),
    };
  }

  String stockPolicyTypeToDto(CommercialPackStockPolicyType type) {
    return switch (type) {
      CommercialPackStockPolicyType.consumeComponentBalances =>
        'consumeComponentBalances',
      CommercialPackStockPolicyType.dedicatedStock => 'dedicatedStock',
    };
  }

  CommercialPackStockPolicyType stockPolicyTypeToEntity(String raw) {
    return switch (raw) {
      'consumeComponentBalances' =>
        CommercialPackStockPolicyType.consumeComponentBalances,
      'dedicatedStock' => CommercialPackStockPolicyType.dedicatedStock,
      _ => throw ValidationException(
        'Invalid commercial pack stock policy type "$raw".',
        code: 'invalid_commercial_pack_stock_policy_type',
      ),
    };
  }

  String syncStatusToDto(CommercialPackSyncStatus syncStatus) {
    return switch (syncStatus) {
      CommercialPackSyncStatus.pending => 'pending',
      CommercialPackSyncStatus.syncing => 'syncing',
      CommercialPackSyncStatus.synced => 'synced',
      CommercialPackSyncStatus.failed => 'failed',
      CommercialPackSyncStatus.conflict => 'conflict',
    };
  }

  CommercialPackSyncStatus syncStatusToEntity(String raw) {
    return switch (raw) {
      'pending' => CommercialPackSyncStatus.pending,
      'syncing' => CommercialPackSyncStatus.syncing,
      'synced' => CommercialPackSyncStatus.synced,
      'failed' => CommercialPackSyncStatus.failed,
      'conflict' => CommercialPackSyncStatus.conflict,
      _ => throw ValidationException(
        'Invalid commercial pack syncStatus "$raw".',
        code: 'invalid_commercial_pack_sync_status',
      ),
    };
  }

  String scopeTypeToDto(PackComponentScopeType scopeType) {
    return switch (scopeType) {
      PackComponentScopeType.variant => 'variant',
      PackComponentScopeType.product => 'product',
      PackComponentScopeType.color => 'color',
      PackComponentScopeType.size => 'size',
      PackComponentScopeType.category => 'category',
      PackComponentScopeType.collection => 'collection',
      PackComponentScopeType.commercialPack => 'commercialPack',
    };
  }

  PackComponentScopeType scopeTypeToEntity(String raw) {
    return switch (raw) {
      'variant' => PackComponentScopeType.variant,
      'product' => PackComponentScopeType.product,
      'color' => PackComponentScopeType.color,
      'size' => PackComponentScopeType.size,
      'category' => PackComponentScopeType.category,
      'collection' => PackComponentScopeType.collection,
      'commercialPack' => PackComponentScopeType.commercialPack,
      _ => throw ValidationException(
        'Invalid pack component scope type "$raw".',
        code: 'invalid_pack_component_scope_type',
      ),
    };
  }

  String compositionTypeToDto(PackComponentCompositionType compositionType) {
    return switch (compositionType) {
      PackComponentCompositionType.fixed => 'fixed',
      PackComponentCompositionType.flexible => 'flexible',
      PackComponentCompositionType.gridProportion => 'gridProportion',
    };
  }

  PackComponentCompositionType compositionTypeToEntity(String raw) {
    return switch (raw) {
      'fixed' => PackComponentCompositionType.fixed,
      'flexible' => PackComponentCompositionType.flexible,
      'gridProportion' => PackComponentCompositionType.gridProportion,
      _ => throw ValidationException(
        'Invalid pack component composition type "$raw".',
        code: 'invalid_pack_component_composition_type',
      ),
    };
  }

  String assortmentRuleTypeToDto(AssortmentRuleType type) {
    return switch (type) {
      AssortmentRuleType.minPercentagePerColor => 'minPercentagePerColor',
      AssortmentRuleType.minQuantityPerSize => 'minQuantityPerSize',
      AssortmentRuleType.minDistinctColors => 'minDistinctColors',
      AssortmentRuleType.minDistinctSizes => 'minDistinctSizes',
    };
  }

  AssortmentRuleType assortmentRuleTypeToEntity(String raw) {
    return switch (raw) {
      'minPercentagePerColor' => AssortmentRuleType.minPercentagePerColor,
      'minQuantityPerSize' => AssortmentRuleType.minQuantityPerSize,
      'minDistinctColors' => AssortmentRuleType.minDistinctColors,
      'minDistinctSizes' => AssortmentRuleType.minDistinctSizes,
      _ => throw ValidationException(
        'Invalid assortment rule type "$raw".',
        code: 'invalid_assortment_rule_type',
      ),
    };
  }
}
