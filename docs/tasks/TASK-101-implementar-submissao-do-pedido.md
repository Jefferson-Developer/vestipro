# TASK-101 — Implementar submissão do pedido

**Epic:** EPIC-13 — Pedidos
**Status:** ⬜ Pendente
**Depende de:** TASK-100 — Implementar validações antes do envio (submissão reexecuta essas mesmas validações server-side)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Implementar a Cloud Function idempotente responsável por enviar o pedido, gerando o número único de pedido server-side, mantendo a trilha de mudança de status e tratando corretamente o reenvio acidental (double submit) sem duplicar o pedido.

## Escopo técnico

- Criar Cloud Function `submitOrder` idempotente: recebe um `clientRequestId`/`idempotencyKey` gerado no client ao iniciar o envio; se a mesma chave já foi processada, retorna o resultado anterior em vez de criar um novo pedido.
- Gerar o número único de pedido server-side (sequencial ou baseado em contador transacional por organização/empresa) — nunca gerado ou confiado pelo client.
- Revalidar server-side as mesmas condições de TASK-100 (cliente ativo, preço vigente, disponibilidade, condição de pagamento, permissões) antes de persistir a transição `draft/pending_sync → submitted`.
- Registrar uma entrada em `OrderStatusHistoryEntry` a cada transição de status, incluindo a submissão.
- Consumir a reserva de estoque (TASK-092) quando a flag estiver ativa, ou aplicar o decremento direto de saldo vendável quando não estiver.
- Tratar reenvio acidental (duplo toque, retry de rede) via a mesma idempotency key — nunca criar dois pedidos para uma única intenção de envio do vendedor.

## Regras de negócio e restrições

- Número de pedido e todas as validações críticas são responsabilidade exclusiva da Cloud Function — o client nunca gera o número final nem decide sozinho que o pedido é válido.
- Falha durante a submissão nunca deve deixar o pedido em estado ambíguo — o status final deve ser sempre determinístico (sucesso completo ou falha com o rascunho preservado para nova tentativa).
- Pedido enviado offline permanece em `pending_sync` até a Function confirmar `submitted`, e a UI deve deixar isso explícito ao vendedor.

## Testes obrigatórios

- Teste de Cloud Function (Emulator) cobrindo submissão bem-sucedida, reenvio com a mesma idempotency key (não deve duplicar) e falha de validação server-side.
- Teste de concorrência: duas submissões simultâneas com a mesma chave de idempotência resultam em um único pedido.
- Teste cobrindo a geração de número de pedido único mesmo sob submissões concorrentes.
- Teste garantindo que a trilha de status (`OrderStatusHistoryEntry`) é criada corretamente na submissão.

## Critérios de aceite

- Pedido enviado gera exatamente um registro, mesmo sob reenvio acidental ou falha de rede intermitente.
- Número de pedido único gerado exclusivamente pela Cloud Function.
- Todas as validações críticas de TASK-100 são reexecutadas e aplicadas no servidor.
- Transições de status registradas corretamente na trilha de histórico.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
