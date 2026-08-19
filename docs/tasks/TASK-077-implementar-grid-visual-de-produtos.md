# TASK-077 — Implementar grid visual de produtos

**Epic:** EPIC-10 — Catálogo Premium
**Status:** ⬜ Pendente
**Depende de:** TASK-072 (geração de variantes produto-cor-tamanho, necessária para exibir cores/disponibilidade no card), TASK-024 (componentes de catálogo do Design System — grid, card, stepper)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar o grid visual de produtos do catálogo, com foco em fotografia de produto, carregamento
progressivo e performance percebida. É o componente mais reutilizado do catálogo (home, busca,
coleção, campanha, favoritos) e deve ser tratado como peça central do Design System de catálogo.

## Escopo técnico

- Criar `ProductGridBloc` com paginação por cursor (nunca carregar o catálogo inteiro de uma vez),
  preservando itens já carregados ao paginar e ao voltar de uma tela de detalhe.
- Implementar `ProductCard` no Design System (`design_system/components/catalog/`) reservando
  espaço fixo para a imagem (aspect ratio definido) para eliminar layout shift.
- Usar `cached_network_image` com placeholder/skeleton no primeiro carregamento e fallback visual
  para imagem ausente ou com erro de carregamento.
- Implementar lazy load de imagens fora da viewport (builders/slivers) e pré-carregamento
  moderado das próximas linhas.
- Expor no card: imagem principal, nome, marca/coleção, swatches de cor disponíveis, faixa de
  preço da tabela ativa, disponibilidade, no máximo dois badges simultâneos (ex.: lançamento +
  oferta).
- Adaptar número de colunas por breakpoint (`mobile`, `tablet`, `desktop`, `largeDesktop`) via
  `LayoutBuilder` centralizado, sem duplicar telas por plataforma.
- Registrar `product_viewed` ao abrir o detalhe a partir do card e evento de impressão de grid
  quando aplicável.

## Regras de negócio e restrições

- Preço e disponibilidade exibidos vêm da tabela de preço e do saldo por variante vigentes da
  empresa/unidade ativa — nunca um valor calculado ou cacheado indefinidamente na UI.
- Nunca simular estoque baixo ou urgência falsa; preço "de/por" só quando houver origem confiável
  (ex.: campanha registrada).
- Grid deve funcionar com cache local quando offline, sinalizando que os dados podem estar
  desatualizados.
- Card não pode esconder preço, disponibilidade ou condição atrás de hover ou passo extra.

## Testes obrigatórios

- Testes de bloc: primeira página, próxima página, página duplicada/concorrente, erro em página
  intermediária preservando itens já exibidos, offline com cache local, lista vazia.
- Golden tests do `ProductCard` para: com/sem imagem, título longo, texto ampliado, com dois
  badges, sem badge, sem cor disponível.
- Testes de widget para grid em mobile (1–2 colunas), tablet (2–3 colunas) e desktop (4+ colunas).
- Teste de performance/skeleton garantindo que o placeholder ocupa o mesmo espaço da imagem final
  (sem layout shift mensurável).
- Teste de analytics do evento `product_viewed`.

## Critérios de aceite

- Rolagem contínua sem duplicar ou perder produtos já carregados.
- Nenhum layout shift perceptível entre skeleton e imagem carregada.
- Grid responsivo validado em mobile, tablet e desktop.
- Preço e disponibilidade sempre refletem tabela/estoque vigentes, nunca valor hardcoded ou obsoleto
  sem indicação.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
