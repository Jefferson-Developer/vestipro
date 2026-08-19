# TASK-076 — Implementar home do catálogo

**Epic:** EPIC-10 — Catálogo Premium
**Status:** ⬜ Pendente
**Depende de:** TASK-077 (grid visual de produtos, reutilizado nos carrosséis de destaque), TASK-066 (coleções e estações, fonte dos agrupamentos exibidos na home)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar a tela inicial do catálogo digital, ponto de entrada do vendedor e do cliente para
explorar produtos. A home deve destacar coleções em vitrine, lançamentos, campanhas ativas e
oportunidades comerciais (mais vendidos, recomendados, pronta entrega) com uma experiência visual
de nível de marca de moda, sem virar uma lista infinita de seções desconexas.

## Escopo técnico

- Criar `CatalogHomeBloc`/`CatalogHomeCubit` que orquestra a busca das seções (coleções em
  destaque, lançamentos, mais vendidos, recomendados, pronta entrega, campanhas) via casos de uso
  independentes, permitindo que cada seção carregue e falhe isoladamente.
- Modelar `CatalogHomeSection` (tipo, título, produtos/coleções, ordem, prioridade) no domínio, para
  que a composição da home seja orientada por dados (Remote Config ou coleção de configuração),
  não hardcoded na página.
- Reaproveitar o grid/card de produto do Design System (`TASK-024`/`TASK-077`) para os carrosséis
  horizontais; não criar um card de produto alternativo específico da home.
- Cachear localmente a última home carregada para exibição instantânea (stale-while-revalidate) e
  permitir uso offline com indicação de dado desatualizado.
- Registrar evento de analytics `catalog_home_viewed` e evento por seção clicada
  (`catalog_section_opened` com o tipo da seção).
- Aplicar RBAC/escopo de organização e empresa ativa nas consultas (nunca listar produtos de outra
  organização).

## Regras de negócio e restrições

- Priorizar no máximo 4–6 seções simultâneas na tela; seções sem conteúdo relevante não devem ser
  exibidas (nunca mostrar uma seção vazia com título).
- "Mais vendidos" e "recomendados" devem vir de agregação server-side (ver EPIC-16/17), nunca de
  cálculo client-side varrendo pedidos.
- Nenhuma seção pode simular urgência falsa (ex.: "restam poucas peças" sem dado real de estoque).
- Respeitar tabela de preço e disponibilidade vigentes da empresa/unidade ativa do usuário ao
  exibir qualquer produto na home.
- Conteúdo de coleções/campanhas em destaque deve ser atualizável sem deploy de app (ver TASK-080).

## Testes obrigatórios

- Testes de bloc/cubit cobrindo: carregamento inicial, sucesso parcial (uma seção falha e as
  demais carregam), todas as seções vazias, falha total, uso de cache offline.
- Testes de widget para layout mobile (uma coluna, carrosséis horizontais), tablet e desktop
  (múltiplas colunas/seções lado a lado).
- Teste garantindo que seções sem dados não renderizam título/contêiner vazio.
- Teste de analytics validando disparo de `catalog_home_viewed` e `catalog_section_opened`.
- Teste de acessibilidade (leitor de tela navega pelas seções e pelos carrosséis).

## Critérios de aceite

- Home carrega em estado de loading com skeleton, depois exibe seções reais sem layout shift.
- Falha em uma seção não derruba a tela inteira; demais seções continuam funcionais.
- Layout aproveita o espaço extra em tablet/desktop sem apenas esticar o layout mobile.
- Navegação por teclado funcional no Flutter Web entre seções e itens.
- Dados exibidos respeitam organização/empresa ativa e tabela de preço vigente do usuário.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
