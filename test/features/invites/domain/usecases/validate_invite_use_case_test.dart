import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/invites/invites.dart';

class _MockInviteAcceptanceRepository extends Mock
    implements InviteAcceptanceRepository {}

void main() {
  group('ValidateInviteUseCase', () {
    late _MockInviteAcceptanceRepository repository;
    late ValidateInviteUseCase useCase;

    const preview = InvitePreview(outcome: InviteAcceptanceOutcome.valid);

    setUp(() {
      repository = _MockInviteAcceptanceRepository();
      useCase = ValidateInviteUseCase(repository);
    });

    test('delegates to the repository with a trimmed token', () async {
      when(
        () => repository.validate(token: any(named: 'token')),
      ).thenAnswer((_) async => const AppSuccess<InvitePreview>(preview));

      final result = await useCase.call(token: '  token-123  ');

      expect(result, isA<AppSuccess<InvitePreview>>());
      verify(() => repository.validate(token: 'token-123')).called(1);
    });

    test('returns a ValidationFailure without calling the repository when '
        'the token is blank', () async {
      final result = await useCase.call(token: '   ');

      expect(result, isA<AppFailure<InvitePreview>>());
      expect(
        (result as AppFailure<InvitePreview>).failure,
        isA<ValidationFailure>(),
      );
      verifyNever(() => repository.validate(token: any(named: 'token')));
    });

    test('propagates a technical failure from the repository', () async {
      when(() => repository.validate(token: any(named: 'token'))).thenAnswer(
        (_) async =>
            AppFailure<InvitePreview>(const ConnectivityFailure('Offline.')),
      );

      final result = await useCase.call(token: 'token-123');

      expect(result, isA<AppFailure<InvitePreview>>());
    });
  });
}
