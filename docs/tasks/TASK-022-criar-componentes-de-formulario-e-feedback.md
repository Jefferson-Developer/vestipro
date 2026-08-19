# TASK-022 — Criar componentes de formulário e feedback

**Epic:** EPIC-02 — Design System
**Status:** ⬜ Pendente
**Depende de:** TASK-020 (foundations), TASK-021 (componentes base) — modais, sheets e snackbars reutilizam botões, inputs e tokens já criados.

## Agentes obrigatórios

- `flutter-ui-design-specialist`

## Objetivo

Criar os componentes de overlay e feedback do Design System (`design_system/components/overlays/` e `feedback/`): modais, bottom sheets, snackbars, tooltips e o diálogo de confirmação para ações destrutivas. Esses componentes serão usados em fluxos críticos como exclusão de cliente/produto, desativação de usuário, cancelamento de pedido e alteração de role — por isso precisam de comportamento consistente de foco, teclado e confirmação.

## Escopo técnico

- Criar modal genérico (dialog) com título, corpo configurável, ações primária/secundária, tamanho adaptado por breakpoint (largura máxima no desktop/Web, tela quase cheia no mobile quando aplicável).
- Criar bottom sheet reutilizável (para filtros no mobile, seleção de opções, ações contextuais), com suporte a arrastar para fechar e altura adaptável ao conteúdo.
- Criar snackbar padronizado para confirmações leves (ex.: "Rascunho salvo"), com fila/anti-sobreposição quando múltiplas ações disparam feedback em sequência.
- Criar tooltip reutilizável, disponível principalmente na experiência Web/desktop (hover), com fallback acessível no mobile (ex.: toque longo ou ícone de ajuda).
- Criar diálogo de confirmação específico para ações destrutivas (excluir cliente, remover usuário, cancelar pedido, excluir imagem), com texto claro do que será perdido, exigindo ação explícita (nunca destrutivo por engano com um único toque acidental).
- Garantir que todos os overlays fecham corretamente por teclado (Esc) na Web e devolvem foco ao elemento de origem ao fechar.

## Regras de negócio e restrições

- O diálogo de confirmação destrutiva nunca deve ser substituído por snackbar — ações irreversíveis exigem confirmação explícita em modal.
- Nenhum overlay pode conter regra de negócio (ex.: decidir se a exclusão é permitida) — apenas apresentar e coletar a confirmação; a decisão de permissão vem da camada de domínio/BLoC.
- Snackbars não podem se sobrepor de forma a esconder informação crítica; devem enfileirar.
- Bottom sheets no mobile não podem ser usadas para ações destrutivas sem confirmação adicional.
- Tooltips não podem ser o único canal para informação comercial essencial (preço, estoque, condição) — apenas complementar.

## Testes obrigatórios

- Teste de widget do modal cobrindo abertura, fechamento por botão, fechamento por Esc (Web) e devolução de foco.
- Teste de widget do bottom sheet cobrindo abertura, fechamento por gesto/botão e conteúdo dinâmico.
- Teste de widget do snackbar cobrindo enfileiramento de múltiplas mensagens em sequência.
- Teste de widget do diálogo de confirmação destrutiva garantindo que a ação só dispara após confirmação explícita.
- Golden tests para modal, bottom sheet e diálogo de confirmação em tema claro e escuro.

## Critérios de aceite

- Todos os componentes listados existem, usam exclusivamente tokens do Design System e têm exemplo de uso documentado.
- Diálogo de confirmação destrutiva é o único caminho oficial para ações irreversíveis no restante do backlog.
- Foco e navegação por teclado funcionam corretamente em todos os overlays na Web.
- `flutter analyze` e `dart format --set-exit-if-changed .` sem erros; testes de widget e golden tests passando.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
