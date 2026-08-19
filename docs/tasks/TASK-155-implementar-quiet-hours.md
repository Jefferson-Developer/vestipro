# TASK-155 — Implementar quiet hours

**Epic:** EPIC-19 — Notificações e Engajamento
**Status:** ⬜ Pendente
**Depende de:** TASK-151 (central de notificações internas, cujos envios devem respeitar o horário
de silêncio)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Evitar o envio de notificações em horários inadequados, respeitando o timezone real do usuário — não
o do servidor — para preservar a experiência do vendedor fora do horário comercial.

## Escopo técnico

- Estender `CommunicationPreferences` (TASK-154) com `QuietHours` (horário de início/fim, dias da
  semana, timezone do usuário).
- Capturar e persistir o timezone real do dispositivo do usuário, nunca assumir o timezone do
  servidor/Cloud Function como referência.
- A Cloud Function/serviço de envio calcula o horário local do destinatário (a partir do timezone
  salvo) antes de decidir enviar o push imediatamente ou enfileirar para o próximo horário
  permitido.
- UI de configuração de quiet hours reaproveitando componentes de formulário/seletor de horário do
  Design System.

## Regras de negócio e restrições

- Notificações críticas de segurança/sessão não são bloqueadas por quiet hours (mesma exceção
  definida em TASK-154).
- Notificação enfileirada por estar fora do horário permitido é entregue assim que o quiet hours
  termina — nunca descartada.
- Timezone é atualizado quando o dispositivo do usuário muda de fuso (ex.: viagem), detectando a
  mudança e atualizando o cadastro correspondente.

## Testes obrigatórios

- Teste de cálculo de horário local considerando o timezone salvo do usuário, distinto do timezone
  do servidor.
- Teste garantindo que notificação fora do quiet hours é enfileirada e entregue no próximo horário
  permitido, sem se perder.
- Teste da exceção para notificações críticas durante o quiet hours.
- Teste de atualização de timezone quando o dispositivo do usuário muda de fuso.
- Teste de widget de configuração de horário (validação de intervalo, formato local).

## Critérios de aceite

- Nenhuma notificação não crítica chega durante o horário de silêncio configurado pelo usuário.
- Notificação adiada é entregue corretamente após o fim do quiet hours, sem se perder.
- Timezone considerado é sempre o do usuário, nunca o do servidor.
- Notificações críticas de segurança continuam sendo entregues mesmo durante o quiet hours.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura
  de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
