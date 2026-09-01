import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/connectivity/connectivity.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/sync/sync.dart';

import 'test_pump_app.dart';

void main() {
  group('AppConnectivityIndicator', () {
    testWidgets('renders online synced copy with text and icon', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AppConnectivityIndicator(
          status: ConnectivityIndicatorStatus.onlineSynced,
          outboxSummary: OutboxSummary(),
        ),
      );

      expect(find.text('Online e sincronizado'), findsOneWidget);
      expect(find.text('Nenhuma pendência aguardando envio.'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
    });

    testWidgets('renders online syncing copy with pending count', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AppConnectivityIndicator(
          status: ConnectivityIndicatorStatus.onlineSyncing,
          outboxSummary: OutboxSummary(pendingCount: 2, syncingCount: 1),
        ),
      );

      expect(find.text('Online, sincronizando'), findsOneWidget);
      expect(
        find.text('3 pendências aguardando sincronização.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.sync_outlined), findsOneWidget);
    });

    testWidgets(
      'renders offline pending copy with text and icon for accessibility',
      (tester) async {
        await pumpApp(
          tester,
          const AppConnectivityIndicator(
            status: ConnectivityIndicatorStatus.offlinePending,
            outboxSummary: OutboxSummary(failedCount: 1),
          ),
        );

        expect(find.text('Offline com pendências'), findsOneWidget);
        expect(
          find.text('1 pendência salva localmente até a conexão voltar.'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
      },
    );

    testWidgets('renders offline without pendencies copy', (tester) async {
      await pumpApp(
        tester,
        const AppConnectivityIndicator(
          status: ConnectivityIndicatorStatus.offlineNoPending,
          outboxSummary: OutboxSummary(),
        ),
      );

      expect(find.text('Offline'), findsOneWidget);
      expect(
        find.text('Sem pendências no momento. Novas ações ficam locais.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.wifi_off_outlined), findsOneWidget);
    });
  });
}
