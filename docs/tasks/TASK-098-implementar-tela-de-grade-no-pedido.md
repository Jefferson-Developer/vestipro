# TASK-098 — Implementar tela de grade no pedido

**Epic:** EPIC-13 — Pedidos
**Status:** ⬜ Pendente
**Depende de:** TASK-096 — Implementar pedido em rascunho (grade alimenta os itens de um rascunho existente); TASK-073 — Implementar UI de grade comercial (componente a ser reutilizado, não recriado)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Reutilizar o componente de grade comercial do Design System dentro do fluxo de pedido, agilizando a venda por cor/tamanho com totais por cor, por tamanho e por produto sempre visíveis durante a digitação.

## Escopo técnico

- Reutilizar o componente de grade comercial já existente (TASK-073) dentro da tela de pedido — sem duplicar ou recriar a grade especificamente para pedidos.
- Conectar a grade ao `OrderDraftBloc`: cada célula preenchida (cor × tamanho) gera ou atualiza o `OrderItem` correspondente à variante daquela combinação.
- Exibir totais por cor, por tamanho e por produto sempre visíveis durante a digitação, calculados a partir do estado do rascunho.
- Indicar visualmente a disponibilidade por variante na grade (pronta entrega/estoque futuro/indisponível, vindo de TASK-090/TASK-091) sem poluir a grade.
- Preservar a navegação rápida entre células (tab/enter avança) e o teclado numérico inteligente já definidos como padrão do componente.

## Regras de negócio e restrições

- A grade não é responsável pelo bloqueio definitivo de quantidade além da disponibilidade — isso é responsabilidade de TASK-100; aqui há apenas indicação visual.
- Valores digitados na grade não podem ser perdidos por perda de conexão — a grade opera 100% sobre o estado local do rascunho.

## Testes obrigatórios

- Teste de widget da grade preenchendo múltiplas células e validando totais por cor/tamanho/produto.
- Teste garantindo que a grade usada aqui é a mesma implementação/componente de TASK-073 (sem duplicação de código).
- Teste de perda de conexão simulada durante o preenchimento da grade sem perda de dados digitados.
- Teste de acessibilidade (navegação por teclado entre células) no Web.

## Critérios de aceite

- Grade comercial reutilizada sem duplicação de componente dentro do fluxo de pedido.
- Totais por cor/tamanho/produto corretos e atualizados em tempo real durante a digitação.
- Indicação de disponibilidade por variante presente na grade sem poluir a experiência.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
