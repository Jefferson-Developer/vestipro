# TASK-033 — Implementar auditoria administrativa (audit log central)

**Epic:** EPIC-03 — Segurança e Multi-Tenancy
**Status:** ⬜ Pendente
**Depende de:** TASK-026 (Organization modelada), TASK-029 (RBAC implementado) — o audit log registra ações administrativas realizadas dentro de uma organização e vinculadas a capabilities do RBAC.

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Implementar a coleção central `auditLogs` (seção 20 de `tasks.md`) para registrar toda ação administrativa sensível do VestiPro — mudança de role, exclusão, alteração de configuração — com ator, ação, entidade afetada, timestamp e organização, garantindo que o log seja imutável (nunca editável/deletável pela própria aplicação), conforme exigido na seção 13 e nas tasks VESTI-030/VESTI-047 de `tasks.md`.

## Escopo técnico

- Criar entidade de domínio `AuditLogEntry` com campos: `id`, `organizationId`, `actorUserId`, `actorName` (snapshot no momento do evento), `action` (enum/string padronizada, ex.: `role.changed`, `user.deactivated`, `company.deleted`, `settings.updated`), `entityType`, `entityId`, `previousValue`/`newValue` (quando aplicável e sem dado sensível demais), `timestamp` (preenchido no backend).
- Criar contrato de repositório `AuditLogRepository` com método `record(entry)` e métodos de leitura paginada por organização/período/tipo de ação (sem método de update/delete expostos no contrato).
- Implementar o registro de auditoria preferencialmente a partir de Cloud Functions (trigger em escrita de coleções sensíveis, ou chamada explícita a partir de Functions que já processam a ação administrativa) para não depender só do cliente — quando o registro for feito client-side como fallback, documentar essa limitação e o plano de migração para Function.
- Persistir em `organizations/{organizationId}/auditLogs/{logId}` (conforme modelo do Firestore da seção 20).
- Criar um pequeno "catálogo" de ações auditáveis padronizadas (constantes, não strings mágicas) reutilizado por todas as features que gerarem log (troca de role da TASK-029/043, exclusão de usuário/empresa, mudanças de configuração sensíveis).
- Integrar Firestore Security Rules para tornar a coleção `auditLogs` append-only: permitir `create` para atores autorizados e negar completamente `update`/`delete` para qualquer usuário (validar em conjunto com a TASK-030, já concluída ou em paralelo).

## Regras de negócio e restrições

- O audit log é imutável: nenhuma regra de negócio, Cloud Function ou UI pode editar ou excluir uma entrada já criada.
- Toda ação administrativa sensível (troca de role, exclusão de usuário/empresa/branch, alteração de configuração de organização) deve gerar uma entrada de auditoria — nenhuma dessas ações pode "passar em silêncio".
- O log deve registrar quem executou a ação (ator real, nunca "sistema" genérico quando houver um usuário identificável).
- Dados sensíveis (senhas, tokens, dados pessoais desnecessários) nunca devem ser armazenados no log.
- A leitura do audit log deve respeitar RBAC (apenas roles com a capability correspondente, ex.: `ADMIN`/`OWNER`, podem visualizar).

## Testes obrigatórios

- Teste unitário da entidade `AuditLogEntry` (campos obrigatórios, imutabilidade).
- Teste unitário do caso de uso que registra uma ação sensível (ex.: troca de role) garantindo que uma entrada de auditoria é criada com os dados corretos.
- Teste de Firestore Security Rules (Emulator Suite) garantindo que `create` é permitido para o ator autorizado e que `update`/`delete` são sempre negados, mesmo para `OWNER`/`ADMIN`.
- Teste garantindo que leitura do audit log respeita RBAC (usuário sem capability não lista entradas).
- Teste garantindo que nenhum dado sensível (ex.: senha, token) é gravado na entrada de log em cenários simulados.

## Critérios de aceite

- Coleção `auditLogs` implementada, populada nas ações administrativas sensíveis já existentes até esta task (ex.: troca de role da TASK-028/029).
- Regras Firestore tornam a coleção append-only (sem update/delete possível por ninguém).
- Catálogo de ações auditáveis padronizado, sem strings mágicas espalhadas.
- `flutter analyze`, `dart format --set-exit-if-changed .` e `flutter test` sem erros; testes de regras passando no Emulator Suite.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
