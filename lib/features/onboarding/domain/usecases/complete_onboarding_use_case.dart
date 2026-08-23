import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../organizations/domain/entities/organization.dart';
import '../../../organizations/domain/usecases/create_organization_use_case.dart';
import '../entities/onboarding_progress.dart';
import '../validators/onboarding_step_validators.dart';
import '../value_objects/organization_segment.dart';

final RegExp _diacriticPattern = RegExp('[áàâãäåéèêëíìîïóòôõöúùûüçñ]');
final RegExp _nonSlugCharacter = RegExp(r'[^a-z0-9]+');
final RegExp _edgeHyphens = RegExp(r'^-+|-+$');

const String _withDiacritics = 'áàâãäåéèêëíìîïóòôõöúùûüçñ';
const String _withoutDiacritics = 'aaaaaaeeeeiiiiooooouuuucn';

/// Creates the Organization collected by the onboarding wizard (TASK-038),
/// on top of the already-existing [CreateOrganizationUseCase]
/// (TASK-026/TASK-037) — this use case never talks to
/// [OrganizationRepository]/Firestore/Cloud Functions itself, it only
/// derives the two inputs [CreateOrganizationUseCase] needs but the wizard
/// never asks the user for ([id], generated once per submission, and
/// [slug], derived from the organization name) and re-validates the two
/// "hard" required fields (`docs/tasks/TASK-038-*.md`) as defense-in-depth
/// on top of `OnboardingBloc`'s own per-step validation.
@injectable
final class CompleteOnboardingUseCase {
  CompleteOnboardingUseCase(this._createOrganization) : _uuid = const Uuid();

  /// Same as the default constructor, but lets tests substitute [uuid] for
  /// a deterministic id/slug — the default (unnamed) constructor is the one
  /// `injectable` generates a provider for, and it only takes
  /// [_createOrganization], same seam precedent as
  /// `CloudFunctionsService.withDependencies`.
  CompleteOnboardingUseCase.withDependencies(
    this._createOrganization, {
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final CreateOrganizationUseCase _createOrganization;
  final Uuid _uuid;

  Future<AppResult<Organization>> call({
    required OnboardingProgress progress,
    required String createdBy,
  }) async {
    final nameError = validateOrganizationName(progress.organizationName);
    final segmentError = validateOrganizationSegment(progress.segment);

    if (nameError != null || segmentError != null) {
      return AppFailure<Organization>(
        ValidationFailure(
          'Cannot complete onboarding without the required fields.',
          fieldErrors: <String, String>{
            'organizationName': ?nameError,
            'segment': ?segmentError,
          },
          code: 'invalid_onboarding_completion_payload',
        ),
      );
    }

    final id = _uuid.v4();

    return _createOrganization(
      id: id,
      name: progress.organizationName,
      slug: _deriveSlug(progress.organizationName, id),
      currency: progress.currency,
      country: progress.country,
      defaultLanguage: progress.defaultLanguage,
      segment: progress.segment!.code,
      createdBy: createdBy,
    );
  }

  /// A human-readable, URL-safe slug derived from [organizationName], made
  /// unique with the first 8 hex characters of the freshly generated [id] —
  /// `slug` has no server-side uniqueness check yet (see
  /// `CreateOrganizationUseCase`'s own docs), so this is a best-effort
  /// collision guard, not a guarantee.
  String _deriveSlug(String organizationName, String id) {
    final normalized = _stripDiacritics(organizationName.trim().toLowerCase());
    final hyphenated = normalized
        .replaceAll(_nonSlugCharacter, '-')
        .replaceAll(_edgeHyphens, '');
    final base = hyphenated.isEmpty ? 'org' : hyphenated;
    final suffix = id.replaceAll('-', '').substring(0, 8);
    return '$base-$suffix';
  }

  String _stripDiacritics(String value) {
    if (!_diacriticPattern.hasMatch(value)) {
      return value;
    }
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      final index = _withDiacritics.indexOf(char);
      buffer.write(index == -1 ? char : _withoutDiacritics[index]);
    }
    return buffer.toString();
  }
}
