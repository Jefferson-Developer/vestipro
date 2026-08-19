# TASK-153 — Implementar notificações comerciais

**Epic:** EPIC-19 — Notificações e Engajamento
**Status:** ⬜ Pendente
**Depende de:** TASK-151 (central de notificações internas, onde as notificações comerciais são
exibidas), TASK-120 (alertas de meta, um dos gatilhos de notificação comercial)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Gerar alertas comerciais sobre metas em risco, pedidos com problema e oportunidades quentes,
entregues na central de notificações (TASK-151), para que gestores e vendedores ajam a tempo sobre
situações críticas do negócio.

## Escopo técnico

- Reaproveitar os alertas de meta em risco/oportunidade já gerados em TASK-120 e transformá-los em
  notificações categoria "comercial" na central (TASK-151).
- Gerar notificação para outros eventos comerciais: pedido rejeitado ou com falha crítica de
  sincronização, oportunidade quente identificada pela engine de insights (EPIC-16).
- Priorização visual diferenciada na central para alertas críticos (ex.: meta em risco severo) versus
  informativos.
- Deep link para o pedido, meta ou oportunidade relacionada.

## Regras de negócio e restrições

- Evitar excesso de notificações: aplicar a mesma regra de "thresholds configuráveis e sem excesso"
  definida para alertas de meta (TASK-120), agrupando/consolidando quando fizer sentido (ex.: um
  resumo diário em vez de um alerta por item).
- Notificação de meta em risco vai apenas ao vendedor/gestor responsável pela carteira/equipe (RBAC).
- Notificação de pedido com problema nunca expõe detalhe financeiro sensível a quem não tem
  permissão de visualizá-lo (ex.: diferença de tratamento entre `FINANCE` e `SALES_REP`).

## Testes obrigatórios

- Teste de geração de notificação a partir de alerta de meta em risco (integração com TASK-120).
- Teste de agrupamento/consolidação evitando excesso de notificações para o mesmo usuário.
- Teste de RBAC restringindo quem recebe cada tipo de alerta comercial.
- Teste de deep link para pedido/meta/oportunidade relacionados.
- Teste de priorização visual (crítico vs. informativo) sem depender apenas de cor.

## Critérios de aceite

- Alertas comerciais chegam ao responsável certo, sem inundar a central de notificações.
- Alertas críticos são visualmente destacados de forma acessível (não apenas por cor).
- Nenhuma notificação vaza dado financeiro sensível fora do RBAC do destinatário.
- Deep link funcional para cada tipo de alerta comercial.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura
  de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
