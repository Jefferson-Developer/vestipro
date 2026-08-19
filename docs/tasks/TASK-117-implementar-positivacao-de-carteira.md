# TASK-117 — Implementar positivação de carteira

**Epic:** EPIC-15 — Metas e Performance Comercial
**Status:** ⬜ Pendente
**Depende de:** TASK-051 (carteira de clientes implementada — a positivação mede compra dentro da carteira), TASK-115 (metas cadastradas — positivação pode ser acompanhada como meta/KPI)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Medir quantos clientes da carteira de um vendedor (ou equipe) compraram dentro de um período, com regras de "carteira ativa" configuráveis por organização, alimentando o dashboard de atingimento e futuros insights comerciais.

## Escopo técnico

- Definir uma configuração de organização (`PositivacaoSettings`) com regras parametrizáveis: janela do período (mensal/trimestral), valor mínimo de pedido para contar como "positivado" (quando aplicável) e quais status de pedido contam (ex.: approved/invoiced, não draft/cancelled).
- Criar agregação server-side calculando, por vendedor/equipe/período: total de clientes na carteira, quantidade de clientes positivados, percentual de positivação e a lista de clientes não positivados (para ação comercial).
- Criar `PositivacaoViewModel` e a página/seção exibindo o indicador (card KPI + lista de clientes pendentes de compra no período), reaproveitando componentes de card/lista do Design System.
- Integrar com a carteira de clientes (TASK-051) para a base de "clientes elegíveis" e com pedidos para o cálculo de "comprou no período".
- Permitir a configuração da regra de carteira ativa por organização em uma tela administrativa (ex.: dentro de settings) — nunca hardcoded no código, para que diferentes marcas/organizações tenham critérios distintos.

## Regras de negócio e restrições

- A regra de "positivado" (quais status de pedido contam, valor mínimo) é configurável por organização, nunca fixa no código de forma que uma organização não possa ajustar.
- O cálculo deve ser feito via agregação server-side, evitando centenas de queries do cliente por vendedor.
- Cliente removido/inativado da carteira durante o período não pode distorcer o histórico de positivação já calculado anteriormente (snapshot no momento do cálculo).
- RBAC: vendedor vê apenas a própria carteira/positivação; gestor vê a de sua equipe/empresa.

## Testes obrigatórios

- Teste da regra de positivação cobrindo: cliente com pedido dentro do período e status elegível (positivado), cliente com pedido mas status não elegível (não positivado), cliente sem pedido (não positivado), cliente com pedido abaixo do valor mínimo configurado.
- Teste de configuração por organização (duas organizações com regras diferentes produzindo resultados diferentes para os mesmos dados brutos).
- Teste de RBAC impedindo vendedor de ver a positivação de carteira de outro vendedor.
- Teste de widget cobrindo estado vazio (carteira vazia), carregado, erro.

## Critérios de aceite

- Positivação calculada corretamente conforme regra configurável por organização.
- Lista de clientes pendentes de compra no período disponível para ação comercial.
- RBAC respeitado.
- `flutter analyze`, `dart format --set-exit-if-changed .` e os testes passam.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
