# TASK-021 — Criar componentes base

**Epic:** EPIC-02 — Design System
**Status:** ⬜ Pendente
**Depende de:** TASK-020 (foundations do Design System) — todos os componentes desta task devem consumir exclusivamente os tokens ali definidos.

## Agentes obrigatórios

- `flutter-ui-design-specialist`

## Objetivo

Criar os componentes visuais fundamentais do Design System (`design_system/components/`): botões, inputs, dropdowns, chips, badges, skeleton, empty state e error state. Esses componentes serão reutilizados em praticamente todas as telas do VestiPro (autenticação, clientes, produtos, pedidos, dashboards) e por isso precisam suportar todas as variantes previstas desde já, evitando duplicação futura.

## Escopo técnico

- Criar componentes de botão: primário, secundário, textual, destrutivo e ícone — todos com estados normal, hover (Web), pressed, disabled e loading (spinner substituindo o label, sem redimensionar o botão).
- Criar inputs: campo de texto padrão, campo numérico (com teclado numérico no mobile), campo de busca com debounce visual e botão de limpar.
- Criar dropdown/seletor único e múltiplo, com suporte a busca interna para listas longas.
- Criar chip de filtro (selecionável/removível) reutilizável em telas de catálogo, clientes e relatórios.
- Criar badge de status (ex.: pedido, cliente, sincronização) com variantes de cor mapeadas semanticamente (sucesso/erro/aviso/info/neutro), nunca dependendo apenas de cor para o significado (incluir ícone ou texto).
- Criar skeleton loading reutilizável (linha, bloco, card) parametrizável por tamanho.
- Criar empty state genérico configurável (ícone/ilustração, título, descrição, ação opcional) para reuso em listas vazias de qualquer feature.
- Criar error state genérico configurável (mensagem amigável, ação "tentar novamente"), nunca expondo erro técnico cru ao usuário final.
- Todos os componentes devem usar exclusivamente tokens de `design_system/foundations/` (TASK-020) — nenhuma cor/espaçamento/radius arbitrário.

## Regras de negócio e restrições

- Nenhum componente pode conter regra de negócio, chamada a repositório/Firestore ou lógica de autorização — apenas apresentação e callbacks.
- Botões em estado de processamento devem impedir duplo envio (double-tap) por padrão.
- Empty state e error state devem ser genéricos e configuráveis por parâmetro — não criar uma versão por feature.
- Todos os componentes devem funcionar em mobile, tablet e Web (incluindo foco de teclado nos inputs/dropdowns na Web).
- Textos de botões e mensagens de erro devem ser passados via parâmetro/i18n, nunca hardcoded no componente.
- Áreas de toque devem respeitar tamanho mínimo acessível.

## Testes obrigatórios

- Testes de widget para cada variante de botão (estados normal/disabled/loading) validando que loading não duplica evento de tap.
- Testes de widget para inputs cobrindo texto vazio, texto longo, erro de validação exibido e campo obrigatório destacado.
- Teste de widget do dropdown cobrindo seleção única, múltipla e busca interna.
- Teste de widget do chip cobrindo estado selecionado/não selecionado e remoção.
- Teste de widget do empty state e error state cobrindo presença de título, descrição e ação configurada.
- Golden tests para botão, input, badge e skeleton em tema claro e escuro.

## Critérios de aceite

- Todos os componentes listados em "Escopo técnico" existem, documentados com exemplo de uso mínimo.
- Nenhum componente referencia cor/espaçamento/radius fora dos tokens da TASK-020.
- Componentes aprovados em teste de widget e golden test (claro/escuro).
- `flutter analyze` e `dart format --set-exit-if-changed .` sem erros.
- Componentes acessíveis: labels semânticos, foco visível, contraste adequado, áreas de toque mínimas.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
