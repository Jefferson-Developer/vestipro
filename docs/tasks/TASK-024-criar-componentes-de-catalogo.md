# TASK-024 — Criar componentes de catálogo (grid, grade, cor, stepper)

**Epic:** EPIC-02 — Design System
**Status:** ⬜ Pendente
**Depende de:** TASK-020 (foundations), TASK-021 (componentes base) — grid e grade reutilizam skeleton, badges e tokens já criados.

## Agentes obrigatórios

- `flutter-ui-design-specialist`

## Objetivo

Criar os componentes de catálogo e venda por grade do Design System (`design_system/components/catalog/`): grid de produtos, grade de tamanhos com entrada rápida de quantidade, seletor de cor (swatch) e stepper de quantidade. Estes são os componentes mais críticos para a experiência de venda do representante em campo (seção 26 de `tasks.md`) e para o catálogo premium (seção 10), exigindo o mínimo de toques e fricção possível.

## Escopo técnico

- Criar grid de produtos com card que reserva espaço fixo para a imagem (evitar layout shift), skeleton no primeiro carregamento, suporte a lazy load e cache de imagem (`cached_network_image`).
- Criar card de produto do grid exibindo: imagem, nome, marca/coleção, indicação de cores disponíveis, faixa de preço, disponibilidade e no máximo dois badges simultâneos (ex.: lançamento, oferta) — sem simular urgência falsa.
- Criar componente de grade de tamanhos com entrada rápida de quantidade por tamanho: navegação entre células via tab/enter, teclado numérico inteligente no mobile, totais por cor/tamanho/produto sempre visíveis durante a digitação, preservação de valores digitados mesmo em perda de conexão.
- Criar indicação visual de disponibilidade por variante (pronta entrega, futuro, indisponível) dentro da grade, sem poluir visualmente a matriz de células.
- Criar seletor de cor (swatch) que atualiza a galeria/imagem principal e a disponibilidade ao trocar de cor selecionada.
- Criar stepper de quantidade (incremento/decremento com input direto), reutilizável tanto na grade quanto em outras telas de quantidade avulsa.
- Garantir que todos os componentes suportem tablet (layout de duas colunas) e Web/desktop (grid com mais colunas, sem apenas esticar o layout mobile).

## Regras de negócio e restrições

- Estes componentes não calculam preço, desconto, total do pedido ou disponibilidade real — apenas exibem os valores recebidos via parâmetro/estado fornecido pela camada de domínio (grade e stepper emitem apenas eventos de quantidade alterada).
- A grade de tamanhos nunca pode perder os valores já digitados pelo usuário em caso de erro de rede ou re-render.
- Disponibilidade "indisponível" deve ser comunicada sem depender apenas de cor (texto/ícone também).
- Preço "de/por" só pode ser exibido quando fornecido com origem confiável pela camada de domínio — o componente não decide isso, apenas exibe se o dado existir.
- Grid de produtos não pode carregar catálogo inteiro de uma vez — deve integrar com paginação/lazy load (contrato fornecido pelo `flutter-senior-architect`).

## Testes obrigatórios

- Teste de widget do grid cobrindo: produto sem imagem, título longo, ausência de preço/estoque, skeleton inicial e lazy load.
- Teste de widget da grade de tamanhos cobrindo: matriz totalmente preenchida, navegação entre células via teclado/tab, totais recalculados corretamente, e preservação de valores após simular perda de conexão.
- Teste de widget do seletor de cor cobrindo troca de cor e atualização de disponibilidade/imagem associada.
- Teste de widget do stepper cobrindo incremento, decremento, limite mínimo (zero) e entrada direta de valor.
- Golden tests para grid de produtos, grade de tamanhos e swatch de cor em mobile, tablet e desktop.

## Critérios de aceite

- Grade de tamanhos permite preenchimento rápido com teclado numérico e nunca perde dados digitados.
- Grid de produtos evita layout shift e funciona com lazy load/skeleton.
- Seletor de cor e stepper reutilizáveis em qualquer tela que necessite (catálogo, pedido, detalhe de produto).
- Componentes testados em mobile, tablet e desktop (golden tests aprovados).
- `flutter analyze` e `dart format --set-exit-if-changed .` sem erros; testes de widget passando.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
