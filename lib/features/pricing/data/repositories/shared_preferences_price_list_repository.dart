import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/price_list.dart';
import '../../domain/repositories/price_list_repository.dart';
import '../mappers/price_list_mapper.dart';

/// Durable local Price List store used until the real remote/outbox sync
/// implementation exists (EPIC-11, TASK-083) — same precedent as
/// `SharedPreferencesCustomerRepository`/`SharedPreferencesProductRepository`.
/// Enum<->string codes are shared with the remote-facing [PriceListMapper]
/// so they stay identical once a Firestore-backed implementation exists;
/// dates are kept as plain ISO-8601 strings rather than the Firestore
/// `Timestamp` shape [PriceListDto] uses, since this store has nothing to
/// do with `cloud_firestore`.
@LazySingleton(as: PriceListRepository)
final class SharedPreferencesPriceListRepository
    implements PriceListRepository {
  const SharedPreferencesPriceListRepository(this._mapper);

  final PriceListMapper _mapper;

  String _keyFor(String organizationId) => 'price_lists_$organizationId';

  @override
  Future<AppResult<PriceList>> create({required PriceList priceList}) async {
    try {
      final existing = await _load(priceList.organizationId);
      if (existing.any((item) => item.id == priceList.id)) {
        return const AppFailure<PriceList>(
          ConflictFailure(
            'Price list already exists.',
            code: 'price_list_already_exists',
          ),
        );
      }
      final next = <PriceList>[...existing, priceList];
      await _save(priceList.organizationId, next);
      return AppSuccess<PriceList>(priceList);
    } catch (exception) {
      return AppFailure<PriceList>(
        UnexpectedFailure(
          'Unexpected error creating price list locally.',
          code: 'price_list_local_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<PriceList>> update({required PriceList priceList}) async {
    try {
      final existing = await _load(priceList.organizationId);
      final current = existing.where((item) => item.id == priceList.id);
      if (current.isEmpty) {
        return const AppFailure<PriceList>(
          NotFoundFailure(
            'Price list not found.',
            code: 'price_list_not_found',
          ),
        );
      }
      if (current.first.currency != priceList.currency) {
        return const AppFailure<PriceList>(
          ValidationFailure(
            'Price list currency is immutable once created.',
            code: 'price_list_currency_immutable',
          ),
        );
      }
      final next = <PriceList>[
        ...existing.where((item) => item.id != priceList.id),
        priceList,
      ];
      await _save(priceList.organizationId, next);
      return AppSuccess<PriceList>(priceList);
    } catch (exception) {
      return AppFailure<PriceList>(
        UnexpectedFailure(
          'Unexpected error updating price list locally.',
          code: 'price_list_local_update_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<PriceList?>> getById({
    required String organizationId,
    required String id,
  }) async {
    try {
      final existing = await _load(organizationId);
      for (final priceList in existing) {
        if (priceList.id == id && priceList.deletedAt == null) {
          return AppSuccess<PriceList?>(priceList);
        }
      }
      return const AppSuccess<PriceList?>(null);
    } catch (exception) {
      return AppFailure<PriceList?>(
        UnexpectedFailure(
          'Unexpected error loading price list locally.',
          code: 'price_list_local_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<PriceList>>> listByCompany({
    required String organizationId,
    required String companyId,
  }) async {
    try {
      final existing = await _load(organizationId);
      return AppSuccess<List<PriceList>>(
        existing
            .where(
              (priceList) =>
                  priceList.companyId == companyId &&
                  priceList.deletedAt == null,
            )
            .toList(growable: false),
      );
    } catch (exception) {
      return AppFailure<List<PriceList>>(
        UnexpectedFailure(
          'Unexpected error listing price lists locally.',
          code: 'price_list_local_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  Future<List<PriceList>> _load(String organizationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(organizationId));
    if (raw == null || raw.isEmpty) return const <PriceList>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) return const <PriceList>[];
    return decoded
        .map((item) => _fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> _save(String organizationId, List<PriceList> priceLists) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(organizationId),
      jsonEncode(priceLists.map(_toJson).toList(growable: false)),
    );
  }

  /// Plain (non-Firestore) JSON encoding for local persistence — unlike
  /// [PriceListDto] (which shapes dates as `cloud_firestore` `Timestamp`
  /// for the eventual remote store), dates here are ISO-8601 strings, same
  /// precedent `SharedPreferencesCustomerRepository._toJson`/`_fromJson`
  /// already follow.
  Map<String, dynamic> _toJson(PriceList priceList) {
    return <String, dynamic>{
      'id': priceList.id,
      'organizationId': priceList.organizationId,
      'companyId': priceList.companyId,
      'name': priceList.name,
      'currency': priceList.currency,
      'validFrom': priceList.validFrom.toIso8601String(),
      'validTo': priceList.validTo?.toIso8601String(),
      'status': _mapper.statusToDto(priceList.status),
      'scope': _mapper.scopeToDto(priceList.scope),
      'scopeValue': priceList.scopeValue,
      'priority': priceList.priority,
      'createdAt': priceList.createdAt.toIso8601String(),
      'createdBy': priceList.createdBy,
      'updatedAt': priceList.updatedAt.toIso8601String(),
      'updatedBy': priceList.updatedBy,
      'deletedAt': priceList.deletedAt?.toIso8601String(),
      'version': priceList.version,
      'syncStatus': _mapper.syncStatusToDto(priceList.syncStatus),
    };
  }

  PriceList _fromJson(Map<String, dynamic> json) {
    return PriceList(
      id: json['id'] as String,
      organizationId: json['organizationId'] as String,
      companyId: json['companyId'] as String,
      name: json['name'] as String,
      currency: json['currency'] as String,
      validFrom: DateTime.parse(json['validFrom'] as String),
      validTo: (json['validTo'] as String?) == null
          ? null
          : DateTime.parse(json['validTo'] as String),
      status: _mapper.statusToEntity(json['status'] as String),
      scope: _mapper.scopeToEntity(json['scope'] as String),
      scopeValue: json['scopeValue'] as String?,
      priority: json['priority'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      updatedBy: json['updatedBy'] as String,
      deletedAt: (json['deletedAt'] as String?) == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      version: json['version'] as int,
      syncStatus: _mapper.syncStatusToEntity(json['syncStatus'] as String),
    );
  }
}
