# TASK-130 — Implementar insight de pedido abandonado/carrinho salvo

**Epic:** EPIC-16 — Insights e Recomendação
**Status:** ⬜ Pendente
**Depende de:** TASK-121 (engine base de insights), TASK-096 (pedido em rascunho — origem dos dados de estado e última alteração do rascunho)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Implementar as regras de insight "pedidos abandonados" e "carrinhos salvos" (seção 11 de `tasks.md`), detectando rascunhos de pedido parados há mais de X horas/dias sem submissão, com ação recomendada de retomada ou contato com o cliente.

## Escopo técnico

- Criar `AbandonedDraftOrderInsightRule` implementando `InsightRule`, consumindo pedidos com status `draft` (TASK-096) e a data/hora da última alteração de conteúdo do rascunho.
- Definir dois níveis de severidade configuráveis por organização: "carrinho salvo" (parado recentemente, ex.: acima de 24h sem alteração) e "pedido abandonado" (ultrapassou o limite maior configurado, ex.: 72h, sem nenhuma interação).
- Montar evidência: data/hora da última alteração do rascunho, itens/quantidade já incluídos, valor estimado do rascunho, cliente vinculado.
- Calcular impacto estimado como o valor total já somado dos itens incluídos no rascunho (receita potencial em risco).
- Configurar `quickAction`: "Retomar pedido" (reabre o rascunho exatamente no estado em que foi deixado) e "Contatar cliente" (quando o rascunho foi iniciado em contexto de atendimento).

## Regras de negócio e restrições

- Rascunhos com sincronização pendente na Outbox (TASK-108) não devem ser confundidos com abandono — a regra considera apenas ausência de alteração de conteúdo, nunca pendência de sincronização.
- Rascunho vinculado a cliente/produto excluído ou tabela de preço expirada deve ser sinalizado com aviso adicional na ação "retomar pedido", nunca reaberto silenciosamente sem alerta.
- Limites de horas/dias para cada severidade configuráveis por organização.

## Testes obrigatórios

- Teste com rascunho parado exatamente no limite de horas de cada severidade (borda) e além do limite.
- Teste diferenciando corretamente "carrinho salvo" de "pedido abandonado" conforme os thresholds configurados.
- Teste com rascunho pendente apenas de sincronização na Outbox (não deve ser tratado como abandonado).
- Teste da ação "retomar pedido" restaurando o estado exato do rascunho (itens, quantidades, cliente).

## Critérios de aceite

- Insight só considera rascunhos realmente parados por ausência de conteúdo alterado, nunca pendências de sincronização.
- Ação "retomar pedido" reabre o rascunho no estado exato em que foi deixado pelo usuário.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
