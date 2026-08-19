# TASK-205 — Criar pipeline de Data Warehouse / BigQuery

**Epic:** EPIC-31 — Administração Avançada e Data Platform
**Status:** ⬜ Pendente
**Depende de:** TASK-133 (camada de agregação server-side, referência de dados já consolidados a serem também exportados)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Criar um pipeline de exportação incremental do Firestore para o BigQuery (via extensão oficial do Firebase ou pipeline próprio), com esquema documentado, garantindo que dados de uma organização nunca fiquem expostos a consultas de outra organização.

## Escopo técnico

- Avaliar e adotar a extensão oficial "Export Collections to BigQuery" (ou pipeline próprio via Cloud Functions + BigQuery client, caso a extensão não cubra necessidades específicas de multi-tenancy), documentando a decisão em um ADR (mesmo padrão de TASK-105).
- Selecionar as coleções relevantes para BI (orders, customers, products/variants, targets, insights, priceLists, commissionEntries quando existir) e definir o esquema de tabelas no BigQuery, incluindo sempre `organizationId` como coluna de particionamento/filtro obrigatório.
- Views/datasets no BigQuery segmentados de forma que qualquer consulta de análise exija filtro por `organizationId` — nunca uma tabela consultável sem esse filtro ser praticamente obrigatório (ex.: views parametrizadas, row-level security do BigQuery quando aplicável).
- Job/monitoramento de atraso de sincronização (freshness) entre Firestore e BigQuery, alertando se a exportação incremental parar de rodar.
- Documentar o esquema de tabelas resultante (nome de tabela, colunas, tipo, origem) para uso pela equipe de dados e pela camada semântica de BI (TASK-206).

## Regras de negócio e restrições

- Nenhuma tabela/view do Data Warehouse deve permitir consulta que misture dados de organizações diferentes sem filtro explícito de `organizationId`.
- Exportação incremental nunca deve duplicar registros nem perder eventos de atualização/exclusão (soft delete refletido corretamente no destino).
- Dados pessoais sensíveis seguem a mesma política de minimização definida em LGPD (EPIC-20) — não exportar campos além do necessário para BI.
- Pipeline deve ser reprocessável (reexecução de uma janela de tempo) sem gerar duplicidade, para recuperação de falhas.

## Testes obrigatórios

- Testes de configuração/validação do pipeline: uma alteração no Firestore aparece corretamente no BigQuery dentro do tempo esperado (teste de integração, ambiente de staging).
- Teste de isolamento: consulta sem filtro de organização não deve ser o caminho padrão disponibilizado às ferramentas de BI (validar a estrutura de views/permissões).
- Teste de reprocessamento de uma janela sem duplicar dados.
- Teste garantindo que exclusões (soft delete) no Firestore refletem corretamente no destino (não deixam registro "fantasma" ativo).

## Critérios de aceite

- Dados relevantes chegam ao BigQuery de forma incremental e consistente, com atraso monitorado.
- Nenhuma consulta padrão do Data Warehouse mistura dados de organizações diferentes.
- Esquema de tabelas está documentado e acessível à equipe de dados.
- Pipeline pode ser reprocessado sem duplicar ou perder dados.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
