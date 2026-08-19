# TASK-027 — Modelar Company e Branch

**Epic:** EPIC-03 — Segurança e Multi-Tenancy
**Status:** ⬜ Pendente
**Depende de:** TASK-026 (Organization modelada) — Company e Branch são obrigatoriamente vinculadas a uma Organization existente.

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Modelar as entidades `Company` e `Branch`, permitindo que uma Organização configure múltiplas empresas/marcas e múltiplas lojas/unidades vinculadas, conforme o exemplo da seção 3.1/3.2 de `tasks.md` (Organização "Grupo Fashion XPTO" com empresas "Marca A"/"Marca B" e unidades "Loja Blumenau", "Loja Jaraguá", "Showroom São Paulo").

## Escopo técnico

- Criar entidade de domínio `Company` (feature `organizations/domain/entities/` ou subfeature dedicada) com campos: `id`, `organizationId` (obrigatório e imutável), `name`, `legalName`/documento fiscal quando aplicável, `status`, campos de auditoria completos (`createdAt/By`, `updatedAt/By`, `deletedAt`, `version`).
- Criar entidade de domínio `Branch` com campos: `id`, `organizationId`, `companyId` (obrigatório e imutável), `name`, `type` (loja, showroom, unidade), endereço básico, `status`, campos de auditoria completos.
- Definir contratos de repositório `CompanyRepository` e `BranchRepository` com métodos de criar, listar por organização/empresa, obter por id e atualizar (sem update irrestrito de `organizationId`/`companyId`).
- Implementar repositórios via Firestore nas subcollections `organizations/{organizationId}/companies/{companyId}` e `organizations/{organizationId}/branches/{branchId}` (ou modelagem equivalente validada quanto a padrão de consultas, conforme seção 20/22 de `tasks.md`).
- Criar casos de uso: `CreateCompanyUseCase`, `ListCompaniesUseCase`, `CreateBranchUseCase`, `ListBranchesByCompanyUseCase`.
- Garantir que toda consulta de Branch seja escopada por `organizationId` (e opcionalmente `companyId`), nunca uma query global entre organizações.

## Regras de negócio e restrições

- `Company.organizationId` e `Branch.organizationId`/`Branch.companyId` são obrigatórios e imutáveis após criação — nenhum caso de uso permite "mover" uma Company/Branch para outra Organization.
- Uma Organization deve suportar N Companies e cada Company deve suportar N Branches (cardinalidade real, não fixa em 1).
- Exclusão de Company/Branch usa soft delete (`deletedAt`), preservando histórico de pedidos/dados vinculados.
- Nenhuma UI acessa Firestore diretamente — sempre via repositório.
- Toda consulta cliente deve ser escopada pela organização ativa; nunca depender do cliente "lembrar" de filtrar.

## Testes obrigatórios

- Teste unitário das entidades `Company` e `Branch` (igualdade por valor, imutabilidade de `organizationId`/`companyId`).
- Teste unitário dos casos de uso de criação e listagem, cobrindo múltiplas empresas por organização e múltiplas branches por empresa.
- Teste do repositório garantindo que listagens são sempre filtradas por `organizationId` (e `companyId` quando aplicável) — nunca retornam dado cross-tenant no mock.
- Teste de mapper DTO ↔ entidade cobrindo campos opcionais (endereço, documento fiscal).
- Teste cobrindo tentativa de atualizar `organizationId`/`companyId` de uma Company/Branch existente (deve ser rejeitada pelo caso de uso).

## Critérios de aceite

- Company e Branch vinculadas obrigatoriamente a uma Organization (e Branch a uma Company) em todos os fluxos de criação/leitura.
- Suporte real a múltiplas empresas e múltiplas unidades por organização testado.
- Nenhuma query no repositório retorna dados fora do escopo da organização/empresa informada.
- `flutter analyze`, `dart format --set-exit-if-changed .` e `flutter test` sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
