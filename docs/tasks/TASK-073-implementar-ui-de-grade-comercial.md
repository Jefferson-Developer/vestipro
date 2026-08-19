# TASK-073 — Implementar UI de grade comercial

**Epic:** EPIC-09 — Cores, Grades e Variantes
**Status:** ⬜ Pendente
**Depende de:** TASK-072 (Implementar geração de variantes produto-cor-tamanho) — a grade exibe e edita quantidades sobre as variantes já geradas; TASK-024 (Criar componentes de catálogo) — fornece o componente base de grade do Design System.

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar a UI de grade comercial (cor × tamanho) para digitação rápida de quantidade por variante, com navegação por teclado numérico entre células e totais por cor, tamanho e produto sempre atualizados em tempo real.

## Escopo técnico

- Criar tela/widget de grade comercial reutilizando o componente base criado na TASK-024, adaptado para digitação rápida de quantidade por variante.
- Implementar navegação entre células via teclado numérico (mobile) e tab/enter (Web), avançando na ordem de tamanhos definida pelo template (ver TASK-075), sem depender de toque preciso em campos pequenos.
- Calcular totais em tempo real por cor, por tamanho e por produto, recalculados a cada alteração de célula sem lag perceptível.
- Exibir indicação visual de disponibilidade por variante (pronta entrega, futuro, indisponível) sem poluir a grade (ex.: cor sutil ou ícone pequeno, nunca bloqueando a leitura da quantidade).
- Preservar os valores digitados mesmo em caso de perda de conexão, com persistência local imediata, sem esperar sincronização.
- Garantir layout responsivo: grade compacta com rolagem controlada no mobile, grade completa e densa no desktop.

## Regras de negócio e restrições

- A grade não decide preço nem valida estoque definitivo — apenas exibe o que a camada de domínio fornece (disponibilidade, preço); nenhuma regra de negócio na UI.
- Quantidade digitada não pode ser perdida por erro de sincronização nem por navegação entre telas.
- Totais exibidos devem sempre corresponder exatamente à soma das células — nunca um cálculo divergente feito só na UI.

## Testes obrigatórios

- Teste de widget cobrindo digitação, navegação entre células por teclado e atualização de totais.
- Teste garantindo que valores digitados sobrevivem à perda de conexão simulada.
- Golden tests da grade em mobile e desktop, com e sem indicadores de disponibilidade.
- Teste de acessibilidade (navegação por teclado, foco visível) na versão Web.

## Critérios de aceite

- Digitação rápida por tamanho funcional, com navegação por teclado numérico e tab/enter.
- Totais por cor/tamanho/produto sempre corretos e atualizados em tempo real.
- Indicador de disponibilidade presente sem poluir visualmente a grade.
- `dart format`, `flutter analyze` e `flutter test` sem erros; evidências visuais (golden tests) geradas.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
