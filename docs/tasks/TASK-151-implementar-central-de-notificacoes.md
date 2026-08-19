# TASK-151 — Implementar central de notificações internas

**Epic:** EPIC-19 — Notificações e Engajamento
**Status:** ⬜ Pendente
**Depende de:** TASK-150 (Firebase Cloud Messaging, origem de parte das notificações), TASK-020
(foundations do Design System, para o componente de item/badge de notificação)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar a central de notificações internas do VestiPro: listagem de alertas (lidos/não lidos,
por categoria) com deep link para a tela relevante (pedido, cliente, insight, oportunidade etc.),
servindo de base para as notificações de CRM (TASK-152) e comerciais (TASK-153).

## Escopo técnico

- Modelar `Notification` mapeando para
  `organizations/{organizationId}/notifications/{notificationId}` (destinatário, categoria, título,
  corpo curto, lida/não lida, deepLink, criadoEm, origem).
- `NotificationCenterBloc`: listagem paginada, marcar como lida/todas como lidas, contador de não
  lidas (badge), filtro por categoria (CRM, comercial, sistema).
- Componente de Design System: item de notificação (ícone por categoria, indicador de não lida) e
  badge de contador no ícone de navegação — reaproveitar componentes existentes (TASK-020/TASK-023),
  não criar componente isolado.
- Deep link: ao tocar na notificação, navegar para a tela relevante usando rotas tipadas do
  `go_router`.
- Persistir notificações localmente para acesso offline (últimas N sincronizadas).

## Regras de negócio e restrições

- Notificação pertence sempre a um destinatário específico dentro de uma organização; nunca listar
  notificação de outro usuário.
- Notificação lida há muito tempo pode ser arquivada conforme política de retenção (evitar lista
  infinita), alinhada com TASK-160.
- Deep link para entidade excluída ou fora do escopo do usuário trata o erro de forma amigável (ex.:
  "este item não está mais disponível"), nunca quebra a navegação.
- A central reflete tanto notificações originadas de push (TASK-150) quanto eventos internos sem
  push (ex.: usuário com push desabilitado).

## Testes obrigatórios

- Teste de bloc: listagem paginada, marcar lida/todas lidas, contador de não lidas atualizando em
  tempo real.
- Teste de deep link para entidade existente e para entidade removida (tratamento de erro).
- Teste de isolamento multi-tenant/usuário (notificação de outro usuário nunca aparece).
- Teste de widget: estado vazio, filtro por categoria, item lido vs. não lido diferenciado sem
  depender só de cor.
- Teste de acesso offline às últimas notificações sincronizadas.

## Critérios de aceite

- Usuário visualiza, filtra e marca notificações como lidas com o contador sempre correto.
- Toque na notificação navega corretamente para a tela relevante ou trata o erro de forma amigável.
- Notificações continuam acessíveis (últimas sincronizadas) sem conexão.
- Nenhuma notificação de outro usuário/organização é exposta.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura
  de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
