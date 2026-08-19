# TASK-048 — Modelar Customer

**Epic:** EPIC-06 — Clientes
**Status:** ⬜ Pendente
**Depende de:** TASK-026 (Modelar Organization) — Customer precisa carregar `organizationId`/`companyId` válidos e o vínculo obrigatório com o tenant desde a criação.

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Modelar a entidade `Customer` suportando pessoa jurídica e pessoa física, com todos os campos que sustentarão o cadastro (TASK-049), endereços/contatos (TASK-050), carteira (TASK-051), detalhe 360º (TASK-052) e segmentação (TASK-053). A entidade deve seguir o padrão de entidade sincronizável definido em `.claude/agents/flutter-senior-architect.md` (id, organizationId, companyId, createdAt/By, updatedAt/By, deletedAt, version, syncStatus).

## Escopo técnico

- Criar entidade `Customer` (domain) com discriminador `CustomerType` (`legalEntity` / `individual`).
- Campos comuns: id, organizationId, companyId, tipo, documento (CNPJ ou CPF), razão social/nome fantasia (PJ) ou nome completo (PF), inscrição estadual (PJ, opcional), email principal, telefone principal, status (ativo/inativo/prospect/bloqueado), classificação/potencial (ex.: A/B/C, configurável por organização), segmento, canal de origem, vendedor responsável (`userId`), data de cadastro, data da última compra (denormalizada para performance de listagem), tags e custom fields.
- Value object `CnpjCpf` com validação de dígito verificador, formatação e identificação do tipo de documento.
- Casos de uso: `CreateCustomer`, `UpdateCustomer`, `DeactivateCustomer`, `GetCustomerById`.
- Contrato `CustomerRepository` (domain), desacoplado de Firestore/Drift.
- DTO `CustomerDto` + `CustomerMapper` na camada data.

## Regras de negócio e restrições

- Documento (CNPJ/CPF) obrigatório e único por organização — validar duplicidade antes de criar.
- PJ exige razão social e CNPJ válidos; PF exige nome completo e CPF válido — obrigatoriedade de campos varia conforme `CustomerType`.
- Nunca persistir `Customer` sem `organizationId` resolvido a partir da sessão autenticada — nunca aceitar `organizationId` vindo diretamente de input de formulário/cliente.
- Campos de classificação/potencial devem ser configuráveis por organização (não hardcoded), preparando terreno para a configurabilidade de campos obrigatórios da TASK-049.
- Alterações em campos sensíveis (documento, razão social) devem ser auditáveis, preparando integração futura com TASK-033.

## Testes obrigatórios

- Testes unitários de validação de CNPJ e CPF (casos válidos, inválidos, dígito verificador incorreto, tamanho incorreto).
- Testes de mapper DTO↔entidade cobrindo PJ e PF, incluindo campos opcionais nulos.
- Testes de caso de uso `CreateCustomer` cobrindo: duplicidade de documento na mesma organização, tipo inconsistente com o documento informado, `organizationId` ausente/inválido.
- Teste de igualdade por valor da entidade `Customer` (freezed).

## Critérios de aceite

- Entidade `Customer` cobre PJ e PF com discriminador de tipo e validação de documento.
- Nenhum caso de uso aceita `organizationId` vindo diretamente do formulário sem resolução via sessão autenticada.
- Mapper e value objects cobertos por testes unitários com casos válidos, inválidos e de limite.
- `flutter analyze` e `dart format --set-exit-if-changed .` sem erros; testes desta task passam.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
