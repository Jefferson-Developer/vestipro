import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/onboarding/domain/entities/onboarding_progress.dart';
import 'package:vestipro/features/onboarding/domain/usecases/complete_onboarding_use_case.dart';
import 'package:vestipro/features/onboarding/domain/value_objects/organization_segment.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockUuid extends Mock implements Uuid {}

void main() {
  group('CompleteOnboardingUseCase', () {
    late _MockOrganizationRepository organizationRepository;
    late CreateOrganizationUseCase createOrganization;

    final organization = Organization(
      id: '11112222333344445555666677778888',
      name: 'Grupo Fashion XPTO',
      slug: 'grupo-fashion-xpto-11112222',
      settings: const OrganizationSettings(
        currency: 'BRL',
        country: 'BR',
        defaultLanguage: 'pt-BR',
        segment: 'apparel',
      ),
      status: OrganizationStatus.active,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'user-1',
      updatedAt: DateTime.utc(2026, 1, 1),
      updatedBy: 'user-1',
    );

    setUp(() {
      organizationRepository = _MockOrganizationRepository();
      createOrganization = CreateOrganizationUseCase(organizationRepository);
    });

    setUpAll(() {
      registerFallbackValue(
        const OrganizationSettings(
          currency: 'BRL',
          country: 'BR',
          defaultLanguage: 'pt-BR',
        ),
      );
    });

    test('derives an id/slug from the generated uuid and forwards every '
        'collected field to CreateOrganizationUseCase', () async {
      when(
        () => organizationRepository.create(
          id: any(named: 'id'),
          name: any(named: 'name'),
          slug: any(named: 'slug'),
          settings: any(named: 'settings'),
          createdBy: any(named: 'createdBy'),
        ),
      ).thenAnswer((_) async => AppSuccess<Organization>(organization));

      final uuid = _MockUuid();
      when(() => uuid.v4()).thenReturn('11112222-3333-4444-5555-666677778888');
      final useCase = CompleteOnboardingUseCase.withDependencies(
        createOrganization,
        uuid: uuid,
      );

      const progress = OnboardingProgress(
        organizationName: 'Grupo Fashion XPTO',
        segment: OrganizationSegment.apparel,
        currency: 'BRL',
        country: 'BR',
        defaultLanguage: 'pt-BR',
      );

      final result = await useCase(progress: progress, createdBy: 'user-1');

      expect(result, isA<AppSuccess<Organization>>());
      verify(
        () => organizationRepository.create(
          id: '11112222-3333-4444-5555-666677778888',
          name: 'Grupo Fashion XPTO',
          slug: 'grupo-fashion-xpto-11112222',
          settings: const OrganizationSettings(
            currency: 'BRL',
            country: 'BR',
            defaultLanguage: 'pt-BR',
            segment: 'apparel',
          ),
          createdBy: 'user-1',
        ),
      ).called(1);
    });

    test('strips diacritics/special characters from the name when deriving '
        'the slug', () async {
      when(
        () => organizationRepository.create(
          id: any(named: 'id'),
          name: any(named: 'name'),
          slug: any(named: 'slug'),
          settings: any(named: 'settings'),
          createdBy: any(named: 'createdBy'),
        ),
      ).thenAnswer((_) async => AppSuccess<Organization>(organization));

      final uuid = _MockUuid();
      when(() => uuid.v4()).thenReturn('aaaa1111-bbbb-2222-cccc-333344445555');
      final useCase = CompleteOnboardingUseCase.withDependencies(
        createOrganization,
        uuid: uuid,
      );

      const progress = OnboardingProgress(
        organizationName: 'Confecção São José & Cia.',
        segment: OrganizationSegment.multiBrand,
      );

      await useCase(progress: progress, createdBy: 'user-1');

      final captured =
          verify(
                () => organizationRepository.create(
                  id: any(named: 'id'),
                  name: any(named: 'name'),
                  slug: captureAny(named: 'slug'),
                  settings: any(named: 'settings'),
                  createdBy: any(named: 'createdBy'),
                ),
              ).captured.single
              as String;

      expect(captured, 'confeccao-sao-jose-cia-aaaa1111');
    });

    test('returns a ValidationFailure without calling the repository when the '
        'organization name is blank', () async {
      final useCase = CompleteOnboardingUseCase.withDependencies(
        createOrganization,
      );

      const progress = OnboardingProgress(
        organizationName: '  ',
        segment: OrganizationSegment.apparel,
      );

      final result = await useCase(progress: progress, createdBy: 'user-1');

      expect(result, isA<AppFailure<Organization>>());
      final failure = (result as AppFailure<Organization>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors.containsKey(
          'organizationName',
        ),
        isTrue,
      );
      verifyNever(
        () => organizationRepository.create(
          id: any(named: 'id'),
          name: any(named: 'name'),
          slug: any(named: 'slug'),
          settings: any(named: 'settings'),
          createdBy: any(named: 'createdBy'),
        ),
      );
    });

    test('returns a ValidationFailure without calling the repository when no '
        'segment was selected', () async {
      final useCase = CompleteOnboardingUseCase.withDependencies(
        createOrganization,
      );

      const progress = OnboardingProgress(
        organizationName: 'Grupo Fashion XPTO',
      );

      final result = await useCase(progress: progress, createdBy: 'user-1');

      expect(result, isA<AppFailure<Organization>>());
      final failure = (result as AppFailure<Organization>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors.containsKey('segment'),
        isTrue,
      );
      verifyNever(
        () => organizationRepository.create(
          id: any(named: 'id'),
          name: any(named: 'name'),
          slug: any(named: 'slug'),
          settings: any(named: 'settings'),
          createdBy: any(named: 'createdBy'),
        ),
      );
    });

    test('propagates a network failure from the repository', () async {
      when(
        () => organizationRepository.create(
          id: any(named: 'id'),
          name: any(named: 'name'),
          slug: any(named: 'slug'),
          settings: any(named: 'settings'),
          createdBy: any(named: 'createdBy'),
        ),
      ).thenAnswer(
        (_) async => AppFailure<Organization>(
          const ConnectivityFailure('No connection.'),
        ),
      );

      final useCase = CompleteOnboardingUseCase.withDependencies(
        createOrganization,
      );

      const progress = OnboardingProgress(
        organizationName: 'Grupo Fashion XPTO',
        segment: OrganizationSegment.apparel,
      );

      final result = await useCase(progress: progress, createdBy: 'user-1');

      expect(result, isA<AppFailure<Organization>>());
      expect(
        (result as AppFailure<Organization>).failure,
        isA<ConnectivityFailure>(),
      );
    });
  });
}
