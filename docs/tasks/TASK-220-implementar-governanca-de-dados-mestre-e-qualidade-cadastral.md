# TASK-220 — Implementar governança de dados mestre e qualidade cadastral

**Epic:** EPIC-32 — Operações Comerciais Avançadas de Moda B2B
**Status:** ⬜ Pendente
**Depende de:** TASK-048 (Customer), TASK-064 (Product), TASK-167 (importação de clientes), TASK-168 (importação de produtos), TASK-204 (logs de auditoria exportáveis), TASK-206 (camada semântica de BI)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`
- `vestipro-commercial-ops-strategist`

## Objetivo

Criar governança de dados mestre e qualidade cadastral para clientes, produtos, variantes, preços e
territórios. Um sistema de insights só é confiável se o cadastro for completo, deduplicado, validado e
auditável.

## Escopo técnico

- Modelar `DataQualityRule`, `DataQualityIssue`, `DuplicateCandidate`, `MergeRequest` e `MasterDataScore`
  por entidade e organização.
- Criar regras configuráveis de qualidade: campos obrigatórios, formato, duplicidade provável, preço
  ausente, produto sem foto, variante sem EAN, cliente sem endereço/contato, território ausente e
  inconsistência de CNPJ/IE quando aplicável.
- Implementar fila de correção com responsável, prioridade, status, origem da detecção e histórico.
- Criar fluxo seguro de merge/deduplicação para clientes/produtos, com pré-visualização de impacto e
  auditoria completa.
- Exibir score de qualidade cadastral e impacto nos dashboards/insights, sinalizando quando um insight
  depende de dados incompletos.

## Regras de negócio e restrições

- Merge/deduplicação nunca deve apagar dados sem trilha; manter mapa de IDs antigos para novos quando
  necessário.
- Correção automática só pode acontecer em casos sem risco; mudanças destrutivas exigem aprovação humana.
- Qualidade de dados é escopada por tenant e não pode vazar exemplos ou duplicidades de outra organização.
- Dashboard/insight deve sinalizar baixa confiança quando a base de dados estiver incompleta.

## Testes obrigatórios

- Teste de detecção de duplicidade de cliente/produto com match forte e fraco.
- Teste de fluxo de merge com preservação de histórico e referências.
- Teste de regras de qualidade configuráveis por organização.
- Teste de RBAC para correção, aprovação de merge e visualização de score.
- Teste de impacto no insight/dashboard quando há baixa qualidade cadastral.

## Critérios de aceite

- Gestor consegue enxergar e corrigir problemas de cadastro antes que afetem vendas/BI.
- Merge e correção são auditáveis e não destroem histórico.
- Insights e dashboards passam a carregar indicador de confiança quando dependem de dados incompletos.

## Arquivos prováveis

- A definir pelo agente executor no início da task.

## Referências

- Especificação funcional completa: `tasks.md`
- Agentes técnicos e de negócio em `.claude/agents/`
- Fluxo obrigatório: `AGENTS.md`
