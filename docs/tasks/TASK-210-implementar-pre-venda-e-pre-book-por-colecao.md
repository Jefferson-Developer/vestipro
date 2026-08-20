# TASK-210 — Implementar pré-venda e pre-book por coleção

**Epic:** EPIC-32 — Operações Comerciais Avançadas de Moda B2B
**Status:** ⬜ Pendente
**Depende de:** TASK-066 (coleções e estações), TASK-091 (estoque futuro), TASK-092 (reserva comercial), TASK-095 (Order/OrderItem), TASK-088 (motor de precificação), TASK-103 (aprovação de pedidos)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`
- `vestipro-sales-representative-specialist`
- `vestipro-commercial-ops-strategist`

## Objetivo

Suportar venda antecipada de coleção (pré-venda/pre-book), com janelas comerciais, datas de entrega,
alocação de estoque futuro e regras de compromisso. Esse fluxo é crítico para moda por temporada,
showroom e venda antes da produção/entrega.

## Escopo técnico

- Modelar `PreBookProgram` com coleção, janela de venda, janelas de entrega, status, público elegível,
  metas de volume, regras de cancelamento e política de preço.
- Relacionar estoque futuro da TASK-091 a programas de pré-venda, diferenciando previsão, alocação,
  reserva firme e indisponibilidade.
- Permitir pedido do tipo `pre_book` com entrega futura, datas prometidas por item e sinalização clara
  no resumo comercial.
- Integrar aprovação quando volume, desconto, prazo ou cliente exigirem revisão.
- Criar dashboards/indicadores básicos de captação de pré-venda por coleção: reservado, vendido,
  cancelado, gap de meta e risco de produção/entrega.

## Regras de negócio e restrições

- Pedido de pré-venda não pode consumir estoque pronta entrega.
- Data de entrega prometida deve vir do programa/janela aprovada, nunca digitada livremente sem regra.
- Encerrada a janela de venda, novas submissões ficam bloqueadas ou exigem permissão excepcional.
- Alteração em quantidade ou data após aprovação deve gerar trilha de auditoria e possível nova aprovação.
- A UI deve deixar explícito quando a disponibilidade é futura/estimada.

## Testes obrigatórios

- Teste de criação de pedido pre-book dentro e fora da janela comercial.
- Teste de alocação de estoque futuro e bloqueio contra consumo de estoque pronta entrega.
- Teste de mudança de data/quantidade disparando aprovação quando configurado.
- Teste de widget exibindo datas futuras, estados de janela e indisponibilidade.

## Critérios de aceite

- Vendedor consegue vender coleção futura com datas e disponibilidade claras.
- Gestor acompanha captação de pré-venda por coleção e identifica risco de meta/entrega.
- O fluxo nunca mistura estoque futuro com saldo pronta entrega sem regra explícita.

## Arquivos prováveis

- A definir pelo agente executor no início da task.

## Referências

- Especificação funcional completa: `tasks.md`
- Agentes técnicos e de negócio em `.claude/agents/`
- Fluxo obrigatório: `AGENTS.md`
