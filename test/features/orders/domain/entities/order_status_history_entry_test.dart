import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/orders/orders.dart';

void main() {
  group(
    'OrderStatusHistoryEntry serialization (via OrderStatusHistoryEntryDto)',
    () {
      final now = DateTime.utc(2026, 1, 1, 12);

      test('toJson/fromJson round-trip preserves every field', () {
        final dto = OrderStatusHistoryEntryDto(
          previousStatus: 'draft',
          newStatus: 'pending_sync',
          changedAt: now,
          actorId: 'user-1',
          reason: 'Sincronizado automaticamente',
        );

        final roundTripped = OrderStatusHistoryEntryDto.fromJson(dto.toJson());

        expect(roundTripped.previousStatus, dto.previousStatus);
        expect(roundTripped.newStatus, dto.newStatus);
        // `Timestamp.toDate()` returns a local-time `DateTime` for the same
        // instant, not a UTC-flagged one — `isAtSameMomentAs` is the
        // instant-equality check that ignores that flag, same pitfall every
        // other Firestore-Timestamp-backed DTO in this codebase has.
        expect(roundTripped.changedAt.isAtSameMomentAs(dto.changedAt), isTrue);
        expect(roundTripped.actorId, dto.actorId);
        expect(roundTripped.reason, dto.reason);
      });

      test('toJson/fromJson round-trip preserves a null previousStatus/reason '
          '(the very first history entry has no previous status)', () {
        final dto = OrderStatusHistoryEntryDto(
          newStatus: 'draft',
          changedAt: now,
          actorId: 'user-1',
        );

        final roundTripped = OrderStatusHistoryEntryDto.fromJson(dto.toJson());

        expect(roundTripped.previousStatus, isNull);
        expect(roundTripped.reason, isNull);
        expect(roundTripped.newStatus, dto.newStatus);
      });

      test('fromJson rejects a payload missing newStatus', () {
        expect(
          () => OrderStatusHistoryEntryDto.fromJson(<String, dynamic>{
            'changedAt': Timestamp.fromDate(now),
            'actorId': 'user-1',
          }),
          throwsA(isA<ValidationException>()),
        );
      });

      test('fromJson rejects a payload with a non-Timestamp changedAt', () {
        expect(
          () => OrderStatusHistoryEntryDto.fromJson(<String, dynamic>{
            'newStatus': 'draft',
            'changedAt': now.toIso8601String(),
            'actorId': 'user-1',
          }),
          throwsA(isA<ValidationException>()),
        );
      });

      test(
        'OrderMapper maps every OrderStatus through the entry unchanged',
        () {
          const mapper = OrderMapper();
          for (final previous in [null, ...OrderStatus.values]) {
            for (final next in OrderStatus.values) {
              final entry = OrderStatusHistoryEntry(
                previousStatus: previous,
                newStatus: next,
                changedAt: now,
                actorId: 'user-1',
              );
              final roundTripped = mapper.historyEntryToEntity(
                mapper.historyEntryToDto(entry),
              );
              expect(roundTripped, entry);
            }
          }
        },
      );
    },
  );
}
