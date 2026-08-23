import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/invites/invites.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockInviteRepository extends Mock implements InviteRepository {}

void main() {
  final pendingInvite = Invite(
    id: 'invite-1',
    organizationId: 'org-1',
    email: 'novo@vestipro.com.br',
    roleName: SystemRoleName.salesRep,
    status: InviteStatus.pending,
    invitedByUserId: 'admin-1',
    invitedByName: 'Admin',
    expiresAt: DateTime.utc(2026, 1, 8),
    createdAt: DateTime.utc(2026, 1, 1),
    createdBy: 'admin-1',
    updatedAt: DateTime.utc(2026, 1, 1),
    updatedBy: 'admin-1',
  );

  late _MockInviteRepository inviteRepository;

  InviteListBloc buildBloc() {
    return InviteListBloc(
      listPendingInvites: ListPendingInvitesUseCase(inviteRepository),
      resendInvite: ResendInviteUseCase(inviteRepository),
      revokeInvite: RevokeInviteUseCase(inviteRepository),
    );
  }

  setUp(() {
    inviteRepository = _MockInviteRepository();
  });

  group('InviteListBloc — started', () {
    blocTest<InviteListBloc, InviteListState>(
      'loads and exposes the pending invites',
      build: buildBloc,
      setUp: () {
        when(
          () => inviteRepository.listPending('org-1'),
        ).thenAnswer((_) async => AppSuccess<List<Invite>>([pendingInvite]));
      },
      act: (bloc) => bloc.add(const InviteListEvent.started('org-1')),
      expect: () => <InviteListState>[
        const InviteListState(
          loadStatus: InviteListLoadStatus.loading,
          organizationId: 'org-1',
        ),
        InviteListState(
          loadStatus: InviteListLoadStatus.ready,
          organizationId: 'org-1',
          invites: [pendingInvite],
        ),
      ],
    );

    blocTest<InviteListBloc, InviteListState>(
      'reports a load failure without swallowing it into an empty list',
      build: buildBloc,
      setUp: () {
        when(() => inviteRepository.listPending('org-1')).thenAnswer(
          (_) async =>
              AppFailure<List<Invite>>(const ConnectivityFailure('Offline.')),
        );
      },
      act: (bloc) => bloc.add(const InviteListEvent.started('org-1')),
      expect: () => <InviteListState>[
        const InviteListState(
          loadStatus: InviteListLoadStatus.loading,
          organizationId: 'org-1',
        ),
        const InviteListState(
          loadStatus: InviteListLoadStatus.failure,
          organizationId: 'org-1',
          loadFailure: ConnectivityFailure('Offline.'),
        ),
      ],
    );
  });

  group('InviteListBloc — resendRequested', () {
    blocTest<InviteListBloc, InviteListState>(
      'marks the invite as processing, then reloads the list on success',
      build: buildBloc,
      seed: () => InviteListState(
        loadStatus: InviteListLoadStatus.ready,
        organizationId: 'org-1',
        invites: [pendingInvite],
      ),
      setUp: () {
        when(
          () => inviteRepository.resend(
            organizationId: 'org-1',
            inviteId: 'invite-1',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<IssuedInvite>(
            IssuedInvite(invite: pendingInvite, token: 'new-token'),
          ),
        );
        when(
          () => inviteRepository.listPending('org-1'),
        ).thenAnswer((_) async => AppSuccess<List<Invite>>([pendingInvite]));
      },
      act: (bloc) =>
          bloc.add(const InviteListEvent.resendRequested('invite-1')),
      expect: () => <InviteListState>[
        InviteListState(
          loadStatus: InviteListLoadStatus.ready,
          organizationId: 'org-1',
          invites: [pendingInvite],
          processingInviteId: 'invite-1',
        ),
        InviteListState(
          loadStatus: InviteListLoadStatus.ready,
          organizationId: 'org-1',
          invites: [pendingInvite],
          lastResendResult: IssuedInvite(
            invite: pendingInvite,
            token: 'new-token',
          ),
        ),
        // The subsequent reload's own emit is deduped by Bloc itself: its
        // content (loadStatus/invites/loadFailure) is identical to the
        // state right above, since the mocked reload returns the exact
        // same list — so only 2 states are actually observed, not 3.
      ],
    );

    blocTest<InviteListBloc, InviteListState>(
      'reports an action failure (e.g. already-accepted invite) and stops '
      'processing without touching the list',
      build: buildBloc,
      seed: () => InviteListState(
        loadStatus: InviteListLoadStatus.ready,
        organizationId: 'org-1',
        invites: [pendingInvite],
      ),
      setUp: () {
        when(
          () => inviteRepository.resend(
            organizationId: 'org-1',
            inviteId: 'invite-1',
          ),
        ).thenAnswer(
          (_) async => AppFailure<IssuedInvite>(
            const ConflictFailure('Already accepted.'),
          ),
        );
      },
      act: (bloc) =>
          bloc.add(const InviteListEvent.resendRequested('invite-1')),
      expect: () => <InviteListState>[
        InviteListState(
          loadStatus: InviteListLoadStatus.ready,
          organizationId: 'org-1',
          invites: [pendingInvite],
          processingInviteId: 'invite-1',
        ),
        InviteListState(
          loadStatus: InviteListLoadStatus.ready,
          organizationId: 'org-1',
          invites: [pendingInvite],
          actionFailure: const ConflictFailure('Already accepted.'),
        ),
      ],
      verify: (_) {
        verifyNever(() => inviteRepository.listPending(any()));
      },
    );
  });

  group('InviteListBloc — revokeRequested', () {
    blocTest<InviteListBloc, InviteListState>(
      'marks the invite as processing, then reloads the list on success',
      build: buildBloc,
      seed: () => InviteListState(
        loadStatus: InviteListLoadStatus.ready,
        organizationId: 'org-1',
        invites: [pendingInvite],
      ),
      setUp: () {
        when(
          () => inviteRepository.revoke(
            organizationId: 'org-1',
            inviteId: 'invite-1',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Invite>(
            pendingInvite.copyWith(status: InviteStatus.revoked),
          ),
        );
        when(
          () => inviteRepository.listPending('org-1'),
        ).thenAnswer((_) async => const AppSuccess<List<Invite>>([]));
      },
      act: (bloc) =>
          bloc.add(const InviteListEvent.revokeRequested('invite-1')),
      expect: () => <InviteListState>[
        InviteListState(
          loadStatus: InviteListLoadStatus.ready,
          organizationId: 'org-1',
          invites: [pendingInvite],
          processingInviteId: 'invite-1',
        ),
        InviteListState(
          loadStatus: InviteListLoadStatus.ready,
          organizationId: 'org-1',
          invites: [pendingInvite],
        ),
        const InviteListState(
          loadStatus: InviteListLoadStatus.ready,
          organizationId: 'org-1',
          invites: [],
        ),
      ],
    );
  });
}
