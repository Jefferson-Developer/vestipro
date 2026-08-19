# TASK-097 — Implementar adição de produtos ao pedido via catálogo

**Epic:** EPIC-13 — Pedidos
**Status:** ⬜ Pendente
**Depende de:** TASK-096 — Implementar pedido em rascunho (adição de item ocorre dentro de um rascunho já existente); TASK-077 — Implementar grid visual de produtos (origem da navegação de catálogo)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Permitir a inserção de variantes e quantidades no pedido em rascunho a partir do catálogo (grid visual), com atualização de totais em tempo real conforme itens são adicionados, removidos ou alterados.

## Escopo técnico

- Integrar o grid visual de produtos (TASK-077) ao fluxo de pedido em rascunho: CTA "Adicionar ao pedido" no card/detalhe de produto abre a seleção de variante (cor/tamanho) e quantidade.
- Ao confirmar a adição, criar/atualizar o `OrderItem` correspondente no rascunho local, disparando recálculo de totais via caso de uso que consulta o motor de precificação para feedback imediato de UX (client-side é apenas estimativa, nunca definitivo).
- Implementar remoção e edição de quantidade de item já adicionado diretamente na lista de itens do pedido.
- Exibir contador/indicador de "produtos no pedido atual" acessível a partir do catálogo, com linguagem adequada ao contexto B2B (evitar termos de e-commerce B2C).
- Registrar o evento de Analytics `product_added_to_order` com contexto de origem (catálogo, busca, favoritos).

## Regras de negócio e restrições

- O preço exibido ao adicionar reflete sempre a tabela de preço vigente do pedido/cliente — nunca um preço "achatado" que ignore a tabela ativa.
- Adicionar um produto sem variante/estoque cadastrado deve ser bloqueado ou sinalizado claramente (conforme disponibilidade retornada por TASK-090/TASK-091), nunca falhar silenciosamente.
- Totais exibidos durante a adição são estimativa client-side claramente identificada; o total oficial permanece o do resumo comercial (TASK-099), sempre vindo do motor de precificação.

## Testes obrigatórios

- Teste de BLoC cobrindo adição, atualização de quantidade e remoção de item no rascunho.
- Teste de integração catálogo → pedido garantindo que o item correto (produto + variante + preço) é persistido.
- Teste de widget para o indicador de itens no pedido atual, incluindo estado vazio.
- Teste de Analytics verificando o disparo do evento `product_added_to_order` com os parâmetros corretos.

## Critérios de aceite

- Vendedor adiciona produtos/variantes ao pedido em rascunho diretamente do catálogo com poucos toques.
- Totais do rascunho são atualizados em tempo real a cada alteração de item.
- Evento de Analytics correto é disparado a cada adição.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
