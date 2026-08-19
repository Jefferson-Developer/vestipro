# TASK-026 — Modelar Organization

**Epic:** EPIC-03 — Segurança e Multi-Tenancy
**Status:** ⬜ Pendente
**Depende de:** TASK-013 (Firestore configurado) — a entidade e o repositório precisam da infraestrutura de persistência cloud já disponível.

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Modelar a entidade `Organization` como tenant raiz do sistema (seção 3.1 de `tasks.md`), incluindo domínio (entidade, value objects), contrato de repositório, implementação de repositório (Firestore) e casos de uso básicos (criar, ler, atualizar configurações). Toda a arquitetura multi-tenant do VestiPro depende desta entidade estar correta e imutável em seus identificadores.

## Escopo técnico

- Criar entidade de domínio `Organization` (feature `organizations/domain/entities/`) com campos mínimos: `id`, `name`, `slug`/identificador amigável, `settings` (moeda, país, idioma padrão), `createdAt`, `createdBy`, `updatedAt`, `updatedBy`, `deletedAt`, `status`.
- Definir `id` da Organization como imutável após criação — nenhum caso de uso pode alterar o `id` de uma organização existente.
- Criar contrato de repositório (`OrganizationRepository`) na camada domain, com métodos `create`, `getById`, `updateSettings` (sem exposição de métodos genéricos de update irrestrito).
- Implementar `OrganizationRepositoryImpl` na camada data usando Firestore (`organizations/{organizationId}`), com DTO e mapper separados da entidade.
- Criar casos de uso: `CreateOrganizationUseCase`, `GetOrganizationUseCase`, `UpdateOrganizationSettingsUseCase`.
- Modelar `Organization` como raiz de todas as subcollections previstas na seção 20 de `tasks.md` (companies, branches, members, teams, roles, etc.), sem criar ainda essas subcollections (isso é escopo de tasks futuras) — apenas garantir que o path estrutural seja compatível.
- Garantir que a criação de Organization seja transacional/idempotente (evitar duplicidade em caso de retry de rede), preparando o terreno para a TASK-037 (criação da primeira Organization no onboarding).

## Regras de negócio e restrições

- O `organizationId` nunca pode ser gerado ou confirmado apenas pelo cliente sem validação — a criação real definitiva deve ser validável no backend (Cloud Function ou regra de escrita), mesmo que esta task apenas prepare a estrutura de domínio/repositório.
- Nenhuma UI deve acessar Firestore diretamente para ler/gravar Organization — sempre via `OrganizationRepository`.
- Isolamento lógico: nenhuma consulta pode retornar dados de mais de uma Organization simultaneamente.
- Soft delete: exclusão de Organization deve popular `deletedAt`, nunca remover fisicamente o documento nesta camada.
- Campos de auditoria (`createdAt`, `createdBy`, `updatedAt`, `updatedBy`) devem ser preenchidos de forma consistente, preferencialmente confirmados no backend.

## Testes obrigatórios

- Teste unitário da entidade `Organization` (igualdade por valor, imutabilidade do `id`).
- Teste unitário dos casos de uso `CreateOrganizationUseCase`, `GetOrganizationUseCase`, `UpdateOrganizationSettingsUseCase`, cobrindo sucesso, falha de validação e falha de rede.
- Teste do mapper DTO ↔ entidade cobrindo campos nulos/opcionais.
- Teste do repositório (`OrganizationRepositoryImpl`) com mock do datasource Firestore, cobrindo criação idempotente (retry não duplica organização).
- Teste garantindo que `UpdateOrganizationSettingsUseCase` nunca permite alterar o `id`.

## Critérios de aceite

- Entidade `Organization` criada com isolamento lógico e `id` imutável.
- Repositório e casos de uso básicos (criar, ler, atualizar configurações) implementados e testados.
- Nenhum acesso direto a Firestore fora da camada data/datasource.
- `flutter analyze`, `dart format --set-exit-if-changed .` e `flutter test` sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
