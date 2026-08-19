# TASK-082 — Implementar modos de visualização e filtros avançados

**Epic:** EPIC-10 — Catálogo Premium
**Status:** ⬜ Pendente
**Depende de:** TASK-077 (grid visual de produtos, base de todos os modos de visualização listados abaixo)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar os modos de visualização do catálogo (grid, lista, novidades, mais vendidos,
recomendados, pronta entrega, catálogo por coleção/campanha, favoritos) e o conjunto completo de
filtros avançados definidos na especificação, com persistência de filtro e de posição de rolagem ao
navegar para o detalhe de um produto e voltar.

## Escopo técnico

- Modelar `CatalogViewMode` (enum: grid, lista, lookbook, por coleção, por campanha, favoritos,
  novidades, mais vendidos, recomendados, pronta entrega) e `CatalogFilter` (coleção, estação,
  marca, categoria, cor, tamanho, faixa de preço, disponibilidade, lançamento, tags, material/
  tecido) no domínio, independentes da UI.
- Implementar `CatalogFilterBloc`/query builder que traduz o `CatalogFilter` em consulta paginada
  por cursor no repositório (Firestore/local), sem montar filtros diretamente na página.
- Persistir o último modo de visualização e o filtro ativo (por usuário, localmente) e restaurar a
  posição de rolagem do grid ao retornar do detalhe de produto (`PageStorageKey`/estado do bloc).
- Implementar UI de filtros: bottom sheet em mobile, painel lateral em tablet/desktop, com chips de
  filtro ativo removíveis individualmente.
- Refletir filtro e modo de visualização ativos na URL do Flutter Web (deep link navegável e
  compartilhável), preservando o padrão de rotas tipadas do projeto.
- Registrar evento `catalog_filtered` com os filtros aplicados (sem dados pessoais).

## Regras de negócio e restrições

- "Mais vendidos", "recomendados" e "pronta entrega" dependem de dados server-side (agregação ou
  saldo de estoque real) — nunca inferidos apenas no cliente.
- Combinações de filtro sem nenhum resultado devem exibir estado vazio explicativo, nunca grid em
  branco sem contexto.
- Filtros e modo de visualização persistidos são por usuário e por organização — nunca vazar
  preferência de filtro entre organizações diferentes no mesmo dispositivo.
- Filtro de faixa de preço deve respeitar a tabela de preço vigente do usuário/empresa ativa.

## Testes obrigatórios

- Testes de bloc: aplicar filtro único, combinar múltiplos filtros, remover filtro, filtro sem
  resultado, troca de modo de visualização mantendo filtro ativo.
- Teste de persistência: filtro e posição de rolagem restaurados corretamente ao voltar do detalhe
  de produto.
- Testes de widget: bottom sheet de filtro em mobile, painel lateral em desktop, chips de filtro
  ativo removíveis, navegação por teclado no painel de filtros (Web).
- Teste de deep link no Flutter Web: URL reflete filtro e modo de visualização e restaura o estado
  ao recarregar a página.
- Teste de analytics do evento `catalog_filtered`.

## Critérios de aceite

- Todos os modos de visualização listados na especificação (seção 10 de `tasks.md`) estão
  implementados e acessíveis.
- Todos os filtros listados na especificação estão disponíveis e combináveis entre si.
- Filtro ativo e posição de rolagem são preservados ao navegar para o detalhe de um produto e
  voltar.
- Em Flutter Web, a URL reflete o estado de filtro/modo de visualização e é compartilhável.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
