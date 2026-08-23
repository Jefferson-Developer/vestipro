import '../../../organizations/organizations.dart';

sealed class TeamFormEvent {
  const TeamFormEvent();
}

final class TeamFormStarted extends TeamFormEvent {
  const TeamFormStarted({
    required this.organizationId,
    required this.userId,
    this.initialTeam,
  });

  final String organizationId;
  final String userId;
  final Team? initialTeam;
}

final class TeamFormNameChanged extends TeamFormEvent {
  const TeamFormNameChanged(this.name);

  final String name;
}

final class TeamFormManagerSelected extends TeamFormEvent {
  const TeamFormManagerSelected(this.managerUserId);

  final String? managerUserId;
}

final class TeamFormMembersSelected extends TeamFormEvent {
  const TeamFormMembersSelected(this.memberIds);

  final Set<String> memberIds;
}

final class TeamFormSubmitted extends TeamFormEvent {
  const TeamFormSubmitted();
}
