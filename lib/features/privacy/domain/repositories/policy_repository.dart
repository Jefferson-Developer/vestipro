import '../../../../core/utils/utils.dart';
import '../entities/policy_document.dart';
import '../entities/user_policy_acceptance.dart';

abstract interface class PolicyRepository {
  Future<AppResult<List<PolicyDocument>>> getCurrentDocuments();

  Future<AppResult<Set<String>>> getAcceptedDocumentIds(String userId);

  Future<AppResult<void>> registerAcceptances(
    List<UserPolicyAcceptance> acceptances,
  );
}
