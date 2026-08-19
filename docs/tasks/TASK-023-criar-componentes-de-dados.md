# TASK-023 — Criar componentes de dados (tabelas, listas, KPI, gráficos)

**Epic:** EPIC-02 — Design System
**Status:** ⬜ Pendente
**Depende de:** TASK-020 (foundations), TASK-021 (componentes base) — tabela e cards de KPI reutilizam badges, skeleton e tokens já criados.

## Agentes obrigatórios

- `flutter-ui-design-specialist`

## Objetivo

Criar os componentes de apresentação de dados do Design System (`design_system/components/tables/`, `cards/`, `charts/`): tabela administrativa responsiva, cards de métrica/KPI, componente base de gráfico gerencial e paginação. Esses componentes sustentarão todas as telas administrativas (usuários, clientes, produtos, pedidos) e os dashboards previstos na seção 12 de `tasks.md`.

## Escopo técnico

- Criar tabela administrativa reutilizável: colunas configuráveis, ordenação, seleção em lote, ações contextuais por linha, cabeçalho fixo (Web/desktop) — e conversão automática para lista de cards em telas mobile via `LayoutBuilder`/breakpoints (nunca duas implementações de tela separadas).
- Criar card de métrica/KPI (valor principal, label, variação percentual vs. período anterior, indicação visual de tendência sem depender só de cor).
- Criar componente base de gráfico gerencial (ex.: linha, barra) sem adicionar biblioteca pesada desnecessária — avaliar se `fl_chart` (já listado como opcional mediante justificativa no agente front-end) atende, documentando a decisão; se optar por construção nativa com `CustomPainter`, justificar também.
- Criar componente de paginação reutilizável (numérica e/ou "carregar mais"), compatível com paginação por cursor usada pelo `flutter-senior-architect` nos repositórios.
- Garantir que o gráfico gerencial tenha alternativa textual resumida para acessibilidade (ex.: tabela de dados subjacente ou resumo em texto).
- Garantir que a tabela administrativa suporte estados de loading (skeleton de linhas), vazio e erro reutilizando os componentes da TASK-021.

## Regras de negócio e restrições

- Nenhum componente de dados calcula métricas de negócio — apenas exibe valores já calculados/fornecidos pela camada de domínio/BLoC.
- Tabela administrativa não pode depender de rolagem horizontal sem alternativa em mobile — conversão para cards é obrigatória abaixo do breakpoint definido.
- Gráficos nunca usam pizza para muitas categorias (regra do agente front-end) — o componente base deve orientar/limitar esse uso.
- Paginação deve preservar itens já carregados ao avançar/retroceder (não recarregar do zero).
- Ações destrutivas em lote na tabela devem reutilizar o diálogo de confirmação da TASK-022, nunca implementar confirmação própria.

## Testes obrigatórios

- Teste de widget da tabela cobrindo: ordenação, seleção em lote, ação contextual, e conversão para cards abaixo do breakpoint mobile.
- Teste de widget do card de KPI cobrindo valor positivo, negativo e neutro de variação.
- Teste de widget do gráfico gerencial cobrindo dataset vazio e dataset com um único ponto (casos-limite).
- Teste de widget da paginação cobrindo avanço, retrocesso e preservação de itens já carregados.
- Golden tests para tabela (modo tabela e modo card) e card de KPI em tema claro e escuro.

## Critérios de aceite

- Tabela administrativa converte corretamente para cards no breakpoint mobile sem duplicar código de tela.
- Card de KPI e gráfico gerencial documentados com exemplo de uso e alternativa textual acessível.
- Decisão sobre biblioteca de gráfico documentada (usar `fl_chart` ou construção nativa, com justificativa).
- `flutter analyze` e `dart format --set-exit-if-changed .` sem erros; testes de widget e golden tests passando.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
