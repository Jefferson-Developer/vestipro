import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

void main() {
  group('AppBreakpoints.resolve', () {
    test('resolves mobile below the tablet threshold', () {
      expect(AppBreakpoints.resolve(0), AppBreakpoint.mobile);
      expect(AppBreakpoints.resolve(320), AppBreakpoint.mobile);
      expect(
        AppBreakpoints.resolve(AppBreakpoints.tablet - 1),
        AppBreakpoint.mobile,
      );
    });

    test('resolves tablet exactly at its lower bound and below desktop', () {
      expect(
        AppBreakpoints.resolve(AppBreakpoints.tablet),
        AppBreakpoint.tablet,
      );
      expect(
        AppBreakpoints.resolve(AppBreakpoints.desktop - 1),
        AppBreakpoint.tablet,
      );
    });

    test(
      'resolves desktop exactly at its lower bound and below largeDesktop',
      () {
        expect(
          AppBreakpoints.resolve(AppBreakpoints.desktop),
          AppBreakpoint.desktop,
        );
        expect(
          AppBreakpoints.resolve(AppBreakpoints.largeDesktop - 1),
          AppBreakpoint.desktop,
        );
      },
    );

    test('resolves largeDesktop at and above its lower bound', () {
      expect(
        AppBreakpoints.resolve(AppBreakpoints.largeDesktop),
        AppBreakpoint.largeDesktop,
      );
      expect(AppBreakpoints.resolve(2560), AppBreakpoint.largeDesktop);
    });
  });
}
