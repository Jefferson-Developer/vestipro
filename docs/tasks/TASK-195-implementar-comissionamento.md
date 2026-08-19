# TASK-195 — Implementar comissionamento de vendedores

**Epic:** EPIC-29 — Pagamentos e Regras Comerciais Avançadas
**Status:** ⬜ Pendente
**Depende de:** TASK-101 (submissão do pedido, evento que dispara o cálculo de comissão), TASK-088 (motor de precificação server-side, fonte do valor final sobre o qual a comissão incide)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Calcular comissão de vendedores a partir de regras configuráveis por vendedor/equipe/produto/campanha, com cálculo definitivo sempre server-side e relatório auditável — nunca depender de cálculo client-side para valores a pagar, com o mesmo rigor do motor de precificação.

## Escopo técnico

- Modelar `CommissionRule` (organização/equipe/vendedor/produto/campanha, percentual ou valor fixo, condições de vigência, prioridade entre regras sobrepostas).
- Cloud Function `calculateOrderCommission`, disparada na confirmação/faturamento do pedido (TASK-101), que aplica as regras vigentes sobre o valor final calculado pelo motor de precificação (TASK-088) — nunca sobre um valor recalculado no cliente.
- Modelar `CommissionEntry` (orderId, vendedor, regra aplicada, valor base, percentual/valor, valor da comissão, status: provisionada/aprovada/paga/estornada).
- Tratamento de pós-venda: devolução/troca/cancelamento (EPIC-30) gera estorno de comissão correspondente, nunca deixando valor pago indevidamente sem rastro.
- Relatório de comissão (por vendedor/período) reaproveitando o construtor de relatórios/exportação (EPIC-18), mostrando a regra aplicada por pedido — nunca apenas o total, sempre auditável até o pedido de origem.
- Tela de extrato de comissão do vendedor (somente leitura) e tela de conciliação para o gestor/financeiro.

## Regras de negócio e restrições

- Cálculo definitivo de comissão ocorre exclusivamente em Cloud Function idempotente; qualquer estimativa exibida ao vendedor antes da confirmação é claramente marcada como "estimativa", nunca valor final.
- Toda comissão deve ser reproduzível: dado um `CommissionEntry`, deve ser possível explicar exatamente qual regra e qual base de cálculo foram usadas (mesmo padrão de auditabilidade do motor de precificação).
- Sobreposição de regras (ex.: regra de produto vs. regra de campanha) segue prioridade explícita e documentada, nunca comportamento ambíguo.
- Nenhuma tela client-side pode alterar valor de comissão diretamente; ajustes manuais passam por fluxo de aprovação com motivo registrado.
- Estorno de comissão por devolução/cancelamento é automático e rastreável até o evento que o originou.

## Testes obrigatórios

- Testes da Cloud Function: cálculo com uma única regra, com regras sobrepostas (prioridade), pedido cancelado (estorno), pedido parcialmente devolvido.
- Testes de idempotência: reprocessamento do mesmo pedido não duplica `CommissionEntry`.
- Testes de RBAC: vendedor só vê seu próprio extrato; gestor/financeiro vê o consolidado da equipe/organização.
- Testes de auditoria: toda entrada de comissão é rastreável até regra e pedido de origem.

## Critérios de aceite

- Valor final de comissão é sempre calculado server-side e auditável até a regra aplicada.
- Estimativa exibida antes da confirmação nunca é confundida com o valor definitivo.
- Estornos por devolução/cancelamento ocorrem automaticamente e ficam rastreáveis.
- Vendedor não vê comissão de outros vendedores; isolamento de RBAC validado no backend.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
