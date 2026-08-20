# TASK-212 — Implementar crédito, inadimplência e bloqueios financeiros

**Epic:** EPIC-32 — Operações Comerciais Avançadas de Moda B2B
**Status:** ⬜ Pendente
**Depende de:** TASK-048 (Customer), TASK-052 (cliente 360º), TASK-085 (condições de pagamento), TASK-088 (motor de precificação), TASK-101 (submissão do pedido), TASK-194 (aprovação multinível)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`
- `vestipro-sales-representative-specialist`
- `vestipro-commercial-ops-strategist`

## Objetivo

Adicionar controle de limite de crédito, inadimplência e bloqueios financeiros por cliente para evitar
pedido que não deveria ser aceito, sem esconder do vendedor o motivo e a rota de resolução comercial.

## Escopo técnico

- Modelar `CustomerCreditProfile` com limite de crédito, saldo em aberto, saldo vencido, política de
  bloqueio, score financeiro, última atualização, origem do dado e visibilidade por RBAC.
- Criar Cloud Function `validateOrderCredit` chamada na submissão do pedido, combinando valor do pedido,
  saldo em aberto, títulos vencidos, condição de pagamento e política da organização.
- Exibir no cliente 360º e no pedido alertas claros: liberado, próximo do limite, bloqueado,
  aprovação necessária ou dado financeiro desatualizado.
- Integrar exceções de crédito ao fluxo de aprovação multinível quando a política permitir override.
- Registrar auditoria de toda alteração manual em limite, bloqueio, liberação excepcional ou política.

## Regras de negócio e restrições

- O cliente não pode aprovar crédito no próprio app; decisão crítica é server-side e auditável.
- Dados financeiros sensíveis são visíveis apenas para perfis autorizados.
- Offline: o app pode alertar com o último snapshot conhecido, mas submissão sempre revalida ao sincronizar.
- Override de bloqueio financeiro exige motivo, aprovador autorizado e validade temporal.
- Analytics não deve conter valores financeiros sensíveis nem motivo detalhado de inadimplência.

## Testes obrigatórios

- Teste da Cloud Function: pedido dentro do limite, excedendo limite, cliente com vencido, dado expirado
  e override aprovado.
- Teste de RBAC: vendedor vê status acionável sem detalhes sensíveis quando não autorizado; financeiro
  vê detalhes completos.
- Teste offline: rascunho criado com snapshot antigo e bloqueado/reaprovado ao sincronizar.
- Teste de auditoria de alteração de limite e liberação excepcional.

## Critérios de aceite

- Pedido é bloqueado ou enviado para aprovação quando viola crédito/inadimplência.
- Vendedor entende o motivo operacional sem acessar dado financeiro além do permitido.
- Toda exceção financeira fica auditável.

## Arquivos prováveis

- A definir pelo agente executor no início da task.

## Referências

- Especificação funcional completa: `tasks.md`
- Agentes técnicos e de negócio em `.claude/agents/`
- Fluxo obrigatório: `AGENTS.md`
