import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_size_grid_template_repository.dart';
import 'package:vestipro/features/products/products.dart';

/// TASK-075 — Regression coverage: a missing or otherwise inconsistent
/// commercial [SizeGridSize.orderScore] must fail loudly at the data layer,
/// never be silently guessed from alphabetical label order.
void main() {
  group('SharedPreferencesSizeGridTemplateRepository — orderScore integrity', () {
    late SharedPreferencesSizeGridTemplateRepository repository;

    setUp(() {
      repository = const SharedPreferencesSizeGridTemplateRepository();
    });

    test(
      'listByOrganization fails explicitly when a stored size is missing orderScore',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'size_grid_templates_org-1': jsonEncode(<Map<String, dynamic>>[
            _templateJson(
              sizes: <Map<String, dynamic>>[
                _sizeJson(id: 'size-p', label: 'P', orderScore: 1),
                // Missing 'orderScore' entirely — must never fall back to
                // alphabetical order for this size.
                <String, dynamic>{
                  'id': 'size-m',
                  'organizationId': 'org-1',
                  'label': 'M',
                },
              ],
            ),
          ]),
        });

        final result = await repository.listByOrganization('org-1');

        expect(result, isA<AppFailure<List<SizeGridTemplate>>>());
        final failure = (result as AppFailure<List<SizeGridTemplate>>).failure;
        expect(failure, isA<UnexpectedFailure>());
        expect(
          failure.cause,
          isA<ValidationException>().having(
            (exception) => exception.code,
            'code',
            'invalid_size_grid_template_local_payload',
          ),
        );
      },
    );

    test(
      'getById fails explicitly when a stored size has a non-integer orderScore',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'size_grid_templates_org-1': jsonEncode(<Map<String, dynamic>>[
            _templateJson(
              sizes: <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 'size-p',
                  'organizationId': 'org-1',
                  'label': 'P',
                  // Inconsistent type for orderScore: must fail, never be
                  // coerced or guessed.
                  'orderScore': 'first',
                },
              ],
            ),
          ]),
        });

        final result = await repository.getById(
          organizationId: 'org-1',
          id: 'template-1',
        );

        expect(result, isA<AppFailure<SizeGridTemplate>>());
        final failure = (result as AppFailure<SizeGridTemplate>).failure;
        expect(failure, isA<UnexpectedFailure>());
        expect(
          failure.cause,
          isA<ValidationException>().having(
            (exception) => exception.code,
            'code',
            'invalid_size_grid_template_local_payload',
          ),
        );
      },
    );
  });
}

Map<String, dynamic> _templateJson({
  required List<Map<String, dynamic>> sizes,
}) {
  return <String, dynamic>{
    'id': 'template-1',
    'organizationId': 'org-1',
    'name': 'Grade',
    'sizes': sizes,
    'createdAt': '2026-01-01T00:00:00.000Z',
    'createdBy': 'user-1',
    'updatedAt': '2026-01-01T00:00:00.000Z',
    'updatedBy': 'user-1',
    'version': 1,
    'syncStatus': 'pending',
  };
}

Map<String, dynamic> _sizeJson({
  required String id,
  required String label,
  required int orderScore,
}) {
  return <String, dynamic>{
    'id': id,
    'organizationId': 'org-1',
    'label': label,
    'orderScore': orderScore,
  };
}
