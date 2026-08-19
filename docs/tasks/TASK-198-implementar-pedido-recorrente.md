# TASK-198 — Implementar pedido recorrente

**Epic:** EPIC-29 — Pagamentos e Regras Comerciais Avançadas
**Status:** ⬜ Pendente
**Depende de:** TASK-101 (submissão do pedido, fluxo reaproveitado para gerar cada execução recorrente)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Permitir configurar um pedido recorrente (assinatura/reposição programada, ex.: repetir a cada N dias), com revalidação de preço e estoque a cada execução e cancelamento simples pelo cliente ou vendedor.

## Escopo técnico

- Modelar `RecurringOrderPlan` (customerId, itens/variantes e quantidades base, frequência — ex.: a cada N dias/semanas —, próxima execução, status: ativo/pausado/cancelado, origem do plano).
- Cloud Function agendada `processRecurringOrders` que, na data programada, gera um novo pedido a partir do plano, revalidando preço (motor de precificação, TASK-088) e disponibilidade de estoque no momento da execução — nunca reaproveitando valores antigos.
- Se algum item ficar indisponível ou o preço mudar significativamente, gerar o pedido com o que for possível e sinalizar claramente as diferenças (itens removidos/ajustados) ao vendedor/cliente antes da submissão final (TASK-101), nunca enviando silenciosamente um pedido divergente do combinado.
- Tela de gestão do plano recorrente (criar a partir de um pedido existente, editar itens/frequência, pausar, cancelar), com histórico de execuções geradas.
- Notificação (central de notificações) antes de cada execução automática, com opção de revisar/pular a rodada.

## Regras de negócio e restrições

- Toda execução recorrente revalida preço e estoque no momento real da geração — nunca usa preço/estoque congelado da criação do plano.
- Cancelamento/pausa é imediato e impede qualquer execução futura já agendada; execuções já processadas não são desfeitas retroativamente.
- Pedido gerado automaticamente deve deixar claro, no histórico do pedido, que a origem foi um plano recorrente (rastreabilidade).
- Nenhuma execução automática pode contornar aprovações/políticas de desconto normalmente exigidas para aquele valor (reaproveita TASK-103/TASK-194 quando aplicável).

## Testes obrigatórios

- Testes da Cloud Function agendada: execução normal, item indisponível na execução, preço alterado desde a criação do plano, plano pausado/cancelado (não deve gerar pedido).
- Teste de idempotência: reexecução no mesmo ciclo não gera pedido duplicado.
- Testes de widget: criação do plano, edição de frequência/itens, pausa, cancelamento, histórico de execuções.
- Teste garantindo que aprovações necessárias continuam sendo exigidas em pedidos gerados automaticamente.

## Critérios de aceite

- Pedido recorrente sempre revalida preço e estoque reais a cada execução.
- Cancelamento/pausa impede execuções futuras de forma imediata e confiável.
- Pedido gerado automaticamente é rastreável até o plano de origem.
- Políticas de aprovação/desconto continuam válidas em pedidos gerados automaticamente.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
