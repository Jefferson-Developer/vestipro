import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/connectivity/connectivity.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/sync/sync.dart';

import '../test_pump_app.dart';

void main() {
  Future<void> expectGolden(
    WidgetTester tester,
    Widget child,
    String name, {
    required double width,
    double height = 120,
  }) async {
    final view = tester.view;
    view.physicalSize = Size(width + 80, height);
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    await pumpApp(
      tester,
      RepaintBoundary(
        key: Key(name),
        child: SizedBox(width: width, child: child),
      ),
    );
    await tester.pump();
    await expectLater(find.byKey(Key(name)), matchesGoldenFile('$name.png'));
  }

  Widget buildIndicator(
    ConnectivityIndicatorStatus status,
    OutboxSummary summary,
  ) {
    return AppConnectivityIndicator(
      status: status,
      outboxSummary: summary,
      onTap: () {},
    );
  }

  group('AppConnectivityIndicator goldens', () {
    const widths = <String, double>{
      'mobile': 375,
      'tablet': 800,
      'desktop': 1200,
    };
    const scenarios = <String, (ConnectivityIndicatorStatus, OutboxSummary)>{
      'online_synced': (
        ConnectivityIndicatorStatus.onlineSynced,
        OutboxSummary(),
      ),
      'online_syncing': (
        ConnectivityIndicatorStatus.onlineSyncing,
        OutboxSummary(pendingCount: 2, syncingCount: 1),
      ),
      'offline_pending': (
        ConnectivityIndicatorStatus.offlinePending,
        OutboxSummary(failedCount: 1),
      ),
      'offline_no_pending': (
        ConnectivityIndicatorStatus.offlineNoPending,
        OutboxSummary(),
      ),
    };

    for (final widthEntry in widths.entries) {
      for (final scenarioEntry in scenarios.entries) {
        testWidgets('${scenarioEntry.key} ${widthEntry.key}', (tester) async {
          await expectGolden(
            tester,
            buildIndicator(scenarioEntry.value.$1, scenarioEntry.value.$2),
            'app_connectivity_indicator_${scenarioEntry.key}_${widthEntry.key}',
            width: widthEntry.value,
          );
        });
      }
    }
  });
}
