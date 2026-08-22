import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

void main() {
  group('AppTheme', () {
    test('light builds a valid, light-brightness ThemeData', () {
      final theme = AppTheme.light;

      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.useMaterial3, isTrue);
      expect(theme.extension<AppColors>(), AppColors.light);
    });

    test('dark builds a valid, dark-brightness ThemeData', () {
      final theme = AppTheme.dark;

      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.useMaterial3, isTrue);
      expect(theme.extension<AppColors>(), AppColors.dark);
    });

    test('light and dark produce distinct colors for the same roles', () {
      final light = AppTheme.light;
      final dark = AppTheme.dark;

      expect(light.colorScheme.primary, isNot(dark.colorScheme.primary));
      expect(light.colorScheme.surface, isNot(dark.colorScheme.surface));
      expect(
        light.scaffoldBackgroundColor,
        isNot(dark.scaffoldBackgroundColor),
      );
      expect(light.textTheme.bodyLarge?.color, AppColors.light.onSurface);
      expect(dark.textTheme.bodyLarge?.color, AppColors.dark.onSurface);
    });

    testWidgets('renders a MaterialApp with light and dark theme wired', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const Scaffold(body: Text('VestiPro')),
        ),
      );

      expect(find.text('VestiPro'), findsOneWidget);
    });
  });

  group('DesignSystemContext', () {
    testWidgets('context.colors resolves the active theme tokens', (
      tester,
    ) async {
      AppColors? resolved;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: Builder(
            builder: (context) {
              resolved = context.colors;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, AppColors.dark);
    });

    testWidgets('context.shadows resolves against the active brightness', (
      tester,
    ) async {
      AppShadows? resolved;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: Builder(
            builder: (context) {
              resolved = context.shadows;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, AppShadows.dark);
    });

    testWidgets('context.breakpoint resolves from the available width', (
      tester,
    ) async {
      AppBreakpoint? resolved;
      final view = tester.view;
      view.physicalSize = const Size(1500, 900);
      view.devicePixelRatio = 1.0;
      addTearDown(view.resetPhysicalSize);
      addTearDown(view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) {
              resolved = context.breakpoint;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, AppBreakpoint.largeDesktop);
    });
  });
}
