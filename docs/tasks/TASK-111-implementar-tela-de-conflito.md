# TASK-111 — Implementar tela de conflito

**Epic:** EPIC-14 — Offline e Sincronização
**Status:** ⬜ Pendente
**Depende de:** TASK-110 (ConflictRecord persistido pela resolução de conflitos — a tela consome esses registros)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Criar a interface que exibe conflitos de sincronização de forma compreensível ao vendedor/gestor — o que mudou na versão local vs. na versão remota — permitindo escolha explícita quando a política de resolução exigir decisão manual (pedidos e dados financeiros/críticos).

## Escopo técnico

- Criar página de lista de conflitos pendentes, exibindo os `ConflictRecords` com status `conflict`, priorizando os mais antigos e os de maior impacto (pedidos primeiro).
- Criar tela de detalhe de conflito individual, comparando a versão local e a versão remota (lado a lado no desktop, empilhado no mobile), destacando exatamente os campos divergentes — com rótulos de negócio, nunca nomes técnicos de campo.
- Implementar ações explícitas: "Manter minha versão", "Usar versão do servidor" e, quando aplicável, "Mesclar campo a campo" (seleção individual por campo quando a entidade permitir merge parcial supervisionado).
- Exibir contexto do conflito: quando ocorreu, qual usuário/dispositivo gerou a alteração remota (quando disponível) e o que acontece com a escolha (ex.: "isso vai reenviar o pedido com estes valores").
- Integrar com um `ConflictResolutionCubit` que aciona o `ConflictResolutionService` (TASK-110) para persistir a decisão do usuário e reenfileirar a operação corrigida na Outbox.
- Tratar estados: lista vazia (nenhum conflito pendente), loading, erro ao carregar, conflito resolvido com sucesso, falha ao aplicar a resolução.

## Regras de negócio e restrições

- A tela nunca aplica uma resolução automaticamente para pedidos/dados financeiros — sempre exige escolha explícita do usuário.
- Nunca esconder qual valor é local e qual é remoto — rótulos claros e consistentes em toda a tela.
- Ação de resolução só é irreversível após confirmação explícita (diálogo de confirmação para descarte de dados).
- Não usar apenas cor para indicar campo divergente — também texto/ícone, por acessibilidade.

## Testes obrigatórios

- Teste de widget da lista de conflitos: vazio, com itens, erro de carregamento.
- Teste de widget do detalhe de conflito: destaque correto dos campos divergentes, ação "manter local", ação "usar remoto", merge campo a campo quando aplicável.
- Teste de integração do Cubit garantindo que a escolha do usuário aciona o serviço de resolução correto e reenfileira a operação.
- Teste de acessibilidade/contraste garantindo que a divergência não depende só de cor.
- Golden tests da tela de conflito em mobile e desktop.

## Critérios de aceite

- Usuário consegue visualizar e resolver conflitos de pedidos/dados críticos de forma explícita e compreensível.
- Nenhuma resolução crítica ocorre sem ação manual confirmada.
- Estados de loading/vazio/erro tratados.
- `flutter analyze`, `dart format --set-exit-if-changed .` e os testes (unitários e de widget) passam.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
