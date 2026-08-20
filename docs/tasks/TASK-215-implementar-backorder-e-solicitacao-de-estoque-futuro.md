# TASK-215 — Implementar backorder e solicitação de estoque futuro

**Epic:** EPIC-32 — Operações Comerciais Avançadas de Moda B2B
**Status:** ⬜ Pendente
**Depende de:** TASK-090 (saldo por variante), TASK-091 (estoque futuro), TASK-101 (submissão do pedido), TASK-153 (notificações comerciais), TASK-210 (pré-venda e pre-book, quando aplicável)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`
- `vestipro-sales-representative-specialist`
- `vestipro-commercial-ops-strategist`

## Objetivo

Permitir registrar demanda quando não há estoque pronta entrega suficiente, criando backorders ou
solicitações de estoque futuro com transparência para vendedor, gestor e cliente. A feature transforma
ruptura em oportunidade rastreável, sem prometer disponibilidade falsa.

## Escopo técnico

- Modelar `BackorderRequest` com cliente, produto/variante, quantidade, origem, pedido relacionado,
  prioridade, data desejada, status e motivo.
- Permitir no pedido/catálogo ação de solicitar estoque futuro quando a política da organização permitir.
- Criar fila de atendimento de backorder, priorizada por cliente, data, valor potencial, segmento ou
  política comercial.
- Quando estoque futuro/pronta entrega ficar disponível, notificar vendedor/comprador e permitir converter
  backorder em pedido ou item adicional, sempre revalidando preço e disponibilidade.
- Alimentar insights de ruptura, previsão de demanda e reposição.

## Regras de negócio e restrições

- Backorder não reduz saldo de estoque atual nem garante entrega sem confirmação posterior.
- Toda promessa exibida deve diferenciar previsão, reserva aprovada e disponibilidade confirmada.
- Conversão em pedido sempre revalida preço, crédito, estoque e aprovação.
- Cliente/vendedor não pode criar backorder acima de limites configurados sem aprovação.

## Testes obrigatórios

- Teste de criação de backorder a partir de produto indisponível e estoque parcial.
- Teste de fila/prioridade com múltiplos clientes.
- Teste de conversão de backorder em pedido com revalidação de preço/estoque.
- Teste de notificação quando estoque futuro ficar disponível.
- Teste garantindo que backorder não debita estoque.

## Critérios de aceite

- Ruptura vira demanda registrada, priorizada e acionável.
- Backorder não cria promessa comercial enganosa nem movimentação indevida de estoque.
- Dados de backorder alimentam dashboards/insights de reposição.

## Arquivos prováveis

- A definir pelo agente executor no início da task.

## Referências

- Especificação funcional completa: `tasks.md`
- Agentes técnicos e de negócio em `.claude/agents/`
- Fluxo obrigatório: `AGENTS.md`
