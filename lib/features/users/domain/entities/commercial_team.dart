import '../../../organizations/organizations.dart';

final class CommercialTeam {
  const CommercialTeam({
    required this.team,
    required this.managerName,
    required this.memberNames,
  });

  final Team team;
  final String managerName;
  final List<String> memberNames;

  String get id => team.id;
  String get name => team.name;
  String get managerUserId => team.managerUserId;
  int get memberCount => team.memberIds.length;
}
