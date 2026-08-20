# TASK-214 — Implementar expedição, romaneio, tracking e ocorrências

**Epic:** EPIC-32 — Operações Comerciais Avançadas de Moda B2B
**Status:** ⬜ Pendente
**Depende de:** TASK-095 (Order/OrderItem), TASK-102 (acompanhamento de pedidos), TASK-170 (webhooks de saída), TASK-182 (portal B2B do cliente)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`
- `vestipro-sales-representative-specialist`
- `vestipro-commercial-ops-strategist`

## Objetivo

Implementar acompanhamento de expedição, romaneio, volumes, tracking e ocorrências de entrega para
fechar o ciclo pós-pedido. Isso dá previsibilidade ao comprador, reduz retrabalho do vendedor e cria
dados para performance logística.

## Escopo técnico

- Modelar `Shipment`, `ShipmentPackage`, `PickingList`/`Romaneio` e `TrackingEvent` vinculados ao pedido,
  cliente, transportadora, volumes, itens e status.
- Permitir atualização via integração externa/webhook, importação manual autorizada ou lançamento
  administrativo, sempre com idempotência por evento externo.
- Exibir no pedido, cliente 360º e portal B2B: status de separação, faturamento, expedição, em trânsito,
  entregue, ocorrência e entrega parcial.
- Criar registro de ocorrência logística: atraso, avaria, divergência de volume, endereço inválido,
  devolução de transporte, com responsável e próxima ação.
- Gerar eventos/notificações comerciais quando entrega atrasar, houver ocorrência ou entrega for concluída.

## Regras de negócio e restrições

- Pedido só pode avançar para expedição quando estiver em estado comercial/financeiro permitido.
- Tracking event é append-only; correção cria novo evento de ajuste, não sobrescreve histórico.
- Entrega parcial deve preservar itens/quantidades por volume para evitar divergência no pós-venda.
- Cliente externo só vê tracking dos próprios pedidos.

## Testes obrigatórios

- Teste de transição de status do pedido com expedição válida e inválida.
- Teste de idempotência de tracking event vindo por webhook.
- Teste de entrega parcial com volumes e itens distintos.
- Teste de RBAC/Rules para portal B2B visualizando apenas tracking do próprio cliente.
- Teste de notificação por atraso/ocorrência.

## Critérios de aceite

- Pedido possui rastreio logístico claro e auditável após aprovação/faturamento.
- Ocorrências de entrega geram ação para vendedor/gestor.
- Cliente acompanha tracking no portal sem expor dados de outros clientes.

## Arquivos prováveis

- A definir pelo agente executor no início da task.

## Referências

- Especificação funcional completa: `tasks.md`
- Agentes técnicos e de negócio em `.claude/agents/`
- Fluxo obrigatório: `AGENTS.md`
