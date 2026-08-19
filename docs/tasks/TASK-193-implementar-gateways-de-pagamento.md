# TASK-193 — Implementar integração com gateways de pagamento

**Epic:** EPIC-29 — Pagamentos e Regras Comerciais Avançadas
**Status:** ⬜ Pendente
**Depende de:** TASK-088 (motor de precificação server-side, fonte do valor final a ser cobrado)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Integrar o VestiPro a gateways de pagamento para cobrança de pedidos, com toda lógica sensível executada em Cloud Functions, suporte a múltiplos gateways por organização/país, idempotência de cobrança e conciliação com o status do pedido — com o mesmo rigor de segurança e auditabilidade do motor de precificação.

## Escopo técnico

- Cloud Functions `createPaymentCharge`, `getPaymentStatus` e webhook `handlePaymentWebhook` por gateway configurado — nenhuma chave/segredo de gateway no cliente Flutter em nenhuma hipótese.
- Modelar `PaymentProvider` por organização (gateway ativo, credenciais em secret manager, moedas suportadas) e `PaymentTransaction` (orderId, gatewayId, status, valor, chave de idempotência, tentativas, histórico de eventos do webhook).
- Chave de idempotência obrigatória em toda criação de cobrança (baseada em orderId + tentativa), garantindo que reenvio de requisição (retry de rede) nunca gere cobrança duplicada.
- Reconciliação automática: webhook do gateway atualiza `PaymentTransaction` e, via trigger, atualiza o status financeiro do pedido (TASK-101), nunca a UI decidindo sozinha que o pagamento foi confirmado.
- Suporte a múltiplos gateways por organização/país (ex.: gateway nacional vs. internacional), com seleção do gateway ativo por regra de configuração da organização, nunca hardcoded.
- Tela de status de pagamento no pedido: pendente, aprovado, recusado, estornado, com motivo quando disponível.

## Regras de negócio e restrições

- Toda confirmação de pagamento é validada pelo webhook do gateway (fonte de verdade), nunca apenas pela resposta imediata da chamada de criação.
- Toda transação de pagamento gera registro auditável (quem iniciou, quando, valor, resultado, tentativas) — mesmo padrão de rigor do motor de precificação.
- Nenhuma credencial de gateway é lida/gravada pelo cliente; toda comunicação com o gateway passa por Cloud Function.
- Retry de cobrança nunca pode gerar duplo débito — chave de idempotência é obrigatória e testada.
- Falha ou instabilidade do gateway deve deixar o pedido em estado claro e recuperável, nunca "perdido" entre pedido e pagamento.

## Testes obrigatórios

- Testes da Cloud Function de criação de cobrança: sucesso, gateway indisponível, chave de idempotência repetida (não duplicar cobrança), valor divergente do pedido.
- Testes do webhook: eventos fora de ordem, evento duplicado, assinatura inválida do webhook (rejeitar), atualização correta do status do pedido.
- Testes de segurança: nenhuma credencial de gateway acessível via Firestore Rules ao cliente.
- Testes de auditoria: toda transação gera registro completo e rastreável.

## Critérios de aceite

- Cobrança é criada de forma idempotente; retries não duplicam débito.
- Status do pedido reflete corretamente o resultado do pagamento validado pelo gateway (não apenas pela chamada inicial).
- Nenhuma credencial de gateway é acessível no cliente.
- Toda transação de pagamento é auditável, com histórico completo de eventos.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
