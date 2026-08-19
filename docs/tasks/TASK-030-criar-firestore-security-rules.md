# TASK-030 — Criar Firestore Security Rules

**Epic:** EPIC-03 — Segurança e Multi-Tenancy
**Status:** ⬜ Pendente
**Depende de:** TASK-026 (Organization), TASK-027 (Company/Branch), TASK-028 (Team/Role/Membership), TASK-029 (RBAC) — as regras validam exatamente essas entidades e a matriz de permissões.

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Criar as Firestore Security Rules que impedem qualquer leitura/escrita cross-tenant no VestiPro, validando sempre o vínculo real do usuário autenticado com a Organization — nunca confiando no `organizationId` enviado pelo cliente como única fonte de autorização (regra central da seção 13 de `tasks.md`). Escrever testes positivos e negativos no Firebase Emulator Suite para cada coleção coberta.

## Escopo técnico

- Escrever `firestore.rules` cobrindo, no mínimo, as coleções já modeladas até aqui: `organizations/{organizationId}`, `organizations/{organizationId}/companies/{companyId}`, `organizations/{organizationId}/branches/{branchId}`, `organizations/{organizationId}/members/{userId}`, `organizations/{organizationId}/teams/{teamId}`, `organizations/{organizationId}/roles/{roleId}` (conforme seção 20 de `tasks.md`).
- Criar função reutilizável nas regras (ex.: `isMemberOfOrganization(organizationId)`, `hasRole(organizationId, allowedRoles)`) que consulta o documento de membership real do usuário autenticado (`request.auth.uid`) em `organizations/{organizationId}/members/{userId}` — nunca aceitar um campo `organizationId` do próprio documento sendo escrito como prova de pertencimento.
- Bloquear leitura/escrita quando o usuário não autenticado, quando não houver membership ativo na organização, ou quando a role não tiver a capability equivalente definida na TASK-029.
- Impedir alteração de campos imutáveis via regra (ex.: `organizationId`, `companyId` não podem mudar em updates).
- Proteger roles de sistema (`isSystemRole = true`) contra exclusão/alteração de nome via regra, espelhando a restrição de domínio da TASK-028.
- Configurar `firebase.json`/scripts para rodar `firebase emulators:exec` com os testes de regras usando `@firebase/rules-unit-testing`.

## Regras de negócio e restrições

- Nunca permitir que `organizationId` enviado pelo cliente seja a única fonte de autorização — a regra deve sempre re-verificar o vínculo real do usuário autenticado no próprio Firestore.
- Nenhuma leitura cross-tenant deve ser possível mesmo que o cliente tente adivinhar/forjar um `organizationId` diferente do seu.
- Regras devem negar por padrão (deny by default) e conceder explicitamente apenas os casos previstos.
- Alterações administrativas sensíveis (mudança de role, exclusão) devem exigir role com a capability correspondente, não apenas "estar autenticado".
- Regras devem ser escritas pensando em custo de leitura (evitar `get()`/`exists()` excessivos e redundantes nas mesmas regras).

## Testes obrigatórios

- Teste positivo: usuário membro de uma organização consegue ler/escrever documentos dessa mesma organização conforme sua role.
- Teste negativo: usuário membro da Organization A não consegue ler nem escrever documentos da Organization B (teste cross-tenant explícito para cada coleção coberta).
- Teste negativo: usuário não autenticado não acessa nenhuma coleção.
- Teste negativo: usuário tenta forjar `organizationId` no payload de escrita para uma organização à qual não pertence — deve ser negado.
- Teste negativo: usuário com role sem a capability necessária (ex.: `SALES_REP` tentando excluir Company) é negado.
- Teste negativo: tentativa de excluir/renomear role de sistema é negada.
- Todos os testes executados via `firebase emulators:exec "..."` com `@firebase/rules-unit-testing`.

## Critérios de aceite

- `firestore.rules` cobre todas as coleções modeladas até esta task, com deny by default.
- Testes positivos e negativos (incluindo cross-tenant explícito) passam no Firebase Emulator Suite.
- Nenhuma regra confia em campo `organizationId` do próprio payload sem re-verificação contra o membership real do usuário.
- Documentação da estratégia de regras atualizada (quais funções auxiliares existem e o que cada uma garante).

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
