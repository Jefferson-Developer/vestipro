# TASK-067 — Implementar categorias e subcategorias

**Epic:** EPIC-08 — Produtos e Catálogo Base
**Status:** ⬜ Pendente
**Depende de:** TASK-064 (Modelar Product) — categoria/subcategoria se associam à entidade `Product` já modelada.

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar a árvore hierárquica configurável de categorias e subcategorias por organização, usada tanto no cadastro de produtos quanto nos filtros do catálogo, garantindo uma única fonte de verdade de taxonomia.

## Escopo técnico

- Criar entidade `Category` com suporte a hierarquia (`parentId` opcional), permitindo ao menos dois níveis (categoria > subcategoria), com estrutura já preparada para N níveis no futuro.
- Criar CRUD administrativo de categorias/subcategorias configurável por organização, com reordenação manual (drag-and-drop no Web, ação explícita no mobile).
- Integrar a mesma árvore na seleção de categoria/subcategoria do formulário de cadastro de produto (TASK-065).
- Reutilizar a mesma estrutura nos filtros de catálogo (EPIC-10), evitando duplicar taxonomia entre cadastro e vitrine.
- Implementar validação de ciclo: uma categoria não pode se tornar subcategoria de si mesma nem de um descendente seu.

## Regras de negócio e restrições

- Categoria pertence a uma organização; a árvore não é compartilhada entre tenants.
- Excluir categoria com produtos vinculados deve bloquear a exclusão ou exigir realocação explícita dos produtos — nunca deixar produto órfão silenciosamente.
- Reordenação não pode quebrar a hierarquia existente: mover uma subcategoria para fora de sua categoria pai exige ação explícita, nunca um drag acidental.

## Testes obrigatórios

- Testes unitários de validação de ciclo na árvore de categorias.
- Testes do caso de uso de exclusão de categoria com produtos vinculados (bloqueio ou realocação).
- Teste de widget da árvore de categorias (seleção, reordenação) em mobile e desktop.
- Teste de integração confirmando que o filtro de catálogo reflete exatamente a mesma árvore usada no cadastro.

## Critérios de aceite

- Árvore de categorias hierárquica funcional, reutilizada de forma idêntica em cadastro e filtros de catálogo.
- Proteção contra ciclos e contra exclusão insegura implementada e testada.
- Responsivo (drag-and-drop no Web, alternativa acessível no mobile).
- `dart format`, `flutter analyze` e `flutter test` sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
