# TASK-025 — Criar layouts responsivos

**Epic:** EPIC-02 — Design System
**Status:** ⬜ Pendente
**Depende de:** TASK-020 (foundations do Design System, em especial `app_breakpoints.dart`).

## Agentes obrigatórios

- `flutter-ui-design-specialist`

## Objetivo

Criar a camada de layouts responsivos do Design System (`design_system/layouts/`), incluindo o shell de navegação adaptativo que muda entre bottom navigation/drawer (mobile) e sidebar permanente (desktop/Web), e o padrão centralizado de uso de `LayoutBuilder` por breakpoint. Esta task garante que o VestiPro tenha telas verdadeiramente responsivas em vez de versões mobile esticadas, conforme exigido nas seções 6, 26 e 27 de `tasks.md`.

## Escopo técnico

- Criar shell de navegação adaptativo: bottom navigation + possível drawer secundário no mobile; menu lateral (drawer) recolhível no tablet; sidebar permanente com item ativo destacado no desktop/Web.
- Criar componente/mixin central de resolução de breakpoint (usando `app_breakpoints.dart` da TASK-020) para ser reutilizado por qualquer tela que precise de layout condicional, evitando `MediaQuery.of(context).size.width` espalhado pelo código.
- Criar layout padrão de página administrativa (cabeçalho + área de conteúdo + filtros laterais no desktop / bottom sheet no mobile) reutilizável pelas telas de usuários, clientes, produtos, pedidos.
- Criar guia/documentação de quando usar cada breakpoint (mobile/tablet/desktop/largeDesktop), incluindo casos de teste em tamanhos intermediários.
- Garantir compatibilidade do shell com o roteamento (`go_router`) definido na TASK-007, sem acoplar o layout a rotas específicas (o shell recebe o conteúdo/rota ativa como parâmetro).

## Regras de negócio e restrições

- Proibido duplicar telas completas por plataforma (uma tela mobile e outra desktop separadas) — usar composição condicional dentro do mesmo widget/página via breakpoint.
- O shell de navegação não decide permissões de acesso a itens de menu — apenas exibe os itens permitidos, com a decisão de RBAC vinda da camada de domínio (integração prevista com TASK-029, quando disponível).
- Sidebar permanente no desktop deve preservar estado (item ativo, colapsado/expandido) entre navegações.
- Bottom navigation no mobile deve ter no máximo os itens essenciais definidos pelo produto (evitar sobrecarga visual).
- Nenhum layout pode introduzir rolagem horizontal na página inteira (apenas em containers internos quando estritamente necessário).

## Testes obrigatórios

- Teste de widget do shell cobrindo troca de layout ao redimensionar entre mobile, tablet e desktop.
- Teste de widget garantindo que o mesmo shell não duplica lógica de navegação entre as variantes (mobile/tablet/desktop compartilham o mesmo estado de rota ativa).
- Teste de widget do layout padrão de página administrativa cobrindo posição dos filtros (bottom sheet no mobile vs. painel lateral no desktop).
- Golden tests do shell em mobile, tablet, desktop e largeDesktop.
- Teste em tamanho de tela intermediário (entre breakpoints) validando que não há quebra visual abrupta.

## Critérios de aceite

- Shell de navegação adaptativo funciona corretamente nas quatro faixas de breakpoint sem duplicação de código de tela.
- Uso de `LayoutBuilder`/resolução de breakpoint centralizado documentado e adotado como padrão único no projeto.
- Layout padrão de página administrativa pronto para reuso pelas features futuras (usuários, clientes, produtos, pedidos).
- `flutter analyze` e `dart format --set-exit-if-changed .` sem erros; testes de widget e golden tests passando.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
