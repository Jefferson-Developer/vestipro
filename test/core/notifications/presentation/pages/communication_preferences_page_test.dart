import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/notifications/notifications.dart';
import 'package:vestipro/core/utils/utils.dart';

import '../../../../core/design_system/components/test_pump_app.dart';
import '../../../../support/fake_communication_preferences_repository.dart';

void main() {
  late FakeCommunicationPreferencesRepository repository;
  late FakeAnalyticsService analyticsService;

  setUp(() {
    repository = FakeCommunicationPreferencesRepository();
    analyticsService = FakeAnalyticsService();
  });

  Widget buildPage() {
    return CommunicationPreferencesPage(
      organizationId: 'org-1',
      userId: 'user-1',
      createCubit: () => CommunicationPreferencesCubit(
        WatchCommunicationPreferencesUseCase(repository),
        SaveCommunicationPreferencesUseCase(repository),
        analyticsService,
      ),
    );
  }

  Finder chip(
    AppNotificationCategory category,
    CommunicationChannel channel,
    CommunicationFrequency frequency,
  ) {
    return find.byKey(
      ValueKey<String>(
        'preference-chip-${category.name}-${channel.name}-${frequency.name}',
      ),
    );
  }

  testWidgets('renders every category with the documented default frequency '
      'selection', (tester) async {
    await pumpApp(tester, buildPage());
    await tester.pumpAndSettle();

    expect(find.text('CRM'), findsOneWidget);
    expect(find.text('Comercial'), findsOneWidget);
    expect(find.text('Sistema'), findsOneWidget);

    for (final category in AppNotificationCategory.values) {
      expect(
        tester
            .widget<AppFilterChip>(
              chip(
                category,
                CommunicationChannel.push,
                CommunicationFrequency.immediate,
              ),
            )
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<AppFilterChip>(
              chip(
                category,
                CommunicationChannel.email,
                CommunicationFrequency.disabled,
              ),
            )
            .selected,
        isTrue,
      );
    }
  });

  testWidgets('a successful change is persisted and logged, without any error '
      'snackbar', (tester) async {
    await pumpApp(tester, buildPage());
    await tester.pumpAndSettle();

    await tester.tap(
      chip(
        AppNotificationCategory.crm,
        CommunicationChannel.email,
        CommunicationFrequency.dailyDigest,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(
      analyticsService.loggedEvents.last.name,
      AnalyticsEvents.communicationPreferencesUpdated,
    );

    final saved = await repository.get(
      organizationId: 'org-1',
      userId: 'user-1',
    );
    final preferences = (saved as AppSuccess<CommunicationPreferences>).value;
    expect(
      preferences.frequencyFor(
        AppNotificationCategory.crm,
        CommunicationChannel.email,
      ),
      CommunicationFrequency.dailyDigest,
    );
    expect(
      tester
          .widget<AppFilterChip>(
            chip(
              AppNotificationCategory.crm,
              CommunicationChannel.email,
              CommunicationFrequency.dailyDigest,
            ),
          )
          .selected,
      isTrue,
    );
  });

  testWidgets('shows an error snackbar and keeps the previous selection when a '
      'change would fully disable the system category', (tester) async {
    // Seeds the system category with push already disabled — only the
    // central channel keeps it from being fully muted.
    repository.seed(
      CommunicationPreferences.defaults(
        organizationId: 'org-1',
        userId: 'user-1',
      ).withChannelFrequency(
        category: AppNotificationCategory.system,
        channel: CommunicationChannel.push,
        frequency: CommunicationFrequency.disabled,
      ),
    );

    await pumpApp(tester, buildPage());
    await tester.pumpAndSettle();

    final targetChip = chip(
      AppNotificationCategory.system,
      CommunicationChannel.inApp,
      CommunicationFrequency.disabled,
    );
    await tester.ensureVisible(targetChip);
    await tester.pumpAndSettle();
    await tester.tap(targetChip);
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    // The rejected change never reached the repository — central stays
    // selected as `immediate`, never `disabled`.
    expect(
      tester
          .widget<AppFilterChip>(
            chip(
              AppNotificationCategory.system,
              CommunicationChannel.inApp,
              CommunicationFrequency.immediate,
            ),
          )
          .selected,
      isTrue,
    );
    final refreshed = await repository.get(
      organizationId: 'org-1',
      userId: 'user-1',
    );
    final preferences =
        (refreshed as AppSuccess<CommunicationPreferences>).value;
    expect(preferences.hasSystemCategoryFullyDisabled, isFalse);
  });
}
