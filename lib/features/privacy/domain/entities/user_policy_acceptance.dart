import 'policy_document.dart';

final class UserPolicyAcceptance {
  const UserPolicyAcceptance({
    required this.userId,
    required this.type,
    required this.version,
    required this.acceptedAt,
    this.device,
  });

  final String userId;
  final PolicyDocumentType type;
  final String version;
  final DateTime acceptedAt;
  final String? device;

  String get id => '${type.code}_$version';
}
