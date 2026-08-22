import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

import '../components/test_pump_app.dart';

Future<void> _pumpAtWidth(
  WidgetTester tester,
  double width,
  Widget Function(BuildContext, AppBreakpoint) builder,
) {
  // The default flutter_test surface is only 800x600 logical pixels: wide
  // enough for mobile/tablet fixtures, but too narrow for desktop/large
  // desktop ones. Resizing it here (instead of only the requested
  // SizedBox) is what actually lets AppResponsiveBuilder's LayoutBuilder
  // see the full requested width.
  final view = tester.view;
  view.physicalSize = Size(width + 100, 500);
  view.devicePixelRatio = 1.0;
  addTearDown(view.resetPhysicalSize);
  addTearDown(view.resetDevicePixelRatio);

  return pumpApp(
    tester,
    SizedBox(
      width: width,
      height: 400,
      child: AppResponsiveBuilder(builder: builder),
    ),
  );
}

void main() {
  group('AppResponsiveBuilder', () {
    testWidgets('resolves mobile for widths below 600', (tester) async {
      AppBreakpoint? resolved;
      await _pumpAtWidth(tester, 375, (context, breakpoint) {
        resolved = breakpoint;
        return const SizedBox.shrink();
      });

      expect(resolved, AppBreakpoint.mobile);
    });

    testWidgets('resolves tablet for widths between 600 and 1024', (
      tester,
    ) async {
      AppBreakpoint? resolved;
      await _pumpAtWidth(tester, 800, (context, breakpoint) {
        resolved = breakpoint;
        return const SizedBox.shrink();
      });

      expect(resolved, AppBreakpoint.tablet);
    });

    testWidgets('resolves desktop for widths between 1024 and 1440', (
      tester,
    ) async {
      AppBreakpoint? resolved;
      await _pumpAtWidth(tester, 1200, (context, breakpoint) {
        resolved = breakpoint;
        return const SizedBox.shrink();
      });

      expect(resolved, AppBreakpoint.desktop);
    });

    testWidgets('resolves largeDesktop for widths at or above 1440', (
      tester,
    ) async {
      AppBreakpoint? resolved;
      await _pumpAtWidth(tester, 1600, (context, breakpoint) {
        resolved = breakpoint;
        return const SizedBox.shrink();
      });

      expect(resolved, AppBreakpoint.largeDesktop);
    });

    testWidgets('resolves against the widget own width, not the window', (
      tester,
    ) async {
      // The window/root is genuinely wide (desktop-sized), but this
      // AppResponsiveBuilder only has a narrow (mobile-sized) box to work
      // with — it must resolve against that local constraint, never
      // MediaQuery's full width.
      final view = tester.view;
      view.physicalSize = const Size(1680, 800);
      view.devicePixelRatio = 1.0;
      addTearDown(view.resetPhysicalSize);
      addTearDown(view.resetDevicePixelRatio);

      AppBreakpoint? resolved;
      await pumpApp(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 320,
            child: AppResponsiveBuilder(
              builder: (context, breakpoint) {
                resolved = breakpoint;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(resolved, AppBreakpoint.mobile);
    });

    testWidgets('rebuilds with the new breakpoint when resized', (
      tester,
    ) async {
      final view = tester.view;
      view.physicalSize = const Size(1300, 500);
      view.devicePixelRatio = 1.0;
      addTearDown(view.resetPhysicalSize);
      addTearDown(view.resetDevicePixelRatio);

      final breakpoints = <AppBreakpoint>[];
      Widget buildAt(double width) {
        return SizedBox(
          width: width,
          height: 400,
          child: AppResponsiveBuilder(
            builder: (context, breakpoint) {
              breakpoints.add(breakpoint);
              return const SizedBox.shrink();
            },
          ),
        );
      }

      await pumpApp(tester, buildAt(375));
      await pumpApp(tester, buildAt(1200));

      expect(breakpoints, <AppBreakpoint>[
        AppBreakpoint.mobile,
        AppBreakpoint.desktop,
      ]);
    });
  });

  group('AppResponsiveValue', () {
    const value = AppResponsiveValue<int>(
      mobile: 1,
      tablet: 2,
      desktop: 3,
      largeDesktop: 4,
    );

    test('resolves the exact value for every provided tier', () {
      expect(value.resolve(AppBreakpoint.mobile), 1);
      expect(value.resolve(AppBreakpoint.tablet), 2);
      expect(value.resolve(AppBreakpoint.desktop), 3);
      expect(value.resolve(AppBreakpoint.largeDesktop), 4);
    });

    test('falls back to the nearest narrower tier when not provided', () {
      const mobileOnly = AppResponsiveValue<String>(mobile: 'm');

      expect(mobileOnly.resolve(AppBreakpoint.mobile), 'm');
      expect(mobileOnly.resolve(AppBreakpoint.tablet), 'm');
      expect(mobileOnly.resolve(AppBreakpoint.desktop), 'm');
      expect(mobileOnly.resolve(AppBreakpoint.largeDesktop), 'm');
    });

    test('falls back through multiple missing tiers', () {
      const mobileAndDesktop = AppResponsiveValue<String>(
        mobile: 'm',
        desktop: 'd',
      );

      expect(mobileAndDesktop.resolve(AppBreakpoint.tablet), 'm');
      expect(mobileAndDesktop.resolve(AppBreakpoint.desktop), 'd');
      expect(mobileAndDesktop.resolve(AppBreakpoint.largeDesktop), 'd');
    });
  });
}
