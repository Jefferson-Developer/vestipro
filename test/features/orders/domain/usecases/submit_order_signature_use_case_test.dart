import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/orders/orders.dart';

void main() {
  group('SubmitOrderSignatureUseCase', () {
    test('syncs a pending signature, reconciling the local record with the '
        'server-confirmed metadata', () async {
      final draftRepository = _FakeOrderSignatureDraftRepository();
      final submissionRepository = _FakeOrderSignatureSubmissionRepository(
        AppSuccess<OrderSignatureSubmissionResult>(_confirmation()),
      );
      final analytics = FakeAnalyticsService();
      final useCase = SubmitOrderSignatureUseCase(
        submissionRepository,
        draftRepository,
        analytics,
      );
      final signature = _signature();

      final result = await useCase(signature: signature);

      expect(result, isA<AppSuccess<OrderSignature>>());
      final synced = (result as AppSuccess<OrderSignature>).value;
      expect(synced.syncStatus, OrderSignatureSyncStatus.synced);
      expect(
        synced.remoteImageStoragePath,
        'organizations/org-1/orders/order-1/signatures/signature-1.png',
      );
      expect(synced.deviceInfo, 'android 1.0.0');
      expect(
        draftRepository.saved.single.syncStatus,
        OrderSignatureSyncStatus.synced,
      );
      expect(
        analytics.loggedEvents.any(
          (event) => event.name == AnalyticsEvents.orderSignatureSynced,
        ),
        isTrue,
      );
    });

    test('never loses the already-captured signature when the sync itself '
        'fails (e.g. offline) — only the sync outcome is a failure, not the '
        'capture', () async {
      final draftRepository = _FakeOrderSignatureDraftRepository();
      final submissionRepository = _FakeOrderSignatureSubmissionRepository(
        const AppFailure<OrderSignatureSubmissionResult>(
          ConnectivityFailure('Sem conexão.'),
        ),
      );
      final analytics = FakeAnalyticsService();
      final useCase = SubmitOrderSignatureUseCase(
        submissionRepository,
        draftRepository,
        analytics,
      );

      final result = await useCase(signature: _signature());

      expect(result, isA<AppFailure<OrderSignature>>());
      expect(
        (result as AppFailure<OrderSignature>).failure,
        isA<ConnectivityFailure>(),
      );
      // The failure never reaches the local repository — the signature
      // that was already saved offline (`CaptureOrderSignatureUseCase`)
      // stays exactly as it was, still `pendingSync`, never lost.
      expect(draftRepository.saved, isEmpty);
      expect(
        analytics.loggedEvents.any(
          (event) => event.name == AnalyticsEvents.orderSignatureSyncFailed,
        ),
        isTrue,
      );
    });
  });
}

OrderSignature _signature() {
  final now = DateTime.utc(2026, 6, 1, 12);
  return OrderSignature(
    id: 'signature-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    orderId: 'order-1',
    signerRole: OrderSignerRole.customer,
    signedByUserId: 'seller-1',
    signedByName: 'Maria Cliente',
    method: OrderSignatureMethod.canvasDrawn,
    imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
    contentHash: 'hash-1',
    orderVersionAtSignature: 1,
    signedAt: now,
    createdAt: now,
    createdBy: 'seller-1',
    updatedAt: now,
    updatedBy: 'seller-1',
    version: 1,
    syncStatus: OrderSignatureSyncStatus.pendingSync,
  );
}

OrderSignatureSubmissionResult _confirmation() {
  return OrderSignatureSubmissionResult(
    signatureId: 'signature-1',
    remoteImageStoragePath:
        'organizations/org-1/orders/order-1/signatures/signature-1.png',
    serverReceivedAt: DateTime.utc(2026, 6, 1, 12, 1),
    deviceInfo: 'android 1.0.0',
    ipAddress: '203.0.113.10',
  );
}

final class _FakeOrderSignatureSubmissionRepository
    implements OrderSignatureSubmissionRepository {
  _FakeOrderSignatureSubmissionRepository(this._result);

  final AppResult<OrderSignatureSubmissionResult> _result;

  @override
  Future<AppResult<OrderSignatureSubmissionResult>> submit({
    required OrderSignature signature,
  }) async {
    return _result;
  }
}

final class _FakeOrderSignatureDraftRepository
    implements OrderSignatureDraftRepository {
  final List<OrderSignature> saved = <OrderSignature>[];

  @override
  Future<AppResult<void>> saveLocal({required OrderSignature signature}) async {
    saved.add(signature);
    return const AppSuccess<void>(null);
  }

  @override
  Future<AppResult<OrderSignature?>> getByOrderId({
    required String organizationId,
    required String companyId,
    required String orderId,
  }) async {
    return const AppSuccess<OrderSignature?>(null);
  }

  @override
  Future<AppResult<List<OrderSignature>>> getPendingSync({
    required String organizationId,
    required String companyId,
  }) async {
    return const AppSuccess<List<OrderSignature>>(<OrderSignature>[]);
  }
}
