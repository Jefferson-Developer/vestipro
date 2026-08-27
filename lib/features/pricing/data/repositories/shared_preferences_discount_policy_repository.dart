import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/discount_policy.dart';
import '../../domain/repositories/discount_policy_repository.dart';
import '../../domain/value_objects/discount_policy_status.dart';

@LazySingleton(as: DiscountPolicyRepository)
final class SharedPreferencesDiscountPolicyRepository
    implements DiscountPolicyRepository {
  const SharedPreferencesDiscountPolicyRepository();

  String _keyFor(String organizationId) => 'discount_policies_$organizationId';

  @override
  Future<AppResult<DiscountPolicy>> create({
    required DiscountPolicy discountPolicy,
  }) async {
    try {
      final existing = await _load(discountPolicy.organizationId);
      if (existing.any((item) => item.id == discountPolicy.id)) {
        return const AppFailure<DiscountPolicy>(
          ConflictFailure(
            'Discount policy already exists.',
            code: 'discount_policy_already_exists',
          ),
        );
      }
      if (existing.any(
        (item) =>
            item.companyId == discountPolicy.companyId &&
            item.role == discountPolicy.role &&
            item.deletedAt == null &&
            item.id != discountPolicy.id,
      )) {
        return const AppFailure<DiscountPolicy>(
          ConflictFailure(
            'A discount policy for this role already exists in the company.',
            code: 'discount_policy_role_already_exists',
          ),
        );
      }

      await _save(discountPolicy.organizationId, <DiscountPolicy>[
        ...existing,
        discountPolicy,
      ]);
      return AppSuccess<DiscountPolicy>(discountPolicy);
    } catch (exception) {
      return AppFailure<DiscountPolicy>(
        UnexpectedFailure(
          'Unexpected error creating discount policy locally.',
          code: 'discount_policy_local_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<DiscountPolicy?>> getById({
    required String organizationId,
    required String id,
  }) async {
    try {
      final items = await _load(organizationId);
      for (final item in items) {
        if (item.id == id && item.deletedAt == null) {
          return AppSuccess<DiscountPolicy?>(item);
        }
      }
      return const AppSuccess<DiscountPolicy?>(null);
    } catch (exception) {
      return AppFailure<DiscountPolicy?>(
        UnexpectedFailure(
          'Unexpected error loading discount policy locally.',
          code: 'discount_policy_local_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<DiscountPolicy>>> listByCompany({
    required String organizationId,
    required String companyId,
  }) async {
    try {
      final items = await _load(organizationId);
      return AppSuccess<List<DiscountPolicy>>(
        items
            .where(
              (item) => item.companyId == companyId && item.deletedAt == null,
            )
            .toList(growable: false),
      );
    } catch (exception) {
      return AppFailure<List<DiscountPolicy>>(
        UnexpectedFailure(
          'Unexpected error listing discount policies locally.',
          code: 'discount_policy_local_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<DiscountPolicy>> update({
    required DiscountPolicy discountPolicy,
  }) async {
    try {
      final existing = await _load(discountPolicy.organizationId);
      final currentIndex = existing.indexWhere(
        (item) => item.id == discountPolicy.id,
      );
      if (currentIndex < 0) {
        return const AppFailure<DiscountPolicy>(
          NotFoundFailure(
            'Discount policy not found.',
            code: 'discount_policy_not_found',
          ),
        );
      }
      if (existing.any(
        (item) =>
            item.companyId == discountPolicy.companyId &&
            item.role == discountPolicy.role &&
            item.deletedAt == null &&
            item.id != discountPolicy.id,
      )) {
        return const AppFailure<DiscountPolicy>(
          ConflictFailure(
            'A discount policy for this role already exists in the company.',
            code: 'discount_policy_role_already_exists',
          ),
        );
      }

      final next = List<DiscountPolicy>.of(existing);
      next[currentIndex] = discountPolicy;
      await _save(discountPolicy.organizationId, next);
      return AppSuccess<DiscountPolicy>(discountPolicy);
    } catch (exception) {
      return AppFailure<DiscountPolicy>(
        UnexpectedFailure(
          'Unexpected error updating discount policy locally.',
          code: 'discount_policy_local_update_unexpected',
          cause: exception,
        ),
      );
    }
  }

  Future<List<DiscountPolicy>> _load(String organizationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(organizationId));
    if (raw == null || raw.isEmpty) return const <DiscountPolicy>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) return const <DiscountPolicy>[];
    return decoded
        .map((item) => _fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> _save(String organizationId, List<DiscountPolicy> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(organizationId),
      jsonEncode(items.map(_toJson).toList(growable: false)),
    );
  }

  Map<String, Object?> _toJson(DiscountPolicy item) {
    return <String, Object?>{
      'id': item.id,
      'organizationId': item.organizationId,
      'companyId': item.companyId,
      'role': item.role,
      'maxDiscountPercent': item.maxDiscountPercent,
      'priceListIds': item.priceListIds,
      'requiresApprovalAbovePercent': item.requiresApprovalAbovePercent,
      'status': item.status.name,
      'createdAt': item.createdAt.toUtc().toIso8601String(),
      'createdBy': item.createdBy,
      'updatedAt': item.updatedAt.toUtc().toIso8601String(),
      'updatedBy': item.updatedBy,
      'deletedAt': item.deletedAt?.toUtc().toIso8601String(),
      'version': item.version,
      'syncStatus': item.syncStatus,
    };
  }

  DiscountPolicy _fromJson(Map<String, dynamic> json) {
    return DiscountPolicy(
      id: json['id'] as String,
      organizationId: json['organizationId'] as String,
      companyId: json['companyId'] as String,
      role: json['role'] as String,
      maxDiscountPercent: (json['maxDiscountPercent'] as num).toDouble(),
      priceListIds: (json['priceListIds'] as List<dynamic>? ?? const [])
          .cast<String>()
          .toList(growable: false),
      requiresApprovalAbovePercent:
          (json['requiresApprovalAbovePercent'] as num?)?.toDouble(),
      status: DiscountPolicyStatus.values.byName(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      updatedBy: json['updatedBy'] as String,
      deletedAt: (json['deletedAt'] as String?) == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      version: json['version'] as int? ?? 1,
      syncStatus: json['syncStatus'] as String? ?? 'pending',
    );
  }
}
