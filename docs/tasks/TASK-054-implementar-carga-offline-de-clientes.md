# TASK-054 — Implementar carga offline inicial de clientes

**Epic:** EPIC-06 — Clientes
**Status:** ⬜ Pendente
**Depende de:** TASK-048 (Modelar Customer) — o schema local espelha os campos e regras já definidos na entidade de domínio.

> **Nota:** esta task prepara apenas o modelo local de clientes. O motor de sincronização genérico (Outbox, cursor incremental, resolução de conflitos) é construído em EPIC-14 e deve ser reaproveitado quando existir — nunca duplicado aqui.

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Definir o schema local (Drift) para clientes e a lógica de seleção de quais clientes baixar para o dispositivo, conforme a carteira e a permissão do vendedor — a base de dados que a carteira offline (TASK-051) e o detalhe 360º (TASK-052) consultarão quando o app estiver sem conexão.

## Escopo técnico

- Tabela Drift `CustomersTable` espelhando os campos de `Customer` (TASK-048), incluindo as colunas de sincronização obrigatórias (`id`, `organizationId`, `companyId`, `createdAt`, `createdBy`, `updatedAt`, `updatedBy`, `deletedAt`, `version`, `syncStatus`).
- Tabelas relacionadas locais para endereços e contatos (TASK-050), com chave estrangeira para `CustomersTable`.
- Lógica de seleção de carga: `SALES_REP` baixa apenas os clientes da própria carteira (TASK-045); `SALES_MANAGER` baixa a carteira da equipe; `ADMIN`/`OWNER` baixam um escopo mais amplo configurável, com limite de paginação para evitar carga excessiva no dispositivo.
- Estratégia de carga inicial (download completo filtrado) com ponto de extensão claro para o motor de sincronização incremental que será construído em TASK-109 — não implementar sincronização incremental nesta task, apenas a carga inicial e o schema.
- Migração Drift versionada e testada para a nova tabela.

## Regras de negócio e restrições

- Nunca baixar clientes fora da carteira/permissão do usuário para o dispositivo — isso violaria tanto o RBAC quanto o isolamento de dados sensíveis em campo.
- Esta task não deve reimplementar Outbox nem motor de sincronização incremental — apenas preparar o schema e a seleção de dados a carregar, reaproveitando o que for definido em EPIC-14 quando existir.
- Dados sensíveis do cliente (documento, contatos) seguem as mesmas regras de armazenamento local seguro já definidas para o projeto (nunca em `shared_preferences`).

## Testes obrigatórios

- Teste de migração Drift (schema criado corretamente; upgrade sem perda de dados quando aplicável).
- Teste da lógica de seleção de carga: vendedor recebe só sua carteira, gestor recebe a carteira da equipe, admin recebe o escopo mais amplo.
- Teste de limite de paginação da carga inicial (não travar em organizações com grande volume de clientes).
- Teste de mapeamento DTO/entidade ↔ linha Drift para cliente, endereço e contato.

## Critérios de aceite

- Schema local de clientes (e endereços/contatos relacionados) criado e migrado sem erro.
- Seleção de carga respeita a carteira/permissão do usuário em todos os perfis testados.
- `flutter analyze`, `dart format` e testes passam.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
