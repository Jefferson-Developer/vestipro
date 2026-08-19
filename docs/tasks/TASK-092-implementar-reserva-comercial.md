# TASK-092 — Implementar reserva comercial

**Epic:** EPIC-12 — Estoque e Disponibilidade
**Status:** ⬜ Pendente
**Depende de:** TASK-090 — Implementar saldo por variante (reserva decrementa/devolve o mesmo saldo vendável)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Implementar uma estrutura de reserva temporária de estoque para um pedido em elaboração, evitando que dois vendedores vendam o mesmo saldo escasso simultaneamente durante a montagem do pedido. A funcionalidade fica atrás de feature flag (Remote Config) e as regras de expiração de reserva são sempre definidas e executadas server-side.

## Escopo técnico

- Criar entidade `StockReservation` (`id`, `organizationId`, `variantId`, `warehouseId`, `orderDraftId`, `quantity`, `reservedBy`, `reservedAt`, `expiresAt`, `status`: `active`/`expired`/`released`/`consumed`).
- Implementar criação de reserva via Cloud Function transacional que decrementa o saldo vendável e cria o documento de reserva atomicamente.
- Implementar liberação de reserva (por expiração, cancelamento do rascunho, ou submissão efetiva do pedido) revertendo o decremento de saldo.
- Criar job/Cloud Function agendada (Scheduler) para expirar reservas vencidas e devolver o saldo automaticamente.
- Encapsular toda a funcionalidade atrás de flag no `FeatureFlagService` (Remote Config), com valor padrão seguro (desligado) até estabilização.
- Definir tempo de expiração configurável por organização (ex.: 15–60 minutos), nunca hardcoded no client.

## Regras de negócio e restrições

- A regra de expiração e o próprio decremento/reversão de saldo vivem exclusivamente na Cloud Function — o client nunca decide quando uma reserva expira.
- Reserva nunca pode ultrapassar o saldo vendável disponível no momento da criação (validação atômica).
- Ao submeter o pedido definitivamente (TASK-101), a reserva correspondente deve ser consumida sem duplicar o decremento de saldo.
- Falha de rede durante criação/liberação de reserva nunca deve deixar saldo "preso" permanentemente — sempre há expiração de segurança.

## Testes obrigatórios

- Teste de Cloud Function (Emulator) cobrindo criação, expiração automática e liberação manual de reserva.
- Teste de concorrência: duas reservas simultâneas para o mesmo saldo limitado não permitem overselling.
- Teste com a feature flag desligada, validando que o comportamento é idêntico ao fluxo sem reserva.
- Teste de consumo de reserva na submissão do pedido, garantindo ausência de decremento duplicado.

## Critérios de aceite

- Reserva funcional apenas quando a flag estiver ativa para a organização.
- Expiração de reserva sempre decidida e executada server-side.
- Nenhuma condição de corrida permite reservar mais do que o saldo vendável real.
- Reserva corretamente consumida ou liberada conforme o desfecho do pedido em elaboração.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
