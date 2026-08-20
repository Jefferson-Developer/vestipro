# TASK-219 — Implementar ingestão de sell-out/POS do varejo

**Epic:** EPIC-32 — Operações Comerciais Avançadas de Moda B2B
**Status:** ⬜ Pendente
**Depende de:** TASK-169 (framework de integração ERP), TASK-171 (API pública), TASK-205 (Data Warehouse/BigQuery), TASK-206 (camada semântica de BI), TASK-220 (governança de dados mestre, quando disponível)

## Agentes obrigatórios

- `flutter-senior-architect`
- `vestipro-commercial-ops-strategist`
- `vestipro-sales-representative-specialist`

## Objetivo

Ingerir dados de sell-out/POS enviados por varejistas, marketplaces, ERPs ou planilhas para diferenciar
o que a marca vendeu ao cliente (sell-in) do que o cliente vendeu ao consumidor final (sell-out). Isso
melhora previsão de demanda, reposição, mix ideal e qualidade dos insights.

## Escopo técnico

- Modelar `SellOutEvent`/`RetailSalesFact` com cliente, loja, data, produto/variante, quantidade,
  valor, canal, origem, confiança do match e latência.
- Criar ingestão via API, importação CSV/XLSX e/ou conector ERP/POS, reaproveitando o framework de
  integração e registrando lote, erros e idempotência.
- Implementar matching de produto/variante por EAN, SKU, referência, cor/tamanho e tabela de equivalência
  por cliente.
- Persistir fatos analíticos em camada adequada para BI/BigQuery, sem poluir o fluxo transacional de
  pedidos.
- Alimentar dashboards e insights: ruptura no varejo, reposição sugerida, produto parado no cliente,
  sell-through por coleção, top sellers por região e oportunidade de cross-sell.

## Regras de negócio e restrições

- Sell-in e sell-out são métricas diferentes e devem aparecer rotuladas separadamente.
- Dados de POS podem ter latência e confiança parcial; dashboards devem exibir origem/atualização quando
  relevante.
- Dados enviados por um cliente não podem ser usados para expor performance individual a outro cliente.
- Ingestão não altera pedido, estoque da marca ou faturamento transacional.
- Dados pessoais do consumidor final não devem ser ingeridos, salvo base legal explícita e necessidade
  comprovada; por padrão, trabalhar agregado/anônimo.

## Testes obrigatórios

- Teste de ingestão idempotente por lote/evento.
- Teste de matching de produto por EAN, SKU e tabela de equivalência.
- Teste de isolamento multi-tenant e por cliente.
- Teste de métrica separando sell-in de sell-out.
- Teste de rejeição/mascaramento de dado pessoal indevido em payload.

## Critérios de aceite

- Dados de sell-out entram com rastreabilidade de origem, latência e qualidade.
- Dashboards/insights conseguem usar sell-out sem confundir com pedidos/faturamento da marca.
- Isolamento de cliente e privacidade são preservados.

## Arquivos prováveis

- A definir pelo agente executor no início da task.

## Referências

- Especificação funcional completa: `tasks.md`
- Agentes técnicos e de negócio em `.claude/agents/`
- Fluxo obrigatório: `AGENTS.md`
