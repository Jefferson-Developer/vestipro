# TASK-213 — Implementar contas a receber, faturas e lembretes de cobrança

**Epic:** EPIC-32 — Operações Comerciais Avançadas de Moda B2B
**Status:** ⬜ Pendente
**Depende de:** TASK-193 (gateways de pagamento), TASK-212 (crédito e inadimplência), TASK-095 (Order/OrderItem), TASK-102 (acompanhamento de pedidos), TASK-154 (preferências de comunicação)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`
- `vestipro-sales-representative-specialist`
- `vestipro-commercial-ops-strategist`

## Objetivo

Criar visão operacional de contas a receber, faturas/invoices e lembretes de cobrança vinculados aos
pedidos, para que vendedor, gestor e financeiro enxerguem status de pagamento sem depender apenas do
ERP ou de planilhas externas.

## Escopo técnico

- Modelar `Receivable`, `Invoice` e `PaymentAllocation` com pedido, cliente, vencimento, valor,
  parcelas, status, origem, gateway/ERP externo e histórico de alterações.
- Criar sincronização/entrada de faturas geradas por ERP/gateway, com idempotência por identificador
  externo para evitar duplicidade.
- Exibir no cliente 360º e no pedido: faturas abertas, vencidas, parcialmente pagas, pagas,
  estornadas/canceladas e aging resumido.
- Implementar lembretes de cobrança conforme preferências de comunicação, quiet hours e opt-in,
  usando templates aprovados quando o canal exigir.
- Integrar status de recebíveis ao perfil de crédito da TASK-212.

## Regras de negócio e restrições

- A UI nunca marca fatura como paga sem confirmação de gateway, ERP ou usuário financeiro autorizado.
- Parcela/fatura duplicada por retry de webhook ou importação deve ser ignorada de forma idempotente.
- Vendedor pode ver status acionável conforme RBAC, mas detalhes financeiros sensíveis ficam restritos.
- Lembrete de cobrança respeita consentimento, canal, quiet hours e política da organização.

## Testes obrigatórios

- Teste de idempotência de importação/webhook de fatura.
- Teste de aging e status financeiro: aberta, vencida, parcial, paga e estornada.
- Teste de RBAC para vendedor, gestor e financeiro.
- Teste de envio/agendamento de lembrete respeitando preferências e quiet hours.

## Critérios de aceite

- Pedido e cliente exibem situação financeira atualizada e rastreável.
- Recebíveis alimentam crédito/inadimplência de forma consistente.
- Cobranças e lembretes não violam consentimento nem permissões.

## Arquivos prováveis

- A definir pelo agente executor no início da task.

## Referências

- Especificação funcional completa: `tasks.md`
- Agentes técnicos e de negócio em `.claude/agents/`
- Fluxo obrigatório: `AGENTS.md`
