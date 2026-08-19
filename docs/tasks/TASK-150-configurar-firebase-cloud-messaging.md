# TASK-150 — Configurar Firebase Cloud Messaging

**Epic:** EPIC-19 — Notificações e Engajamento
**Status:** ⬜ Pendente
**Depende de:** TASK-011 (Integrar Firebase Core, pré-requisito para qualquer SDK Firebase adicional)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Configurar o Firebase Cloud Messaging para todas as plataformas suportadas, com ciclo de vida de
token de push tratado corretamente (registro, renovação, remoção no logout) e opt-in de notificações
respeitado por plataforma. É a base sobre a qual toda a central de notificações (TASK-151 a
TASK-155) será construída.

## Escopo técnico

- Integrar `firebase_messaging`; configurar canal de notificação Android, permissões APNs no iOS e
  service worker no Flutter Web.
- Implementar `PushTokenService`: registro do token no login, renovação (`onTokenRefresh`) e remoção
  do token vinculado ao dispositivo no logout.
- Modelar vínculo token↔usuário↔dispositivo (ex.:
  `organizations/{organizationId}/members/{userId}/devices/{deviceId}`) com plataforma, versão do
  app, criadoEm e último uso.
- Tratar opt-in de notificação de forma contextual (nunca solicitar permissão no primeiro splash);
  respeitar a recusa do usuário sem repetir o prompt indevidamente.
- Tratar mensagens em foreground, background e app terminado, preparando o roteamento para deep link
  (consumido por TASK-151).
- Nunca incluir dado pessoal sensível no payload da notificação push — apenas identificadores/
  referências; o conteúdo completo é buscado após a abertura do app.

## Regras de negócio e restrições

- O token pertence sempre a um par dispositivo+usuário; logout nesse dispositivo remove/invalida o
  vínculo, evitando que outro usuário do mesmo aparelho receba notificações da conta anterior.
- Um mesmo usuário pode ter vínculos em múltiplas organizações; o roteamento da notificação deve
  identificar a organização de origem.
- Falha ao registrar o token não pode bloquear o fluxo de login (registro é best-effort com retry em
  segundo plano).

## Testes obrigatórios

- Teste de ciclo de vida do token: registro no login, renovação e remoção no logout.
- Teste garantindo que o payload da notificação nunca contém dado pessoal sensível (validação de
  contrato de payload).
- Teste do comportamento quando o usuário nega a permissão (app não trava, não repete o prompt
  imediatamente).
- Teste de troca de usuário no mesmo dispositivo (token antigo não deve mais notificar a conta
  anterior).
- Teste (mock) de recebimento em foreground/background disparando o roteamento correto.

## Critérios de aceite

- Token é registrado, renovado e removido corretamente em todo o ciclo de vida da sessão.
- Nenhuma notificação expõe dado pessoal sensível no payload.
- Comportamento de opt-in respeita a escolha do usuário em cada plataforma.
- Troca de conta no mesmo dispositivo não vaza notificação para o usuário errado.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura
  de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
