# TASK-112 — Implementar central de sincronização

**Epic:** EPIC-14 — Offline e Sincronização
**Status:** ⬜ Pendente
**Depende de:** TASK-109 (motor de sincronização, fonte de eventos de progresso/falha), TASK-111 (tela de conflito, para onde a central linka quando há conflitos)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Criar a tela que dá transparência total ao usuário sobre o estado de seus dados offline: última sincronização bem-sucedida, itens pendentes na Outbox, falhas recentes e opção de retry manual — para que o vendedor nunca fique sem entender por que uma ação "parece travada".

## Escopo técnico

- Criar a página Central de Sincronização exibindo: timestamp da última sincronização completa por entidade (clientes, produtos, pedidos, etc. — usando o marcador de carga da TASK-107 e os cursores da TASK-109), contagem de itens pending/syncing/failed/conflict na Outbox, e lista detalhada dos itens com falha (com motivo legível, nunca erro técnico cru).
- Implementar ação "Sincronizar agora" (retry manual) que aciona o motor de sincronização (TASK-109) sob demanda, com feedback de progresso.
- Implementar ação "Tentar novamente" por item individual da Outbox com falha, além de um botão de retry em lote para todos os itens `failed`.
- Linkar itens com status `conflict` diretamente para a tela de conflito (TASK-111).
- Exibir indicação clara de quando o usuário está offline (nenhuma tentativa de sincronizar será feita até reconexão) versus online mas com falhas reais.
- Adicionar eventos de Analytics (`sync_center_opened`, `sync_manual_retry_triggered`) e enriquecer Crashlytics/logs quando uma falha de sincronização é exibida ao usuário.

## Regras de negócio e restrições

- A central nunca mostra dados de outra organização/empresa — mesmo isolamento multi-tenant do restante do app.
- Falhas exibidas ao usuário nunca mostram stack trace ou exceção técnica crua — sempre mensagem de negócio (ex.: "Não foi possível confirmar este pedido, verifique sua conexão e tente novamente").
- Retry manual não permite disparo duplicado enquanto uma sincronização já está em andamento (desabilitar ação/mostrar estado "sincronizando").
- Itens em `conflict` não são reenviados por "tentar novamente" simples — precisam passar pela tela de resolução (TASK-111).

## Testes obrigatórios

- Teste de widget cobrindo: nenhuma pendência (tudo sincronizado), pendências em andamento, falhas presentes, conflitos presentes, offline.
- Teste de integração do retry manual acionando o motor de sincronização e refletindo o novo estado na tela.
- Teste garantindo que o link de um item `conflict` abre a tela de conflito correta (TASK-111).
- Teste garantindo que mensagens de erro exibidas nunca contêm texto técnico cru.
- Golden tests da central em mobile e desktop.

## Critérios de aceite

- Usuário visualiza última sincronização, pendências e falhas de forma clara, sem termos técnicos.
- Retry manual (individual e em lote) funcional.
- Itens em conflito direcionam para resolução manual.
- `flutter analyze`, `dart format --set-exit-if-changed .` e os testes passam.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
