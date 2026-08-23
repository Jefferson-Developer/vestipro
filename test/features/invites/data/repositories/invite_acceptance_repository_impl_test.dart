import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/invites/data/datasources/invite_acceptance_data_source.dart';
import 'package:vestipro/features/invites/data/dtos/accepted_invite_dto.dart';
import 'package:vestipro/features/invites/data/dtos/invite_preview_dto.dart';
import 'package:vestipro/features/invites/data/mappers/invite_acceptance_mapper.dart';
import 'package:vestipro/features/invites/data/mappers/invite_mapper.dart';
import 'package:vestipro/features/invites/data/repositories/invite_acceptance_repository_impl.dart';
import 'package:vestipro/features/invites/domain/entities/accepted_invite.dart';
import 'package:vestipro/features/invites/domain/entities/invite_preview.dart';
import 'package:vestipro/features/invites/domain/value_objects/invite_acceptance_outcome.dart';

class _MockInviteAcceptanceDataSource extends Mock
    implements InviteAcceptanceDataSource {}

void main() {
  group('InviteAcceptanceRepositoryImpl', () {
    late _MockInviteAcceptanceDataSource dataSource;
    late InviteAcceptanceRepositoryImpl repository;

    setUp(() {
      dataSource = _MockInviteAcceptanceDataSource();
      repository = InviteAcceptanceRepositoryImpl(
        dataSource: dataSource,
        mapper: InviteAcceptanceMapper(const InviteMapper()),
      );
    });

    group('validate', () {
      test('returns AppSuccess with the mapped preview', () async {
        when(
          () => dataSource.validate(token: any(named: 'token')),
        ).thenAnswer((_) async => const InvitePreviewDto(outcome: 'valid'));

        final result = await repository.validate(token: 'token-1');

        expect(result, isA<AppSuccess<InvitePreview>>());
        expect(
          (result as AppSuccess<InvitePreview>).value.outcome.code,
          'valid',
        );
      });

      test(
        'maps an AppException from the data source into an AppFailure',
        () async {
          when(
            () => dataSource.validate(token: any(named: 'token')),
          ).thenThrow(const UnauthorizedException('Not signed in.'));

          final result = await repository.validate(token: 'token-1');

          expect(result, isA<AppFailure<InvitePreview>>());
        },
      );

      test('wraps any other exception as UnexpectedFailure', () async {
        when(
          () => dataSource.validate(token: any(named: 'token')),
        ).thenThrow(Exception('boom'));

        final result = await repository.validate(token: 'token-1');

        expect(result, isA<AppFailure<InvitePreview>>());
        expect(
          (result as AppFailure<InvitePreview>).failure,
          isA<UnexpectedFailure>(),
        );
      });
    });

    group('accept', () {
      test('returns AppSuccess with the mapped accepted invite', () async {
        when(() => dataSource.accept(token: any(named: 'token'))).thenAnswer(
          (_) async => const AcceptedInviteDto(
            organizationId: 'org-1',
            organizationName: 'Grupo Fashion XPTO',
            roleName: 'SALES_REP',
          ),
        );

        final result = await repository.accept(token: 'token-1');

        expect(result, isA<AppSuccess<AcceptedInvite>>());
        expect(
          (result as AppSuccess<AcceptedInvite>).value.organizationId,
          'org-1',
        );
      });

      test(
        'maps an AppException from the data source into an AppFailure',
        () async {
          when(
            () => dataSource.accept(token: any(named: 'token')),
          ).thenThrow(const UnauthorizedException('Not signed in.'));

          final result = await repository.accept(token: 'token-1');

          expect(result, isA<AppFailure<AcceptedInvite>>());
        },
      );
    });
  });
}
