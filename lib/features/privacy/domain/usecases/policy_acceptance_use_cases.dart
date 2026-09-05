import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/policy_document.dart';
import '../entities/user_policy_acceptance.dart';
import '../repositories/policy_repository.dart';

final class PolicyAcceptanceRequirement {
  const PolicyAcceptanceRequirement({
    required this.documents,
    required this.missingDocuments,
  });

  final List<PolicyDocument> documents;
  final List<PolicyDocument> missingDocuments;
  bool get isSatisfied => missingDocuments.isEmpty;
}

final class GetCurrentPolicyDocumentsUseCase {
  const GetCurrentPolicyDocumentsUseCase(this._repository);
  final PolicyRepository _repository;

  Future<AppResult<List<PolicyDocument>>> call() =>
      _repository.getCurrentDocuments();
}

final class EvaluatePolicyAcceptanceUseCase {
  const EvaluatePolicyAcceptanceUseCase(this._repository);
  final PolicyRepository _repository;

  Future<AppResult<PolicyAcceptanceRequirement>> call(String userId) async {
    final documentsResult = await _repository.getCurrentDocuments();
    if (documentsResult case AppFailure<List<PolicyDocument>>(:final failure)) {
      return AppFailure<PolicyAcceptanceRequirement>(failure);
    }
    final documents =
        (documentsResult as AppSuccess<List<PolicyDocument>>).value;
    if (documents.map((document) => document.type).toSet().length !=
        PolicyDocumentType.values.length) {
      return const AppFailure<PolicyAcceptanceRequirement>(
        ValidationFailure(
          'As versões vigentes da política e dos termos não estão disponíveis.',
          code: 'current_policy_documents_incomplete',
        ),
      );
    }

    final acceptedResult = await _repository.getAcceptedDocumentIds(userId);
    if (acceptedResult case AppFailure<Set<String>>(:final failure)) {
      return AppFailure<PolicyAcceptanceRequirement>(failure);
    }
    final accepted = (acceptedResult as AppSuccess<Set<String>>).value;
    return AppSuccess<PolicyAcceptanceRequirement>(
      PolicyAcceptanceRequirement(
        documents: documents,
        missingDocuments: documents
            .where((document) => !accepted.contains(document.id))
            .toList(growable: false),
      ),
    );
  }
}

final class AcceptCurrentPoliciesUseCase {
  const AcceptCurrentPoliciesUseCase(this._repository);
  final PolicyRepository _repository;

  Future<AppResult<void>> call({
    required String userId,
    required List<PolicyDocument> documents,
    required DateTime acceptedAt,
    String? device,
  }) {
    if (userId.trim().isEmpty || documents.isEmpty) {
      return Future<AppResult<void>>.value(
        const AppFailure<void>(
          ValidationFailure(
            'Usuário e documentos vigentes são obrigatórios.',
            code: 'invalid_policy_acceptance',
          ),
        ),
      );
    }
    return _repository.registerAcceptances(
      documents
          .map(
            (document) => UserPolicyAcceptance(
              userId: userId,
              type: document.type,
              version: document.version,
              acceptedAt: acceptedAt.toUtc(),
              device: device,
            ),
          )
          .toList(growable: false),
    );
  }
}
