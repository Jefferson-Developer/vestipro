import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/functions/functions.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/wallet_summary.dart';
import '../../domain/entities/wallet_summary_reference.dart';
import '../../domain/repositories/wallet_summary_repository.dart';

/// Calls the `generateWalletSummary` Cloud Function (TASK-186, EPIC-28) —
/// the only place this feature ever reaches the network. No Firestore
/// datasource exists for this feature: the server-side cache
/// (`organizations/{organizationId}/walletSummaries/{sellerId}_{periodKey}`)
/// is never readable directly by any client (`firestore.rules` denies it
/// outright), so every call — cached or freshly generated — goes through
/// this one callable.
@LazySingleton(as: WalletSummaryRepository)
final class CloudFunctionsWalletSummaryRepository
    implements WalletSummaryRepository {
  const CloudFunctionsWalletSummaryRepository(this._functions);

  final CloudFunctionsService _functions;

  @override
  Future<AppResult<WalletSummary>> generate({
    required String organizationId,
    required String companyId,
    required String sellerId,
  }) => _guard(() async {
    final json = await _functions.call<Map<String, dynamic>>(
      'generateWalletSummary',
      requireAuth: true,
      data: <String, dynamic>{
        'organizationId': organizationId,
        'companyId': companyId,
        'sellerId': sellerId,
      },
    );
    final rawReferences =
        json['references'] as List<dynamic>? ?? const <dynamic>[];
    return WalletSummary(
      summaryText: json['summaryText'] as String,
      references: rawReferences
          .map((raw) {
            final reference = Map<String, dynamic>.from(raw as Map);
            return WalletSummaryReference(
              code: reference['code'] as String,
              label: reference['label'] as String,
              value: reference['value'] as String,
              unit: reference['unit'] as String?,
            );
          })
          .toList(growable: false),
      periodKey: json['periodKey'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      fromCache: json['fromCache'] as bool? ?? false,
    );
  });

  Future<AppResult<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return AppSuccess<T>(await action());
    } on AppException catch (error) {
      return AppFailure<T>(mapAppExceptionToFailure(error));
    } catch (error) {
      return AppFailure<T>(
        UnexpectedFailure(
          'Falha inesperada ao gerar o resumo da carteira.',
          cause: error,
        ),
      );
    }
  }
}
