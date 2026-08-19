# TASK-071 — Implementar templates de grade de tamanho

**Epic:** EPIC-09 — Cores, Grades e Variantes
**Status:** ⬜ Pendente
**Depende de:** TASK-064 (Modelar Product) — template de grade é associado à entidade `Product` já modelada.

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar templates de grade de tamanho configuráveis por organização (PP/P/M/G/GG/XGG, numérico 34-46, 1-5, Único, P/M/G/G1/G2/G3, entre outros), reutilizáveis entre múltiplos produtos, com tamanhos ordenáveis dentro de cada template.

## Escopo técnico

- Criar entidade `SizeGridTemplate` (nome, lista ordenada de tamanhos, `organizationId`) cobrindo os exemplos da seção 7.2 de `tasks.md`.
- Criar entidade `Size` dentro do template com valor (label), ordem/score explícito (base para a TASK-075) e `organizationId`.
- Criar CRUD administrativo de templates de grade, reutilizável entre múltiplos produtos (associação produto → template, sem recriar tamanhos por produto).
- Implementar reordenação manual dos tamanhos dentro de um template (drag-and-drop no Web, ação explícita no mobile), refletindo a ordem comercial, nunca a alfabética.
- Permitir duplicar um template existente como ponto de partida para um novo (ex.: partir de "PP-GG" para criar a variação "PP-XGG").

## Regras de negócio e restrições

- Template pertence a uma organização; não é compartilhado entre tenants.
- Alterar tamanhos/ordem de um template já usado por produtos publicados deve avisar explicitamente sobre o impacto antes de confirmar.
- Remover um tamanho de um template em uso deve bloquear ou exigir confirmação explícita quando já existirem variantes geradas com aquele tamanho (integração com TASK-072).
- Nome de template deve ser único por organização, para evitar confusão entre templates equivalentes.

## Testes obrigatórios

- Testes unitários de CRUD de template e de validação de nome único por organização.
- Teste de reordenação de tamanhos dentro do template preservando o score/ordem (base para TASK-075).
- Teste de bloqueio/confirmação ao remover tamanho já usado em variantes existentes.
- Teste de widget da tela de gestão de templates (criar, duplicar, reordenar).

## Critérios de aceite

- Templates de grade configuráveis e reutilizáveis entre produtos.
- Reordenação de tamanhos funcional e persistida.
- Proteção contra remoção insegura de tamanho em uso implementada e testada.
- `dart format`, `flutter analyze` e `flutter test` sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
