import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/payment_installment.dart';
import '../../domain/entities/payment_term.dart';
import '../../domain/repositories/payment_term_repository.dart';
import '../../domain/value_objects/payment_term_status.dart';
import '../../domain/value_objects/payment_term_sync_status.dart';

@LazySingleton(as: PaymentTermRepository)
final class SharedPreferencesPaymentTermRepository
    implements PaymentTermRepository {
  String _keyFor(String organizationId) => 'payment_terms_$organizationId';

  @override
  Future<AppResult<PaymentTerm>> create({
    required PaymentTerm paymentTerm,
  }) async {
    try {
      final existing = await _load(paymentTerm.organizationId);
      if (existing.any((item) => item.id == paymentTerm.id)) {
        return const AppFailure<PaymentTerm>(
          ConflictFailure(
            'Payment term already exists.',
            code: 'payment_term_already_exists',
          ),
        );
      }
      await _save(paymentTerm.organizationId, <PaymentTerm>[
        ...existing,
        paymentTerm,
      ]);
      return AppSuccess<PaymentTerm>(paymentTerm);
    } catch (exception) {
      return AppFailure<PaymentTerm>(
        UnexpectedFailure(
          'Unexpected error creating payment term locally.',
          code: 'payment_term_local_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<PaymentTerm?>> getById({
    required String organizationId,
    required String id,
  }) async {
    try {
      final existing = await _load(organizationId);
      for (final term in existing) {
        if (term.id == id && term.deletedAt == null) {
          return AppSuccess<PaymentTerm?>(term);
        }
      }
      return const AppSuccess<PaymentTerm?>(null);
    } catch (exception) {
      return AppFailure<PaymentTerm?>(
        UnexpectedFailure(
          'Unexpected error loading payment term locally.',
          code: 'payment_term_local_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<PaymentTerm>>> listByCompany({
    required String organizationId,
    required String companyId,
  }) async {
    try {
      final existing = await _load(organizationId);
      return AppSuccess<List<PaymentTerm>>(
        existing
            .where(
              (term) => term.companyId == companyId && term.deletedAt == null,
            )
            .toList(growable: false),
      );
    } catch (exception) {
      return AppFailure<List<PaymentTerm>>(
        UnexpectedFailure(
          'Unexpected error listing payment terms locally.',
          code: 'payment_term_local_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<PaymentTerm>> update({
    required PaymentTerm paymentTerm,
  }) async {
    try {
      final existing = await _load(paymentTerm.organizationId);
      final index = existing.indexWhere((item) => item.id == paymentTerm.id);
      if (index == -1) {
        return const AppFailure<PaymentTerm>(
          NotFoundFailure(
            'Payment term not found.',
            code: 'payment_term_not_found',
          ),
        );
      }
      final next = List<PaymentTerm>.of(existing)..[index] = paymentTerm;
      await _save(paymentTerm.organizationId, next);
      return AppSuccess<PaymentTerm>(paymentTerm);
    } catch (exception) {
      return AppFailure<PaymentTerm>(
        UnexpectedFailure(
          'Unexpected error updating payment term locally.',
          code: 'payment_term_local_update_unexpected',
          cause: exception,
        ),
      );
    }
  }

  Future<List<PaymentTerm>> _load(String organizationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(organizationId));
    if (raw == null || raw.isEmpty) return const <PaymentTerm>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) return const <PaymentTerm>[];
    return decoded
        .map((item) => _fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> _save(String organizationId, List<PaymentTerm> terms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(organizationId),
      jsonEncode(terms.map(_toJson).toList(growable: false)),
    );
  }

  Map<String, Object?> _toJson(PaymentTerm term) {
    return <String, Object?>{
      'id': term.id,
      'organizationId': term.organizationId,
      'companyId': term.companyId,
      'name': term.name,
      'installments': term.installments
          .map((installment) => installment.toJson())
          .toList(growable: false),
      'averageTermDays': term.averageTermDays,
      'status': term.status.name,
      'priceListIds': term.priceListIds,
      'createdAt': term.createdAt.toIso8601String(),
      'createdBy': term.createdBy,
      'updatedAt': term.updatedAt.toIso8601String(),
      'updatedBy': term.updatedBy,
      'deletedAt': term.deletedAt?.toIso8601String(),
      'version': term.version,
      'syncStatus': term.syncStatus.name,
    };
  }

  PaymentTerm _fromJson(Map<String, dynamic> json) {
    return PaymentTerm(
      id: json['id'] as String,
      organizationId: json['organizationId'] as String,
      companyId: json['companyId'] as String,
      name: json['name'] as String,
      installments: (json['installments'] as List<dynamic>)
          .map(
            (item) => PaymentInstallment.fromJson(
              Map<String, Object?>.from(item as Map),
            ),
          )
          .toList(growable: false),
      averageTermDays: (json['averageTermDays'] as num).toDouble(),
      status: PaymentTermStatus.values.byName(json['status'] as String),
      priceListIds: (json['priceListIds'] as List<dynamic>)
          .map((item) => item as String)
          .toList(growable: false),
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      updatedBy: json['updatedBy'] as String,
      deletedAt: (json['deletedAt'] as String?) == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      version: (json['version'] as num).toInt(),
      syncStatus: PaymentTermSyncStatus.values.byName(
        json['syncStatus'] as String,
      ),
    );
  }
}
