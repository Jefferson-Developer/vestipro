# TASK-029 — Implementar RBAC

**Epic:** EPIC-03 — Segurança e Multi-Tenancy
**Status:** ⬜ Pendente
**Depende de:** TASK-026 (Organization), TASK-027 (Company/Branch), TASK-028 (Team/Role/Membership) — a matriz de permissões opera sobre essas entidades.

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Implementar o RBAC (Role-Based Access Control) configurável do VestiPro: uma matriz de permissões por role, validada em duas camadas (UI oculta/desabilita ações; backend via Rules/Functions valida de verdade), e um serviço `PermissionService`/`AuthorizationGuard` reutilizável por toda a aplicação. Esta task é pré-requisito para praticamente todas as telas administrativas do backlog (TASK-042 em diante).

## Escopo técnico

- Definir matriz de permissões (capabilities) por role — ex.: `customer.create`, `customer.delete`, `order.approve`, `user.changeRole`, `discount.approveAboveLimit`, `report.export` — cobrindo no mínimo as ações administrativas sensíveis previstas em `tasks.md` (alteração de role, exclusão, aprovação, configuração).
- Modelar a matriz como dado configurável (não hardcoded em `if/else` espalhado), por role de sistema (`OWNER`, `ADMIN`, `SALES_MANAGER`, `SALES_REP`, `SALES_ASSISTANT`, `FINANCE`, `READ_ONLY`), com estrutura que permita evolução futura para roles customizadas.
- Criar `PermissionService` (camada `core/permissions/`) com API do tipo `hasPermission(capability)` e `hasAnyPermission(List<capability>)`, resolvendo a partir do `Membership`/role ativo do usuário na organização corrente.
- Criar `AuthorizationGuard` reutilizável para rotas (`go_router`) e para ações de UI (ex.: `PermissionBuilder`/`can(capability)` widget helper) que oculta/desabilita a ação quando o usuário não tem a permissão.
- Documentar explicitamente que a camada de UI (ocultar/desabilitar) nunca substitui a validação real no backend — toda ação administrativa sensível deve também ser validada em Cloud Function/Firestore Security Rules (a criação dessas regras é escopo da TASK-030, mas esta task deve deixar claro o contrato esperado: qual capability corresponde a qual regra).
- Integrar o `PermissionService` como dependência injetável (`get_it`/`injectable`), sem uso de GetIt direto espalhado pela regra de negócio.

## Regras de negócio e restrições

- Nunca considerar uma ação "autorizada" apenas porque a UI a exibiu — todo caso de uso sensível deve consultar `PermissionService` antes de executar, e o backend deve validar novamente de forma independente.
- A matriz de permissões deve ser auditável: dado um role, deve ser possível listar exatamente quais capabilities ele possui.
- `READ_ONLY` nunca deve ter nenhuma capability de escrita/exclusão/aprovação.
- `OWNER` deve ter superset de permissões de `ADMIN` (ou explicitamente todas as capabilities), nunca menos.
- Mudança de role de um usuário deve refletir imediatamente nas permissões resolvidas pelo `PermissionService` (nunca cache indefinido sem invalidação).

## Testes obrigatórios

- Teste unitário da matriz de permissões cobrindo cada role de sistema e um conjunto representativo de capabilities (positivo e negativo).
- Teste unitário do `PermissionService.hasPermission`/`hasAnyPermission` cobrindo usuário sem membership, membership com role inválida e role válida.
- Teste unitário garantindo que `READ_ONLY` nunca retorna `true` para nenhuma capability de escrita.
- Teste de integração leve garantindo que o `AuthorizationGuard` bloqueia navegação/ação de UI para capability não concedida.
- Teste garantindo que troca de role invalida qualquer cache de permissão anterior do usuário.

## Critérios de aceite

- Matriz de permissões configurável por role implementada e testada para os 7 perfis iniciais.
- `PermissionService`/`AuthorizationGuard` disponível como dependência reutilizável em toda a aplicação, sem lógica de autorização duplicada em telas.
- Documentação clara de que UI e backend validam permissão de forma independente (dupla camada).
- `flutter analyze`, `dart format --set-exit-if-changed .` e `flutter test` sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
