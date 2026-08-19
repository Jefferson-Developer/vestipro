# TASK-128 — Implementar insight de estoque alto/giro baixo e reposição

**Epic:** EPIC-16 — Insights e Recomendação
**Status:** ⬜ Pendente
**Depende de:** TASK-121 (engine base de insights), TASK-090 (saldo por variante), TASK-094 (indicadores de giro de estoque)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Implementar os insights "produtos com estoque alto e giro baixo" e "sugestão de reposição" (seção 11 de `tasks.md`) — dois sinais relacionados porém opostos: excesso de estoque parado (oportunidade de queima/campanha) e risco de ruptura por giro alto com estoque baixo (sugestão de reposição).

## Escopo técnico

- Criar `HighStockLowTurnoverInsightRule`: identifica produtos/variantes com saldo acima de um limiar de cobertura em dias (configurável) e índice de giro (TASK-094) abaixo de um limiar mínimo (configurável), sinalizando candidatos a liquidação/campanha promocional.
- Criar `ReplenishmentSuggestionInsightRule`: identifica produtos/variantes com índice de giro alto e cobertura de estoque abaixo de um limiar mínimo de dias, sugerindo reposição antes da ruptura, cruzando com os alertas já existentes (TASK-093).
- Montar evidência de estoque alto/giro baixo: saldo atual, cobertura em dias, índice de giro, dias parado sem saída relevante.
- Montar evidência de reposição: índice de giro, cobertura atual em dias, ponto de ressuprimento sugerido (baseado no consumo médio recente do snapshot de TASK-133).
- Configurar `quickAction` de estoque alto/giro baixo: "Sugerir campanha/desconto" (leva ao módulo de campanhas promocionais, TASK-087).
- Configurar `quickAction` de reposição: "Notificar compras/reposição" (gera notificação/registro para o time responsável, sem disparar compra automática).

## Regras de negócio e restrições

- Limiares de cobertura em dias e de índice de giro configuráveis por organização e, quando fizer sentido, por categoria (básico, moda e fashion têm giro esperado distinto).
- A sugestão de reposição nunca gera pedido de compra automático nesta task — apenas insight/notificação; automação de replenishment fica a cargo do EPIC-27.
- Produtos descontinuados/fora de coleção vigente não entram na regra de reposição, mas podem entrar na de estoque alto/giro baixo como candidatos a liquidação.
- As duas regras não devem se sobrepor para o mesmo produto/variante no mesmo ciclo (mutuamente exclusivas por definição de limiares).

## Testes obrigatórios

- Teste de `HighStockLowTurnoverInsightRule` com produto acima/abaixo dos limiares de cobertura e giro configurados.
- Teste de `ReplenishmentSuggestionInsightRule` com produto de giro alto e cobertura baixa (dispara) e cobertura confortável (não dispara).
- Teste de exclusão de produto descontinuado da regra de reposição.
- Teste de limiares configuráveis por categoria.

## Critérios de aceite

- As duas regras operam de forma independente e nunca geram insight duplicado/contraditório para o mesmo produto/variante no mesmo ciclo.
- Evidência de cada insight exibe cobertura em dias e índice de giro usados no cálculo.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
