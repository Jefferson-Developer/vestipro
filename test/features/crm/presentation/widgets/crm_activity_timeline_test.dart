import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/features/crm/crm.dart';

void main() {
  group('CrmActivityTimeline', () {
    testWidgets(
      'shows icon by type, pending sync and overdue follow-up badge',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: CrmActivityTimeline(
                activities: <CrmActivity>[
                  _activity(
                    id: 'call-1',
                    type: CrmActivityType.phoneCall,
                    description: 'Ligacao sobre reposicao',
                  ),
                ],
                overdueActivityIds: const <String>{'call-1'},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.call_outlined), findsOneWidget);
        expect(find.text('Ligacao'), findsOneWidget);
        expect(find.text('Ligacao sobre reposicao'), findsOneWidget);
        expect(find.text('Pendente de sync'), findsOneWidget);
        expect(find.text('Follow-up vencido'), findsOneWidget);
      },
    );
  });
}

CrmActivity _activity({
  required String id,
  required CrmActivityType type,
  required String description,
}) {
  final now = DateTime.utc(2026, 8, 24, 12);
  return CrmActivity(
    id: id,
    organizationId: 'org-1',
    type: type,
    customerId: 'customer-1',
    userId: 'rep-1',
    occurredAt: now,
    description: description,
    createdAt: now,
    createdBy: 'rep-1',
    updatedAt: now,
    updatedBy: 'rep-1',
    version: 1,
    syncStatus: CrmActivitySyncStatus.pending,
  );
}
