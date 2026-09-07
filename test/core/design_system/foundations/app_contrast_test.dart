import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';

void main() {
  group('AppContrast', () {
    test('ratio between identical colors is exactly 1', () {
      expect(AppContrast.ratio(Colors.white, Colors.white), 1.0);
    });

    test('ratio between pure black and pure white is the maximum, 21:1', () {
      expect(AppContrast.ratio(Colors.black, Colors.white), closeTo(21, 0.01));
    });

    test('ratio is symmetric regardless of argument order', () {
      expect(
        AppContrast.ratio(Colors.black, Colors.white),
        AppContrast.ratio(Colors.white, Colors.black),
      );
    });

    test('meetsWcagAa is true for black over white', () {
      expect(AppContrast.meetsWcagAa(Colors.black, Colors.white), isTrue);
    });

    test('meetsWcagAa is false for two very similar colors', () {
      expect(
        AppContrast.meetsWcagAa(
          const Color(0xFFAAAAAA),
          const Color(0xFFB0B0B0),
        ),
        isFalse,
      );
    });

    test('relativeLuminance of white is greater than of black', () {
      expect(
        AppContrast.relativeLuminance(Colors.white),
        greaterThan(AppContrast.relativeLuminance(Colors.black)),
      );
    });
  });
}
