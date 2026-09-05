import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../../core/utils/utils.dart';
import '../../../organizations/domain/entities/membership.dart';
import '../../../organizations/domain/repositories/membership_repository.dart';
import '../../../organizations/domain/value_objects/membership_status.dart';
import '../../../organizations/domain/value_objects/system_role_name.dart';
import '../entities/report_definition.dart';
import '../entities/saved_report.dart';
import '../repositories/report_repository.dart';
import '../repositories/saved_report_repository.dart';
import '../services/report_schedule_reference_checker.dart';

/// Resolves the [Capability] required to set a [SavedReport.visibility] to
/// [visibility], or `null` when [SavedReportVisibility.private] — which any
/// active member may always choose, no capability required.
Capability? _shareCapabilityFor(SavedReportVisibility visibility) =>
    switch (visibility) {
      SavedReportVisibility.private => null,
      SavedReportVisibility.team => Capability.reportShareTeam,
      SavedReportVisibility.organization => Capability.reportShareOrganization,
    };

Future<AppResult<Membership>> _resolveActiveMembership(
  MembershipRepository membershipRepository, {
  required String organizationId,
  required String userId,
}) async {
  final result = await membershipRepository.getByUser(
    organizationId: organizationId,
    userId: userId,
  );
  return result.fold(
    onSuccess: (membership) {
      if (membership.status != MembershipStatus.active) {
        return AppFailure<Membership>(
          const PermissionFailure(
            'Usuário não está mais ativo nesta organização.',
            code: 'saved_report_requester_inactive',
          ),
        );
      }
      return AppSuccess<Membership>(membership);
    },
    onFailure: (failure) {
      // A missing Membership denies exactly like an inactive one — never
      // leaks "not found" (which could hint whether an organizationId
      // exists) to a caller who was never a member of it in the first
      // place.
      if (failure is NotFoundFailure) {
        return AppFailure<Membership>(
          const PermissionFailure(
            'Usuário não está ativo nesta organização.',
            code: 'saved_report_requester_inactive',
          ),
        );
      }
      return AppFailure<Membership>(failure);
    },
  );
}

Future<AppResult<void>> _authorizeVisibility(
  PermissionService permissionService, {
  required String organizationId,
  required String userId,
  required SavedReportVisibility visibility,
}) async {
  final capability = _shareCapabilityFor(visibility);
  if (capability == null) return const AppSuccess<void>(null);

  final permissionResult = await permissionService.hasPermission(
    organizationId: organizationId,
    userId: userId,
    capability: capability,
  );
  return permissionResult.fold(
    onSuccess: (allowed) {
      if (allowed) return const AppSuccess<void>(null);
      return AppFailure<void>(
        PermissionFailure(
          visibility == SavedReportVisibility.organization
              ? 'Usuário não pode compartilhar visualizações com toda a organização.'
              : 'Usuário não pode compartilhar visualizações com a equipe.',
          code: 'saved_report_share_denied',
        ),
      );
    },
    onFailure: AppFailure<void>.new,
  );
}

bool _isOwnerOrAdmin(Membership membership) =>
    membership.roleName == SystemRoleName.owner.code ||
    membership.roleName == SystemRoleName.admin.code;

/// Whether [name] (already trimmed) collides, case-insensitively, with an
/// existing name in [existing] — enforcing TASK-145's "nome único por
/// usuário" rule. Best-effort only (a read-then-write, not a transaction): a
/// true race between two concurrent saves from the same user could still
/// both succeed; acceptable for a personal report name, unlike price/stock.
bool _hasDuplicateName(
  List<SavedReport> existing,
  String name, {
  String? excludingId,
}) {
  final normalized = name.trim().toLowerCase();
  return existing.any(
    (report) =>
        report.id != excludingId &&
        report.name.trim().toLowerCase() == normalized,
  );
}

/// Saves the current report builder (TASK-144) `ReportDefinition` as a new
/// [SavedReport] (TASK-145), for one-click re-execution later.
@injectable
final class SaveReportView {
  SaveReportView(
    this._repository,
    this._membershipRepository,
    this._permissionService, [
    Uuid? uuid,
  ]) : _uuid = uuid ?? const Uuid();

  final SavedReportRepository _repository;
  final MembershipRepository _membershipRepository;
  final PermissionService _permissionService;
  final Uuid _uuid;

  Future<AppResult<SavedReport>> call({
    required String organizationId,
    required String companyId,
    required String ownerId,
    required String name,
    required ReportDefinition definition,
    SavedReportVisibility visibility = SavedReportVisibility.private,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return AppFailure<SavedReport>(
        const ValidationFailure(
          'O nome da visualização é obrigatório.',
          fieldErrors: <String, String>{
            'name': 'Informe um nome para a visualização.',
          },
          code: 'saved_report_name_required',
        ),
      );
    }

    final membershipResult = await _resolveActiveMembership(
      _membershipRepository,
      organizationId: organizationId,
      userId: ownerId,
    );
    if (membershipResult is AppFailure<Membership>) {
      return AppFailure<SavedReport>(membershipResult.failure);
    }
    final membership = (membershipResult as AppSuccess<Membership>).value;

    final authorization = await _authorizeVisibility(
      _permissionService,
      organizationId: organizationId,
      userId: ownerId,
      visibility: visibility,
    );
    if (authorization is AppFailure<void>) {
      return AppFailure<SavedReport>(authorization.failure);
    }

    final ownedResult = await _repository.listOwned(
      organizationId: organizationId,
      companyId: companyId,
      userId: ownerId,
    );
    if (ownedResult is AppFailure<List<SavedReport>>) {
      return AppFailure<SavedReport>(ownedResult.failure);
    }
    final owned = (ownedResult as AppSuccess<List<SavedReport>>).value;
    if (_hasDuplicateName(owned, trimmedName)) {
      return AppFailure<SavedReport>(
        const ConflictFailure(
          'Você já tem uma visualização salva com esse nome.',
          code: 'saved_report_duplicate_name',
        ),
      );
    }

    final now = DateTime.now();
    final report = SavedReport(
      id: _uuid.v4(),
      organizationId: organizationId,
      companyId: companyId,
      ownerId: ownerId,
      name: trimmedName,
      definition: definition,
      visibility: visibility,
      sharedWithTeamIds: visibility == SavedReportVisibility.team
          ? membership.teamIds
          : const <String>[],
      favorite: false,
      createdAt: now,
      createdBy: ownerId,
      updatedAt: now,
      updatedBy: ownerId,
    );

    return _repository.create(report);
  }
}

/// Renames, re-shares, favorites or redefines an existing [SavedReport]
/// (TASK-145). Only [SavedReport.ownerId] or an OWNER/ADMIN may call this
/// successfully — anyone else with read access to a shared report only
/// executes/views it, never edits it.
@injectable
final class UpdateSavedReport {
  const UpdateSavedReport(
    this._repository,
    this._membershipRepository,
    this._permissionService,
  );

  final SavedReportRepository _repository;
  final MembershipRepository _membershipRepository;
  final PermissionService _permissionService;

  Future<AppResult<SavedReport>> call({
    required String requesterId,
    required SavedReport current,
    String? name,
    ReportDefinition? definition,
    SavedReportVisibility? visibility,
    bool? favorite,
  }) async {
    final membershipResult = await _resolveActiveMembership(
      _membershipRepository,
      organizationId: current.organizationId,
      userId: requesterId,
    );
    if (membershipResult is AppFailure<Membership>) {
      return AppFailure<SavedReport>(membershipResult.failure);
    }
    final membership = (membershipResult as AppSuccess<Membership>).value;

    final isOwner = current.isOwnedBy(requesterId);
    if (!isOwner && !_isOwnerOrAdmin(membership)) {
      return AppFailure<SavedReport>(
        const PermissionFailure(
          'Apenas o dono ou um administrador podem editar esta visualização.',
          code: 'saved_report_edit_denied',
        ),
      );
    }

    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isEmpty) {
      return AppFailure<SavedReport>(
        const ValidationFailure(
          'O nome da visualização é obrigatório.',
          fieldErrors: <String, String>{
            'name': 'Informe um nome para a visualização.',
          },
          code: 'saved_report_name_required',
        ),
      );
    }

    final nextVisibility = visibility ?? current.visibility;
    if (nextVisibility != current.visibility) {
      final authorization = await _authorizeVisibility(
        _permissionService,
        organizationId: current.organizationId,
        userId: requesterId,
        visibility: nextVisibility,
      );
      if (authorization is AppFailure<void>) {
        return AppFailure<SavedReport>(authorization.failure);
      }
    }

    if (trimmedName != null && trimmedName != current.name) {
      final ownedResult = await _repository.listOwned(
        organizationId: current.organizationId,
        companyId: current.companyId,
        userId: current.ownerId,
      );
      if (ownedResult is AppFailure<List<SavedReport>>) {
        return AppFailure<SavedReport>(ownedResult.failure);
      }
      final owned = (ownedResult as AppSuccess<List<SavedReport>>).value;
      if (_hasDuplicateName(owned, trimmedName, excludingId: current.id)) {
        return AppFailure<SavedReport>(
          const ConflictFailure(
            'Já existe uma visualização salva com esse nome.',
            code: 'saved_report_duplicate_name',
          ),
        );
      }
    }

    // The `sharedWithTeamIds` snapshot only makes sense while `team`-scoped;
    // re-derive it from the *owner's* current Membership (never the
    // requester's, who may be an editing ADMIN, not the owner) whenever
    // visibility is (re)set to `team`.
    List<String> sharedWithTeamIds = current.sharedWithTeamIds;
    if (nextVisibility == SavedReportVisibility.team) {
      final ownerMembershipResult = await _resolveActiveMembership(
        _membershipRepository,
        organizationId: current.organizationId,
        userId: current.ownerId,
      );
      if (ownerMembershipResult is AppFailure<Membership>) {
        return AppFailure<SavedReport>(ownerMembershipResult.failure);
      }
      sharedWithTeamIds =
          (ownerMembershipResult as AppSuccess<Membership>).value.teamIds;
    } else if (nextVisibility != SavedReportVisibility.team) {
      sharedWithTeamIds = const <String>[];
    }

    final updated = current.copyWith(
      name: trimmedName,
      definition: definition,
      visibility: visibility,
      sharedWithTeamIds: sharedWithTeamIds,
      favorite: favorite,
      updatedAt: DateTime.now(),
      updatedBy: requesterId,
      version: current.version + 1,
    );

    return _repository.update(updated);
  }
}

/// Deletes a [SavedReport] (TASK-145). Blocks (rather than silently
/// succeeding) when [ReportScheduleReferenceChecker] reports an active
/// TASK-149 schedule still depends on it.
@injectable
final class DeleteSavedReport {
  const DeleteSavedReport(
    this._repository,
    this._membershipRepository,
    this._scheduleReferenceChecker,
  );

  final SavedReportRepository _repository;
  final MembershipRepository _membershipRepository;
  final ReportScheduleReferenceChecker _scheduleReferenceChecker;

  Future<AppResult<void>> call({
    required String requesterId,
    required SavedReport report,
  }) async {
    final membershipResult = await _resolveActiveMembership(
      _membershipRepository,
      organizationId: report.organizationId,
      userId: requesterId,
    );
    if (membershipResult is AppFailure<Membership>) {
      return AppFailure<void>(membershipResult.failure);
    }
    final membership = (membershipResult as AppSuccess<Membership>).value;

    final isOwner = report.isOwnedBy(requesterId);
    if (!isOwner && !_isOwnerOrAdmin(membership)) {
      return AppFailure<void>(
        const PermissionFailure(
          'Apenas o dono ou um administrador podem excluir esta visualização.',
          code: 'saved_report_delete_denied',
        ),
      );
    }

    final referenceResult = await _scheduleReferenceChecker
        .hasActiveScheduleReferencing(report.id);
    if (referenceResult is AppFailure<bool>) {
      return AppFailure<void>(referenceResult.failure);
    }
    final hasActiveSchedule = (referenceResult as AppSuccess<bool>).value;
    if (hasActiveSchedule) {
      return AppFailure<void>(
        const ConflictFailure(
          'Esta visualização está vinculada a um agendamento ativo e não '
          'pode ser excluída. Cancele o agendamento antes de excluir.',
          code: 'saved_report_has_active_schedule',
        ),
      );
    }

    return _repository.delete(
      organizationId: report.organizationId,
      reportId: report.id,
    );
  }
}

/// Loads a [SavedReport]'s `ReportDefinition` back into the TASK-144 report
/// builder for one-click re-execution (TASK-145's whole point) — reuses the
/// same [ReportDraftRepository] the builder already auto-saves/restores
/// its in-progress definition from, so `ReportBuilderBloc` needs no change
/// at all: opening a [SavedReport] is indistinguishable, from the builder's
/// point of view, from resuming a draft.
///
/// Never persists [SavedReport.id]/[SavedReport.ownerId]/
/// [SavedReport.visibility] anywhere — only the plain [ReportDefinition],
/// which the builder (and `ExecuteReportQuery`) always re-scopes/re-executes
/// under whoever opened it, exactly like TASK-145's RBAC requirement.
@injectable
final class OpenSavedReportInBuilder {
  const OpenSavedReportInBuilder(this._drafts);

  final ReportDraftRepository _drafts;

  Future<void> call({
    required String userId,
    required ReportDefinition definition,
  }) => _drafts.save(userId: userId, definition: definition);
}

/// Owned and shared [SavedReport]s currently visible to one user
/// (TASK-145) — what the "Meus relatórios" / "Compartilhados comigo" lists
/// render.
final class SavedReportsOverview {
  const SavedReportsOverview({required this.owned, required this.shared});

  final List<SavedReport> owned;
  final List<SavedReport> shared;
}

@injectable
final class ListSavedReports {
  const ListSavedReports(this._repository, this._membershipRepository);

  final SavedReportRepository _repository;
  final MembershipRepository _membershipRepository;

  Future<AppResult<SavedReportsOverview>> call({
    required String organizationId,
    required String companyId,
    required String userId,
  }) async {
    final membershipResult = await _resolveActiveMembership(
      _membershipRepository,
      organizationId: organizationId,
      userId: userId,
    );
    if (membershipResult is AppFailure<Membership>) {
      return AppFailure<SavedReportsOverview>(membershipResult.failure);
    }
    final membership = (membershipResult as AppSuccess<Membership>).value;

    final ownedResult = await _repository.listOwned(
      organizationId: organizationId,
      companyId: companyId,
      userId: userId,
    );
    if (ownedResult is AppFailure<List<SavedReport>>) {
      return AppFailure<SavedReportsOverview>(ownedResult.failure);
    }

    final sharedResult = await _repository.listSharedWithMe(
      organizationId: organizationId,
      companyId: companyId,
      userId: userId,
      teamIds: membership.teamIds,
    );
    if (sharedResult is AppFailure<List<SavedReport>>) {
      return AppFailure<SavedReportsOverview>(sharedResult.failure);
    }

    return AppSuccess<SavedReportsOverview>(
      SavedReportsOverview(
        owned: (ownedResult as AppSuccess<List<SavedReport>>).value,
        shared: (sharedResult as AppSuccess<List<SavedReport>>).value,
      ),
    );
  }
}
