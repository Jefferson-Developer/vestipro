# TASK-075 — Implementar ordenação personalizada de tamanhos

**Epic:** EPIC-09 — Cores, Grades e Variantes
**Status:** ⬜ Pendente
**Depende de:** TASK-071 (Implementar templates de grade de tamanho) — o score/ordem de cada tamanho é definido no template; esta task garante que a ordenação é aplicada de ponta a ponta em toda a UI.

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Garantir que os templates de grade definem um score/ordem explícita (não alfabética) para os tamanhos, preservando a ordem comercial (ex.: PP antes de P antes de M), e que essa ordenação é aplicada de forma consistente em toda a interface que exibe tamanhos.

## Escopo técnico

- Garantir que cada `Size` dentro de um `SizeGridTemplate` (criado na TASK-071) possua um campo de ordem/score explícito e obrigatório.
- Garantir que toda consulta/listagem de tamanhos (grade comercial, detalhe de produto no catálogo, formulário de cadastro, relatórios que exibem tamanho) ordena explicitamente pelo score do template, nunca por ordem alfabética ou padrão de coleção.
- Criar utilitário compartilhado (extension ou comparator central) para a ordenação, evitando reimplementação divergente em cada tela.
- Cobrir casos como "PP antes de P antes de M" e grades numéricas (34 antes de 36), garantindo que a ordenação funciona tanto para rótulos alfabéticos quanto numéricos.

## Regras de negócio e restrições

- A ordenação nunca pode depender de ordenação alfabética de string como fallback silencioso — score ausente deve ser tratado como erro de dado, nunca "adivinhado".
- Toda nova tela que liste tamanhos deve obrigatoriamente usar o utilitário central de ordenação; ordenação ad-hoc não deve ser aceita em revisão de código.

## Testes obrigatórios

- Testes unitários do comparator/utilitário cobrindo grades alfabéticas (PP/P/M/G/GG/XGG), numéricas (34-46) e mistas (P/M/G/G1/G2/G3).
- Teste garantindo que grade comercial, detalhe de produto e formulário de cadastro exibem os tamanhos na mesma ordem para o mesmo template.
- Teste de regressão para score ausente/inconsistente (deve falhar de forma explícita, nunca ordenar errado silenciosamente).

## Critérios de aceite

- Ordenação comercial (não alfabética) aplicada consistentemente em toda a UI que exibe tamanhos.
- Utilitário central de ordenação único e reutilizado, sem lógica duplicada entre telas.
- `dart format`, `flutter analyze` e `flutter test` sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
