# TASK-201 — Implementar acompanhamento de pós-venda

**Epic:** EPIC-30 — Pós-venda
**Status:** ⬜ Pendente
**Depende de:** TASK-101 (submissão do pedido, âncora da timeline), TASK-151 (central de notificações internas, canal de notificação dos marcos de pós-venda)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Criar uma linha do tempo de pós-venda por pedido (entrega, problemas reportados, resolução), com notificações de status ao cliente e ao vendedor, dando visibilidade ao que acontece com o pedido depois da confirmação.

## Escopo técnico

- Modelar `PostSaleEvent` (orderId, tipo — ex.: despachado, em trânsito, entregue, problema reportado, em resolução, resolvido —, descrição, autor, timestamp), formando uma timeline por pedido.
- Cloud Function/trigger que registra eventos a partir de integrações existentes (ex.: atualização de status logístico, quando disponível) e permite registro manual por vendedor/suporte (ex.: "cliente reportou avaria").
- Tela de timeline de pós-venda no detalhe do pedido (evolução de TASK-102), reaproveitando o padrão visual de timeline já usado no CRM (TASK-059).
- Notificações (central de notificações, TASK-151) para o vendedor a cada marco relevante (entregue, problema reportado) e, quando aplicável, para o cliente (se houver canal habilitado, ex.: WhatsApp com opt-in de TASK-183).
- Vincular devoluções/trocas (TASK-199/TASK-200) como eventos na mesma timeline, para visão única de pós-venda do pedido.

## Regras de negócio e restrições

- Todo evento de pós-venda é imutável uma vez registrado (histórico não é editado, apenas complementado com novos eventos).
- Registro manual de problema exige descrição mínima obrigatória (nunca um evento vazio de "problema").
- Notificação ao cliente só ocorre em canais com consentimento/opt-in ativo (respeitando LGPD e as regras de TASK-183).
- Isolamento multi-tenant: timeline de um pedido só é visível a usuários da mesma organização (e ao cliente correspondente, quando aplicável ao portal B2B).

## Testes obrigatórios

- Testes da Cloud Function/trigger: registro automático de evento, registro manual válido, registro manual sem descrição (rejeitado).
- Teste de vínculo de eventos de devolução/troca na mesma timeline.
- Testes de notificação: disparo correto para vendedor e para cliente (respeitando opt-in).
- Testes de widget: timeline completa, timeline vazia, novo evento manual, evento de problema em destaque.

## Critérios de aceite

- Todo pedido relevante possui uma timeline de pós-venda consultável, incluindo eventos automáticos e manuais.
- Eventos de devolução/troca aparecem integrados na mesma timeline do pedido.
- Notificações de marcos de pós-venda chegam ao vendedor e, quando permitido, ao cliente.
- Nenhum evento de pós-venda é editado retroativamente; histórico é sempre aditivo.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
