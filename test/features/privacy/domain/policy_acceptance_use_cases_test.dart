import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/privacy/privacy.dart';

void main() {
  final privacyV1 = PolicyDocument(
    type: PolicyDocumentType.privacyPolicy,
    version: '1',
    content: 'Privacidade',
    publishedAt: DateTime.utc(2026),
  );
  final termsV1 = PolicyDocument(
    type: PolicyDocumentType.termsOfUse,
    version: '1',
    content: 'Termos',
    publishedAt: DateTime.utc(2026),
  );

  test('primeiro acesso exige aceite das duas versões vigentes', () async {
    final repository = _FakePolicyRepository(
      documents: <PolicyDocument>[privacyV1, termsV1],
    );
    final result = await EvaluatePolicyAcceptanceUseCase(repository)('user-a');
    expect(
      (result as AppSuccess<PolicyAcceptanceRequirement>)
          .value
          .missingDocuments,
      hasLength(2),
    );
  });

  test('nova versão bloqueia quem aceitou somente a versão anterior', () async {
    final privacyV2 = PolicyDocument(
      type: PolicyDocumentType.privacyPolicy,
      version: '2',
      content: 'Nova privacidade',
      publishedAt: DateTime.utc(2026, 2),
    );
    final repository = _FakePolicyRepository(
      documents: <PolicyDocument>[privacyV2, termsV1],
      acceptedByUser: <String, Set<String>>{
        'user-a': <String>{privacyV1.id, termsV1.id},
      },
    );
    final result = await EvaluatePolicyAcceptanceUseCase(repository)('user-a');
    final requirement =
        (result as AppSuccess<PolicyAcceptanceRequirement>).value;
    expect(requirement.isSatisfied, isFalse);
    expect(requirement.missingDocuments.single.id, privacyV2.id);
  });

  test(
    'registra usuário, tipo, versão, data e dispositivo por documento',
    () async {
      final repository = _FakePolicyRepository(
        documents: <PolicyDocument>[privacyV1, termsV1],
      );
      final acceptedAt = DateTime.utc(2026, 9, 5, 12);
      await AcceptCurrentPoliciesUseCase(repository)(
        userId: 'user-a',
        documents: <PolicyDocument>[privacyV1, termsV1],
        acceptedAt: acceptedAt,
        device: 'android',
      );
      expect(repository.writes, hasLength(2));
      expect(
        repository.writes.every(
          (value) =>
              value.userId == 'user-a' &&
              value.acceptedAt == acceptedAt &&
              value.device == 'android',
        ),
        isTrue,
      );
      expect(
        repository.writes.map((value) => value.version),
        everyElement('1'),
      );
    },
  );

  test('aceite é isolado por usuário, não por organização', () async {
    final repository = _FakePolicyRepository(
      documents: <PolicyDocument>[privacyV1, termsV1],
      acceptedByUser: <String, Set<String>>{
        'user-a': <String>{privacyV1.id, termsV1.id},
      },
    );
    final accepted = await EvaluatePolicyAcceptanceUseCase(repository)(
      'user-a',
    );
    final notAccepted = await EvaluatePolicyAcceptanceUseCase(repository)(
      'user-b',
    );
    expect(
      (accepted as AppSuccess<PolicyAcceptanceRequirement>).value.isSatisfied,
      isTrue,
    );
    expect(
      (notAccepted as AppSuccess<PolicyAcceptanceRequirement>)
          .value
          .isSatisfied,
      isFalse,
    );
  });
}

final class _FakePolicyRepository implements PolicyRepository {
  _FakePolicyRepository({
    required this.documents,
    this.acceptedByUser = const <String, Set<String>>{},
  });
  final List<PolicyDocument> documents;
  final Map<String, Set<String>> acceptedByUser;
  final List<UserPolicyAcceptance> writes = <UserPolicyAcceptance>[];

  @override
  Future<AppResult<List<PolicyDocument>>> getCurrentDocuments() async =>
      AppSuccess<List<PolicyDocument>>(documents);

  @override
  Future<AppResult<Set<String>>> getAcceptedDocumentIds(String userId) async =>
      AppSuccess<Set<String>>(acceptedByUser[userId] ?? <String>{});

  @override
  Future<AppResult<void>> registerAcceptances(
    List<UserPolicyAcceptance> acceptances,
  ) async {
    writes.addAll(acceptances);
    return const AppSuccess<void>(null);
  }
}
