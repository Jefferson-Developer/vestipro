# TASK-170 — Implementar webhooks de saída

**Epic:** EPIC-22 — Importação e Integrações de Dados
**Status:** ⬜ Pendente
**Depende de:** TASK-015 (Configurar Cloud Functions for Firebase — webhooks são disparados por triggers/Cloud Functions).

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Permitir que cada organização configure URLs (webhooks) para receber eventos de pedido, cliente e estoque em tempo real, com autenticação por assinatura HMAC e reentrega automática em caso de falha do consumidor.

## Escopo técnico

- Tela/API de configuração de webhooks por organização: URL de destino, eventos assinados (ex.: `order.created`, `order.status_changed`, `customer.created`, `inventory.updated`), status ativo/inativo, segredo compartilhado gerado pelo sistema.
- Cloud Function/trigger que, ao detectar o evento correspondente (trigger de Firestore ou evento de domínio), monta o payload e o envia via HTTP POST ao(s) endpoint(s) configurados da organização.
- Assinatura HMAC-SHA256 do payload usando o segredo da organização, enviada em header (ex.: `X-VestiPro-Signature`), permitindo ao consumidor validar origem e integridade da mensagem.
- Fila de entrega com retry e backoff exponencial (ex.: 1min, 5min, 30min, 2h) até um limite configurável, após o qual o webhook é marcado como falho e o gestor é notificado.
- Log de entregas por webhook (payload enviado, status HTTP retornado, tentativas, sucesso/falha) consultável pelo gestor.
- Rotina de "enviar evento de teste" para o gestor validar a configuração antes de depender dela em produção.

## Regras de negócio e restrições

- Payload de webhook nunca inclui dados de outra organização nem dados sensíveis além do necessário ao evento.
- Segredo HMAC nunca é reexibido em texto claro após a criação inicial (apenas regeneração, nunca "mostrar novamente").
- Todo evento carrega um `eventId` único e idempotente para o consumidor poder deduplicar em caso de reentrega.
- Falha permanente de entrega não pode travar nem atrasar o fluxo interno do VestiPro — disparo de webhook é sempre assíncrono e best-effort do ponto de vista do fluxo principal.

## Testes obrigatórios

- Teste de geração e validação de assinatura HMAC (payload íntegro vs. adulterado).
- Teste de retry com backoff simulando falhas consecutivas do endpoint consumidor e sucesso eventual.
- Teste de limite de tentativas e transição para status "falho" com notificação ao gestor.
- Teste de isolamento multi-tenant: eventos de uma organização nunca chegam ao webhook de outra.
- Teste do endpoint/rotina de "evento de teste".

## Critérios de aceite

- Gestor configura um webhook, recebe evento de teste corretamente assinado e valida a assinatura no destino.
- Falha temporária do consumidor não perde o evento (retry) e falha permanente é sinalizada claramente.
- Nenhum vazamento de dado entre organizações nos payloads.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
