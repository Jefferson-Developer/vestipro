import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/settings/data/dtos/about_app_dto.dart';
import 'package:vestipro/features/settings/data/mappers/about_app_mapper.dart';

void main() {
  group('AboutAppMapper', () {
    test('maps DTO to immutable domain entity', () {
      const mapper = AboutAppMapper();
      const dto = AboutAppDto(
        name: 'VestiPro Dev',
        version: '1.2.3+4',
        environmentLabel: 'development',
        updatedAtIso: '2026-08-20T00:00:00.000Z',
      );

      final entity = mapper.toEntity(dto);

      expect(entity.name, 'VestiPro Dev');
      expect(entity.version.displayValue, '1.2.3+4');
      expect(entity.environmentLabel, 'development');
      expect(entity.updatedAt, DateTime.parse('2026-08-20T00:00:00.000Z'));
    });
  });
}
