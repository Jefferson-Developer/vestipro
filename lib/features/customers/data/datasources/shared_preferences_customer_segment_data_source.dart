import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../dtos/customer_segment_dto.dart';
import 'customer_segment_data_source.dart';

/// Local segment store used until the remote/outbox sync implementation
/// exists, mirroring `SharedPreferencesCustomerRepository`'s approach for
/// the carteira itself.
@LazySingleton(as: CustomerSegmentDataSource)
final class SharedPreferencesCustomerSegmentDataSource
    implements CustomerSegmentDataSource {
  const SharedPreferencesCustomerSegmentDataSource();

  String _keyFor(String organizationId) => 'customer_segments_$organizationId';

  @override
  Future<List<CustomerSegmentDto>> listByOrganization(
    String organizationId,
  ) async {
    return _load(organizationId);
  }

  @override
  Future<void> upsert(CustomerSegmentDto dto) async {
    final segments = await _load(dto.organizationId);
    final next = <CustomerSegmentDto>[
      ...segments.where((existing) => existing.id != dto.id),
      dto,
    ];
    await _save(dto.organizationId, next);
  }

  @override
  Future<void> delete({
    required String organizationId,
    required String id,
  }) async {
    final segments = await _load(organizationId);
    final next = segments
        .where((existing) => existing.id != id)
        .toList(growable: false);
    await _save(organizationId, next);
  }

  Future<List<CustomerSegmentDto>> _load(String organizationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(organizationId));
    if (raw == null) return const <CustomerSegmentDto>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      throw const ValidationException(
        'Invalid local customer segment list.',
        code: 'invalid_customer_segment_local_list',
      );
    }

    return decoded
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ValidationException(
              'Invalid local customer segment payload.',
              code: 'invalid_customer_segment_local_payload',
            );
          }
          return CustomerSegmentDto.fromJson(item);
        })
        .toList(growable: false);
  }

  Future<void> _save(
    String organizationId,
    List<CustomerSegmentDto> segments,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(organizationId),
      jsonEncode(segments.map((dto) => dto.toJson()).toList(growable: false)),
    );
  }
}
