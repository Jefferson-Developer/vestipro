# TASK-091 — Implementar estoque futuro

**Epic:** EPIC-12 — Estoque e Disponibilidade
**Status:** ⬜ Pendente
**Depende de:** TASK-090 — Implementar saldo por variante (estoque futuro complementa o saldo atual, nunca o substitui)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar a previsão de disponibilidade futura (recebimento previsto, produção, transferência) com data estimada, exibida ao vendedor na tela de produto/grade para que ele consiga prometer prazo mesmo quando a variante não tem saldo imediato.

## Escopo técnico

- Criar entidade `FutureStockEntry` (`variantId`, `warehouseId`, `quantity`, `expectedDate`, `source`: ex. `purchase_order`/`production_order`/`transfer`).
- Expor caso de uso que combina saldo atual (TASK-090) com entradas futuras ordenadas por data, retornando um resumo de disponibilidade (ex.: "12 un. disponíveis agora + 24 un. previstas para 05/09").
- Criar/estender componente de UI na grade comercial e no detalhe de produto exibindo badge/indicador que diferencia pronta entrega de estoque futuro com a data prevista, sem poluir a grade.
- Integrar com a UI de grade comercial (TASK-073) e detalhe de produto (TASK-078) via contrato fornecido pelo domain — a UI apenas exibe o resultado, nunca calcula a previsão.
- Registrar evento de Analytics quando o vendedor expandir/considerar o detalhe de estoque futuro relevante para a venda.

## Regras de negócio e restrições

- Data prevista é informativa, nunca uma garantia contratual — o texto de UI deve deixar isso explícito ("previsão", nunca "garantido").
- Estoque futuro nunca é somado ao saldo vendável imediato de forma que permita reserva automática sem sinalização clara ao vendedor.
- A origem da previsão (compra, produção, transferência) deve ser rastreável, para explicar ao vendedor/cliente a base do prazo informado.

## Testes obrigatórios

- Teste de caso de uso combinando saldo atual com múltiplas entradas futuras ordenadas corretamente por data.
- Teste de widget exibindo o badge de estoque futuro com data formatada por localidade (`intl`).
- Teste de estado vazio (produto sem estoque futuro previsto).
- Teste de acessibilidade/contraste do indicador visual (não depender só de cor para diferenciar pronta entrega de estoque futuro).

## Critérios de aceite

- Vendedor consegue ver, na tela de produto/grade, quando uma variante sem saldo imediato tem previsão de chegada e em qual data.
- Indicador visual não confunde pronta entrega com estoque futuro em nenhum estado.
- Nenhum cálculo de previsão realizado na camada de apresentação.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
