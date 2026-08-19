# TASK-184 — Implementar sugestão de replenishment automático

**Epic:** EPIC-27 — Reposição e Previsão de Demanda
**Status:** ⬜ Pendente
**Depende de:** TASK-090 (saldo por variante, fonte do estoque atual usado no cálculo), TASK-128 (insight de estoque alto/giro baixo, lógica de giro histórico a ser reaproveitada)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Gerar sugestões automáticas de reposição por variante (produto-cor-tamanho), combinando giro histórico de vendas e saldo atual, sempre apresentadas como sugestão revisável — nunca gerando pedido de reposição automaticamente sem confirmação humana.

## Escopo técnico

- Cloud Function agendada `calculateReplenishmentSuggestions`, executada por organização/warehouse, calculando giro médio (ex.: média móvel de saídas em N semanas) por variante e comparando com saldo atual (TASK-090) e estoque futuro.
- Modelar `ReplenishmentSuggestion` (variantId, warehouseId, quantidade sugerida, giro médio usado, saldo no momento do cálculo, status: sugerida/aceita/ajustada/descartada, autor da decisão).
- Parâmetros configuráveis por organização (dias de cobertura alvo, estoque de segurança mínimo, sazonalidade simples).
- Tela de sugestões (gestor/comprador) com aceitar, ajustar quantidade ou descartar — toda decisão registrada com autor e timestamp.
- Ao aceitar, gerar rascunho de pedido de reposição reaproveitando o fluxo de pedidos existente (TASK-096), com origem marcada como "replenishment".
- Extrair um serviço de domínio compartilhado de cálculo de giro, reaproveitado tanto aqui quanto no insight de estoque/giro (TASK-128), evitando duplicar a mesma lógica em dois lugares.

## Regras de negócio e restrições

- Nenhuma sugestão vira pedido real sem ação humana explícita de aceite.
- Cálculo sempre roda server-side (Cloud Function), nunca no cliente, para evitar divergência entre vendedores e gestores.
- Toda sugestão expõe a evidência do cálculo (giro usado, saldo, cobertura alvo) — nunca um número sem explicação.
- Itens sem histórico suficiente (produto novo) não geram sugestão numérica arbitrária; devem ser marcados como "dados insuficientes".
- Alteração de parâmetros de cálculo por organização não altera retroativamente cálculos já aceitos (versionar snapshot dos parâmetros usados).

## Testes obrigatórios

- Testes unitários do serviço de cálculo de giro/cobertura: histórico completo, histórico parcial, sem histórico, saldo zero, saldo negativo.
- Testes da Cloud Function agendada: execução isolada por organização, idempotência em reexecução no mesmo período.
- Testes de aceite/ajuste/descarte de sugestão, com trilha de auditoria.
- Testes de geração de rascunho de pedido a partir de sugestão aceita.

## Critérios de aceite

- Sugestões de reposição aparecem por variante com evidência de cálculo visível.
- Nenhum pedido é criado automaticamente sem confirmação humana.
- Gestor consegue ajustar ou descartar cada sugestão com justificativa registrada.
- Cálculo é isolado por organização e não vaza dados entre tenants.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
