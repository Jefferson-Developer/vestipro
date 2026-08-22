import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('domain layer does not import UI or infrastructure packages', () {
    final domainDirectory = Directory('lib/features/organizations/domain');
    final forbiddenImports = <String>[
      "import 'package:flutter",
      'import "package:flutter',
      "import 'package:firebase",
      'import "package:firebase',
      "import 'package:cloud_firestore",
      'import "package:cloud_firestore',
      "import 'package:drift",
      'import "package:drift',
      "import 'dart:ui",
      'import "dart:ui',
    ];

    final dartFiles = domainDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('.freezed.dart'));

    for (final file in dartFiles) {
      final content = file.readAsStringSync();

      for (final forbiddenImport in forbiddenImports) {
        expect(
          content.contains(forbiddenImport),
          isFalse,
          reason: '${file.path} imports $forbiddenImport',
        );
      }
    }
  });
}
