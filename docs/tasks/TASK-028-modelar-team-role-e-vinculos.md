# TASK-028 — Modelar Team, Role e vínculos de usuário

**Epic:** EPIC-03 — Segurança e Multi-Tenancy
**Status:** ⬜ Pendente
**Depende de:** TASK-026 (Organization modelada) — Team, Role e membros são obrigatoriamente vinculados a uma Organization.

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Modelar as entidades `Team` e `Role`, e o vínculo usuário-organização-role (membership), com os perfis iniciais previstos na seção 3.3 de `tasks.md`: `OWNER`, `ADMIN`, `SALES_MANAGER`, `SALES_REP`, `SALES_ASSISTANT`, `FINANCE`, `READ_ONLY`. Esta modelagem é pré-requisito direto do RBAC (TASK-029) e das Security Rules (TASK-030).

## Escopo técnico

- Criar entidade `Role` com `id`, `organizationId`, `name` (um dos perfis iniciais ou role customizada futura), `isSystemRole` (perfis padrão não podem ser excluídos), campos de auditoria.
- Criar entidade `Team` com `id`, `organizationId`, `name`, `memberIds` (ou subcollection de membros, conforme análise de padrão de consulta), campos de auditoria.
- Criar entidade de vínculo `Membership`/`OrganizationMember` representando o vínculo usuário-organização-role: `id`, `organizationId`, `userId`, `roleId`/`roleName`, `teamIds`, `status` (ativo/inativo), campos de auditoria.
- Seed dos 7 perfis iniciais (`OWNER`, `ADMIN`, `SALES_MANAGER`, `SALES_REP`, `SALES_ASSISTANT`, `FINANCE`, `READ_ONLY`) como roles de sistema, criados automaticamente ao criar uma Organization (integrar com fluxo da TASK-026/TASK-037 sem duplicar lógica).
- Criar contratos de repositório `RoleRepository`, `TeamRepository`, `MembershipRepository` com métodos de criar, listar por organização, obter por usuário e atualizar vínculo (trocar role/adicionar a time).
- Implementar repositórios via Firestore em `organizations/{organizationId}/roles/{roleId}`, `organizations/{organizationId}/teams/{teamId}`, `organizations/{organizationId}/members/{userId}` (conforme seção 20 de `tasks.md`).
- Criar casos de uso: `AssignRoleToUserUseCase`, `CreateTeamUseCase`, `AddUserToTeamUseCase`, `GetUserMembershipUseCase`.

## Regras de negócio e restrições

- O usuário que cria a Organization deve se tornar automaticamente `OWNER` (regra que será exercida na TASK-037, mas a estrutura de dados desta task deve suportar isso sem gambiarra).
- Roles de sistema (`isSystemRole = true`) não podem ser excluídas nem renomeadas por nenhum caso de uso desta task.
- Um usuário só pode ter vínculo (`Membership`) com uma Organization através de um registro explícito — nunca inferir vínculo por outro caminho.
- `Membership.organizationId` é imutável; trocar de organização significa criar um novo vínculo, não editar o existente.
- Nenhuma UI acessa Firestore diretamente — sempre via repositório.
- Esta task modela dados; a validação de permissão de fato (o que cada role pode fazer) é escopo da TASK-029 — aqui não implementar lógica de autorização, apenas a estrutura de dados e CRUD básico dos vínculos.

## Testes obrigatórios

- Teste unitário das entidades `Role`, `Team` e `Membership` (igualdade por valor, imutabilidade de `organizationId`).
- Teste unitário garantindo que os 7 perfis iniciais são criados corretamente e marcados como `isSystemRole`.
- Teste unitário garantindo que uma tentativa de excluir/renomear role de sistema é rejeitada.
- Teste unitário de `AssignRoleToUserUseCase` e `AddUserToTeamUseCase` cobrindo sucesso e usuário/organização inexistente.
- Teste do repositório garantindo que listagens de Team/Role/Membership são sempre escopadas por `organizationId`.

## Critérios de aceite

- Entidades Team, Role e Membership criadas e vinculadas corretamente à Organization.
- Os 7 perfis iniciais existem como roles de sistema, protegidas contra exclusão/renomeação.
- Vínculo usuário-organização-role funcional via casos de uso testados.
- `flutter analyze`, `dart format --set-exit-if-changed .` e `flutter test` sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
