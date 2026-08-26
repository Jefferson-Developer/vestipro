# BACKLOG-001 — Seletor de múltiplas organizações

**Status:** ⬜ Pendente
**Origem:** correção do bug "owner recebe 'sem permissão'" (resolução real de `orgId` pós-login,
TASK-026/TASK-037).

## Contexto

Hoje, `ResolveActiveOrganizationIdUseCase`
(`lib/features/organizations/domain/usecases/resolve_active_organization_id_use_case.dart`) resolve a
organização ativa do usuário logado a partir de `MembershipRepository.listActiveByUser`. Quando o usuário
tem mais de uma Membership ativa (ex.: foi convidado para uma segunda organização), o caso de uso escolhe
deterministicamente a mais antiga (`createdAt` ascendente) e nunca deixa a escolha ambígua — mas também
não existe nenhuma forma de o usuário trocar de organização depois de logado. `MembershipActiveOrganizationGuard`
(`lib/core/navigation/active_organization_guard.dart`) segue o mesmo critério ao se autocurar de um
`:orgId` inválido na URL.

## Objetivo

Implementar um seletor real de organização ativa: UI para listar as organizações que o usuário pertence,
trocar o contexto ativo, e persistir essa escolha entre sessões (em vez de sempre cair na mais antiga).

## Escopo provável

- UI de troca de organização (menu/dropdown no shell principal do app).
- Persistir a organização ativa escolhida (local, por dispositivo) e usá-la como prioridade antes do
  critério "mais antiga" em `ResolveActiveOrganizationIdUseCase`.
- Garantir que toda navegação (`ActiveOrganizationGuard`, `PermissionAuthorizationGuard`) respeita a
  organização escolhida, não apenas a resolvida automaticamente.

## Arquivos prováveis

- `lib/features/organizations/domain/usecases/resolve_active_organization_id_use_case.dart`
- `lib/core/navigation/active_organization_guard.dart`
- `lib/features/authentication/presentation/bloc/login_bloc.dart`
- Um novo widget/página de seleção de organização (a definir).
