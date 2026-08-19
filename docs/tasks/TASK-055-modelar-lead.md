# TASK-055 — Modelar Lead

**Epic:** EPIC-07 — CRM
**Status:** ⬜ Pendente
**Depende de:** TASK-026 (Modelar Organization) — Lead precisa carregar `organizationId` válido e o vínculo obrigatório com o tenant desde a criação.

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Modelar a entidade `Lead` (origem, responsável, score, status) e os casos de uso de qualificação/desqualificação e conversão em `Customer`/`Opportunity`, formando a porta de entrada do funil comercial descrito na seção 8 de `tasks.md`.

## Escopo técnico

- Entidade `Lead` com: id, organizationId, companyId (quando aplicável), nome/empresa do lead, documento (opcional — nem todo lead tem CNPJ/CPF confirmado), origem (`LeadSource`: indicação, evento, site, redes sociais, prospecção ativa, outro — configurável por organização), responsável (`userId`), status (`LeadStatus`: novo, em contato, qualificado, desqualificado, convertido), score numérico, motivo de desqualificação (quando aplicável), data de criação/qualificação/conversão.
- Casos de uso: `CreateLead`, `QualifyLead`, `DisqualifyLead` (exige motivo), `ConvertLeadToCustomer`, `ConvertLeadToOpportunity`.
- Contrato `LeadRepository`, desacoplado de Firestore/Drift.
- Regra de conversão: Lead qualificado pode gerar um `Customer` (TASK-048) e/ou uma `Opportunity` (TASK-057) vinculada, preservando rastreabilidade da origem (campo `sourceLeadId` no Customer/Opportunity gerado).

## Regras de negócio e restrições

- Lead desqualificado exige motivo obrigatório (reaproveitar o catálogo configurável quando TASK-061 existir; nesta task um campo de texto/enum simples é aceitável, desde que a extensão futura seja documentada).
- Conversão de Lead é irreversível no fluxo padrão: uma vez convertido, o status passa a `convertido` e não retorna a `novo`/`qualificado`; o histórico deve preservar o vínculo com o Customer/Opportunity gerado.
- Score do Lead é calculado/atribuído por regra de domínio, nunca hardcoded na UI; esta task modela o campo e o contrato, sem necessariamente implementar o algoritmo completo (pode reaproveitar a abordagem de TASK-062).
- `organizationId` sempre resolvido pela sessão autenticada, nunca aceito diretamente de input externo.

## Testes obrigatórios

- Testes unitários de transição de status (novo → em contato → qualificado/desqualificado → convertido), incluindo transições inválidas bloqueadas (ex.: desqualificado → convertido diretamente).
- Teste de `DisqualifyLead` exigindo motivo (falha sem motivo).
- Teste de conversão gerando Customer/Opportunity com `sourceLeadId` preenchido corretamente.
- Teste de igualdade por valor da entidade `Lead` (freezed) e do mapper DTO↔entidade.

## Critérios de aceite

- Entidade Lead e casos de uso de qualificação/conversão implementados e testados.
- Transições de status inválidas são bloqueadas no domínio.
- `flutter analyze`, `dart format` e testes passam.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
